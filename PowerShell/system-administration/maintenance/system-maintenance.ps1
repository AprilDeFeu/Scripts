#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Safe, configurable Windows system maintenance and health-checks with logging and -WhatIf support.

.DESCRIPTION
    Performs a set of common maintenance tasks: optional Windows Update steps,
    disk checks, safe temp/cache cleanup, drive optimization, system file and
    image health scans (SFC/DISM), service checks, Defender scans/status, and
    basic network troubleshooting. Designed to be conservative by default and
    supports -WhatIf and -Confirm via SupportsShouldProcess.

    Note: When RunWindowsUpdate is specified, PSGallery will be set as a trusted
    repository to install the PSWindowsUpdate module.

.PARAMETER RunWindowsUpdate
    When specified, attempts to import/install PSWindowsUpdate and scan/install
    updates. This step is skipped by default. WARNING: This will set PSGallery
    as a trusted repository.

.PARAMETER MaxTempFileAgeDays
    Maximum age (in days) files must be older than to be removed from temp
    locations. Default: 7. Set to 0 to remove everything (use with caution).

.EXAMPLE
    .\system-maintenance.ps1 -RunWindowsUpdate -MaxTempFileAgeDays 14

.EXAMPLE
    .\system-maintenance.ps1 -WhatIf
    Preview all destructive operations without executing them.

.NOTES
    - Requires Administrator privileges (enforced via #Requires statement).
    - Use -WhatIf to preview destructive steps before execution.
    - Network reset operations are potentially disruptive and require confirmation.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch] $RunWindowsUpdate,
    [ValidateRange(0,3650)][int] $MaxTempFileAgeDays = 7
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LogFilePath {
    $userDocs = [Environment]::GetFolderPath('MyDocuments')
    # Fallback to temp directory if MyDocuments is not available
    if ([string]::IsNullOrWhiteSpace($userDocs)) {
        $userDocs = [System.IO.Path]::GetTempPath()
    }
    $logRoot = Join-Path $userDocs 'SystemLogs'
    if (-not (Test-Path $logRoot)) { New-Item -Path $logRoot -ItemType Directory -Force | Out-Null }
    $timestamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
    return Join-Path $logRoot "System_Maintenance_$timestamp.log"
}

$script:LogFile = Get-LogFilePath

# Store the script-level PSCmdlet for use in nested scriptblocks
$script:ScriptPSCmdlet = $PSCmdlet

# Helper to perform a confirmation check that works even when invoked inside
# nested scriptblocks. Uses the script-scoped PSCmdlet reference.
function Confirm-Action {
    param(
        [string]$Target,
        [string]$Action = 'Perform operation'
    )
    # Use the script-scoped PSCmdlet reference
    if ($null -ne $script:ScriptPSCmdlet) {
        return $script:ScriptPSCmdlet.ShouldProcess($Target, $Action)
    }
    # Fallback: allow the action if PSCmdlet is not available
    return $true
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')][string] $Level = 'INFO'
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    try {
        $line | Tee-Object -FilePath $script:LogFile -Append -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
        Write-Host $line
    }
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][scriptblock] $ScriptBlock,
        [Parameter(Mandatory = $true)][string] $Title,
        [string] $ConfirmTarget,
        [switch] $Destructive
    )
    Write-Log "BEGIN: $Title"
    try {
        if ($Destructive.IsPresent -and $ConfirmTarget) {
            if (-not (Confirm-Action -Target $ConfirmTarget -Action $Title)) {
                Write-Log -Message "SKIP: $Title (not confirmed)" -Level 'WARN'
                return
            }
        }
        # Capture output and errors separately
        $output = @()
        $errors = @()
        & $ScriptBlock 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $errors += $_
            } else {
                $output += $_
            }
        }

        # Log standard output
        if ($output.Count -gt 0) {
            $outputString = ($output | Out-String).Trim()
            if ($outputString -ne '') { Write-Log $outputString }
        }

        # Log errors separately
        if ($errors.Count -gt 0) {
            foreach ($err in $errors) {
                Write-Log -Message "ERROR: $($err.Exception.Message)" -Level 'ERROR'
            }
        }

        Write-Log "END: $Title"
    }
    catch {
        Write-Log -Message "ERROR in ${Title}: $($_.Exception.Message)" -Level 'ERROR'
    }
}

Write-Log "Starting system maintenance and health checks. Params: RunWindowsUpdate=$RunWindowsUpdate, MaxTempFileAgeDays=$MaxTempFileAgeDays"

# ---------------------- Windows Update (optional) ----------------------
if ($RunWindowsUpdate) {
    Invoke-Step -Title 'Windows Update scan/install (if available)' -ScriptBlock {
        try {
            if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
                Write-Output 'PSWindowsUpdate module not found. Installing...'
                Write-Output 'WARNING: Setting PSGallery as a trusted repository to install PSWindowsUpdate module.'
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope AllUsers -ErrorAction SilentlyContinue
            }
            Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
            if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) {
                # Get-WindowsUpdate returns available updates; Install-WindowsUpdate performs install
                $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue
                if ($updates) {
                    Write-Output "Updates found: $($updates.Count)"
                    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -AutoReboot:$false -ErrorAction SilentlyContinue | Out-String
                }
                else {
                    Write-Output 'No updates available.'
                }
            }
            else {
                Write-Output 'PSWindowsUpdate not available. Skipping Windows Update step.'
            }
        }
        catch {
            Write-Output "Windows Update step failed: $($_.Exception.Message)"
        }
    }
}

# ---------------------- Disk Health & Cleanup ---------------------------

Invoke-Step -Title 'CHKDSK read-only scan and schedule repair if needed' -ScriptBlock {
    try {
        $sysDrive = "$($env:SystemDrive)"
        Write-Output "Running read-only CHKDSK scan on $sysDrive..."
        $chkdsk = cmd /c "chkdsk $sysDrive" 2>&1 | Out-String
        Write-Output $chkdsk
        if ($chkdsk -match 'Windows has scanned the file system and found no problems') {
            Write-Output "No disk errors detected on $sysDrive."
        }
        elseif ($chkdsk -match 'Windows found problems') {
            Write-Output 'Errors found. Scheduling repair on next reboot.'
            if (Confirm-Action -Target "Schedule CHKDSK repair on $sysDrive" -Action "Schedule CHKDSK /F /R") {
                $repairOutput = cmd /c "chkdsk $sysDrive /F /R" 2>&1 | Out-String
                Write-Output $repairOutput
                Write-Output 'Repair scheduled. A reboot will be required to complete the repair.'
            }
        }
        else {
            Write-Output 'CHKDSK completed. Review above output for details.'
        }
    }
    catch {
        Write-Output "CHKDSK step error: $($_.Exception.Message)"
    }
}

Invoke-Step -Title 'Disk cleanup (Temp, Cache)' -Destructive -ConfirmTarget 'Clean temporary and cache files' -ScriptBlock {
    try {
        $paths = @($env:TEMP, "$env:WINDIR\Temp", "$env:LOCALAPPDATA\Temp") | Where-Object { Test-Path $_ }
        $threshold = (Get-Date).AddDays(-1 * [int]$MaxTempFileAgeDays)

        foreach ($p in $paths) {
            Write-Output "Cleaning: $p"
            # Confirm at directory level for better performance
            if (Confirm-Action -Target "Delete old files in $p" -Action 'Delete files') {
                Get-ChildItem -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $threshold } |
                ForEach-Object {
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        }

        # Windows Update download cache
        $wuCache = "$env:WINDIR\SoftwareDistribution\Download"
        if (Test-Path $wuCache) {
            if (Confirm-Action -Target 'Windows Update download cache' -Action 'Clear cache') {
                # Stop services using proper PowerShell cmdlets
                $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
                $bitsService = Get-Service -Name bits -ErrorAction SilentlyContinue

                $wuWasRunning = $false
                $bitsWasRunning = $false

                if ($wuService -and $wuService.Status -eq 'Running') {
                    $wuWasRunning = $true
                    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
                    Write-Output 'Stopped Windows Update service'
                }

                if ($bitsService -and $bitsService.Status -eq 'Running') {
                    $bitsWasRunning = $true
                    Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
                    Write-Output 'Stopped BITS service'
                }

                Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output 'Cleared Windows Update download cache'

                # Restart services if they were running
                if ($bitsWasRunning) {
                    Start-Service -Name bits -ErrorAction SilentlyContinue
                    Write-Output 'Restarted BITS service'
                }

                if ($wuWasRunning) {
                    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
                    Write-Output 'Restarted Windows Update service'
                }
            }
        }

        # Delivery Optimization
        $doPath = "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
        if (Test-Path $doPath) {
            if (Confirm-Action -Target 'Delivery Optimization cache' -Action 'Clear cache') {
                Get-ChildItem $doPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output 'Cleared Delivery Optimization cache'
            }
        }
        Write-Output 'Disk cleanup completed.'
    }
    catch {
        Write-Output "Disk cleanup error: $($_.Exception.Message)"
    }
}

Invoke-Step -Title 'Drive optimization (trim/defrag)' -ScriptBlock {
    try {
        # Cache physical disk information to improve performance
        $physicalDisks = @{}
        try {
            Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
                $physicalDisks[$_.Number] = $_
            }
        } catch {
            Write-Output 'Unable to query physical disks. Will use default optimization method.'
        }

        $vols = Get-Volume -FileSystemLabel * -ErrorAction SilentlyContinue
        foreach ($v in $vols) {
            if (-not $v.DriveLetter) { continue }
            $letter = $v.DriveLetter

            # Determine if this volume is on an SSD
            $isSSD = $false
            try {
                # Get the partition for this volume
                $partition = Get-Partition -DriveLetter $letter -ErrorAction SilentlyContinue
                if ($partition) {
                    # Get the disk for this partition
                    $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
                    if ($disk -and $physicalDisks.ContainsKey($disk.Number)) {
                        $physDisk = $physicalDisks[$disk.Number]
                        $isSSD = ($physDisk.MediaType -eq 'SSD')
                    }
                }
            } catch {
                Write-Output "Could not determine disk type for ${letter}:, using default optimization"
            }

            if ($isSSD) {
                if (Confirm-Action -Target "${letter}: (SSD)" -Action 'ReTrim volume') {
                    Optimize-Volume -DriveLetter $letter -ReTrim -Verbose:$false | Out-Null
                    Write-Output "Trimmed ${letter}: (SSD)"
                }
            }
            else {
                if (Confirm-Action -Target "${letter}: (HDD)" -Action 'Defragment volume') {
                    Optimize-Volume -DriveLetter $letter -Defrag -Verbose:$false | Out-Null
                    Write-Output "Defragmented ${letter}: (HDD)"
                }
            }
        }
        Write-Output 'Drive optimization completed.'
    }
    catch {
        Write-Output "Drive optimization error: $($_.Exception.Message)"
    }
}

# ---------------------- System File & Image Health ---------------------
Invoke-Step -Title 'SFC /SCANNOW (repair system files)' -ScriptBlock {
    try { sfc /scannow | Out-String } catch { "SFC error: $($_.Exception.Message)" }
}

Invoke-Step -Title 'DISM RestoreHealth (servicing image)' -ScriptBlock {
    try {
        DISM /Online /Cleanup-Image /ScanHealth | Out-String
        DISM /Online /Cleanup-Image /CheckHealth | Out-String
        DISM /Online /Cleanup-Image /RestoreHealth | Out-String
    }
    catch { "DISM error: $($_.Exception.Message)" }
}

# ---------------------- Services & Drivers ----------------------------
Invoke-Step -Title 'Service health checks (BITS, wuauserv, CryptSvc)' -ScriptBlock {
    try {
        $services = 'BITS', 'wuauserv', 'CryptSvc'
        foreach ($s in $services) {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if ($null -ne $svc) {
                Write-Output ("{0}: {1}" -f $svc.Name, $svc.Status)
                if ($svc.Status -ne 'Running') {
                    if (Confirm-Action -Target $svc.Name -Action 'Start service') {
                        Start-Service $svc -ErrorAction SilentlyContinue
                        Write-Output "Started service: $($svc.Name)"
                    }
                }
            }
            else { Write-Output "$s service not found." }
        }
    }
    catch { "Service check error: $($_.Exception.Message)" }
}

Invoke-Step -Title 'Device Manager problem devices' -ScriptBlock {
    try {
        $problems = Get-PnpDevice -Status Error, Problem, Unknown -ErrorAction SilentlyContinue
        if ($problems) { "Devices with issues:`n" + ($problems | Select-Object Class, FriendlyName, InstanceId, Status | Format-Table -AutoSize | Out-String) }
        else { 'No device problems detected.' }
    }
    catch { "PnpDevice error: $($_.Exception.Message)" }
}

# ---------------------- Security & Safety Scans ------------------------
Invoke-Step -Title 'Defender signature/platform update' -ScriptBlock {
    try { Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; Get-MpComputerStatus | Select-Object AMEngineVersion, AntispywareSignatureVersion, AntivirusSignatureVersion | Format-List | Out-String } catch { "Defender update error: $($_.Exception.Message)" }
}

Invoke-Step -Title 'Defender quick scan' -ScriptBlock {
    try { Start-MpScan -ScanType QuickScan; 'Quick scan initiated.' } catch { "Defender quick scan error: $($_.Exception.Message)" }
}

Invoke-Step -Title 'Firewall & protection status' -ScriptBlock {
    try { (Get-NetFirewallProfile | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String) + (Get-MpPreference | Select-Object DisableRealtimeMonitoring, DisableIOAVProtection, DisableBehaviorMonitoring | Format-List | Out-String) } catch { "Firewall check error: $($_.Exception.Message)" }
}

# ---------------------- Network & Scheduled Tasks ---------------------
Invoke-Step -Title 'Network reset (soft) and DNS flush' -Destructive -ConfirmTarget 'Reset network configuration (may disrupt connectivity)' -ScriptBlock {
    try {
        Write-Output 'Flushing DNS cache...'
        ipconfig /flushdns
        Write-Output 'Resetting Winsock catalog...'
        netsh winsock reset
        Write-Output 'Resetting IP configuration...'
        netsh int ip reset
        Write-Output 'Network reset completed. A reboot may be required for changes to take full effect.'
    } catch {
        "Network reset error: $($_.Exception.Message)"
    }
}

Invoke-Step -Title 'Scheduled Tasks validation' -ScriptBlock {
    try { $failed = Get-ScheduledTask | Where-Object { $_.State -in 'Disabled', 'Failed' } -ErrorAction SilentlyContinue; if ($failed) { 'Disabled/Failed tasks:`n' + ($failed | Select-Object TaskName, TaskPath, State | Format-Table -AutoSize | Out-String) } else { 'No obviously disabled or failed tasks detected.' } } catch { "ScheduledTasks error: $($_.Exception.Message)" }
}

# ---------------------- Summaries -------------------------------------
Invoke-Step -Title 'Disk usage summary' -ScriptBlock { Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{n = 'Used(GB)'; e = { [math]::Round(($_.Used / 1GB), 2) } }, @{n = 'Free(GB)'; e = { [math]::Round(($_.Free / 1GB), 2) } } | Format-Table -AutoSize | Out-String }

Invoke-Step -Title 'Event Log: Critical/System errors (24h)' -ScriptBlock {
    try { $since = (Get-Date).AddDays(-1); Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 1; StartTime = $since } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-Table -AutoSize | Out-String } catch { "EventLog scan error: $($_.Exception.Message)" }
}

Write-Log "Maintenance completed. Review the log for details: $script:LogFile"
Write-Log 'If CHKDSK or network resets were scheduled, please reboot to complete repairs.'
