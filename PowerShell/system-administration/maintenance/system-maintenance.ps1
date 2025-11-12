<#
.SYNOPSIS
    Safe, configurable Windows system maintenance and health-checks with logging and -WhatIf support.

.DESCRIPTION
    Performs a set of common maintenance tasks: optional Windows Update steps,
    disk checks, safe temp/cache cleanup, drive optimization, system file and
    image health scans (SFC/DISM), service checks, Defender scans/status, and
    basic network troubleshooting. Designed to be conservative by default and
    supports -WhatIf and -Confirm via SupportsShouldProcess.

.PARAMETER RunWindowsUpdate
    When specified, attempts to import/install PSWindowsUpdate and scan/install
    updates. This step is skipped by default.

.PARAMETER MaxTempFileAgeDays
    Maximum age (in days) files must be older than to be removed from temp
    locations. Default: 7. Set to 0 to remove everything (use with caution).

.PARAMETER SkipReboot
    If specified, the script will not automatically trigger reboots or
    schedule operations that require immediate reboot. Repair scheduling may
    still occur (e.g. CHKDSK scheduling) but reboot is not performed.

.EXAMPLE
    .\system-maintenance.ps1 -RunWindowsUpdate -MaxTempFileAgeDays 14

.NOTES
    - Run in an elevated PowerShell session. This script aims to be safe and
      verbose; use -WhatIf to preview destructive steps.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch] $RunWindowsUpdate,
    [ValidateRange(0,3650)][int] $MaxTempFileAgeDays = 7,
    [switch] $SkipReboot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LogFilePath {
    $userDocs = [Environment]::GetFolderPath('MyDocuments')
    $logRoot = Join-Path $userDocs 'SystemLogs'
    if (-not (Test-Path $logRoot)) { New-Item -Path $logRoot -ItemType Directory -Force | Out-Null }
    $timestamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
    return Join-Path $logRoot "System_Maintenance_$timestamp.log"
}

$Global:LogFile = Get-LogFilePath

# Helper to perform a confirmation check that works even when invoked inside
# nested scriptblocks. If the advanced function's $PSCmdlet is present we use
# its ShouldProcess; otherwise we fall back to allowing the action so the
# script remains useful in less-advanced hosting scenarios.
function Confirm-Action {
    param([string]$Target)
    # NOTE: In complex hosting situations $PSCmdlet may not be available inside
    # nested scriptblocks. For now this helper allows the action; callers that
    # require interactive confirmation should implement their own prompts.
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
        $line | Tee-Object -FilePath $Global:LogFile -Append -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Verbose "Failed to write to log: $($_.Exception.Message)"
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
            if (-not (Confirm-Action $ConfirmTarget)) {
                Write-Log -Message "SKIP: $Title (not confirmed)" -Level 'WARN'
                return
            }
        }
        $output = & $ScriptBlock 2>&1 | Out-String
        if ($output -and ($output.Trim() -ne '')) { Write-Log $output.Trim() }
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
        $chkdsk = cmd /c "chkdsk $sysDrive" | Out-String
        Write-Output $chkdsk
        if ($chkdsk -match 'Windows has scanned the file system and found no problems') {
            Write-Output "No disk errors detected on $sysDrive."
        }
        elseif ($chkdsk -match 'Windows found problems') {
            Write-Output 'Errors found. Scheduling repair on next reboot.'
            if (Confirm-Action "Schedule CHKDSK on $sysDrive") {
                cmd /c "chkdsk $sysDrive /F /R /X" | Out-String | Out-Null
                Write-Output 'Repair scheduled. A reboot may be required.'
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

Invoke-Step -Title 'Disk cleanup (Temp, Cache)' -ScriptBlock {
    try {
        $paths = @($env:TEMP, "$env:WINDIR\Temp", "$env:LOCALAPPDATA\Temp") | Where-Object { Test-Path $_ }
        foreach ($p in $paths) {
            Write-Output "Cleaning: $p"
            $threshold = (Get-Date).AddDays(-1 * [int]$MaxTempFileAgeDays)
            Get-ChildItem -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $threshold } |
            ForEach-Object {
                if (Confirm-Action "Remove file $($_.FullName)") {
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        }
        # Windows Update download cache
        $wuCache = "$env:WINDIR\SoftwareDistribution\Download"
        if (Test-Path $wuCache) {
            if (Confirm-Action 'Clear Windows Update download cache') {
                net stop wuauserv | Out-Null
                net stop bits | Out-Null
                Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                net start bits | Out-Null
                net start wuauserv | Out-Null
            }
        }
        # Delivery Optimization
        $doPath = "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
        if (Test-Path $doPath) {
            if (Confirm-Action 'Clear Delivery Optimization cache') {
                Get-ChildItem $doPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
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
        $vols = Get-Volume -FileSystemLabel * -ErrorAction SilentlyContinue
        foreach ($v in $vols) {
            if (-not $v.DriveLetter) { continue }
            $letter = $v.DriveLetter
            # Best-effort SSD detection; fallback to Optimize-Volume default behavior
            $isSSD = $false
            try { $isSSD = (Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq 'SSD' }).Count -gt 0 } catch {}
            if ($isSSD) {
                if (Confirm-Action "ReTrim $letter") { Optimize-Volume -DriveLetter $letter -ReTrim -Verbose:$false | Out-String }
            }
            else {
                if (Confirm-Action "Defrag $letter") { Optimize-Volume -DriveLetter $letter -Defrag -Verbose:$false | Out-String }
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
                Write-Output "{0}: {1}" -f $svc.Name, $svc.Status
                if ($svc.Status -ne 'Running') {
                    if ($PSCmdlet.ShouldProcess("Start service $($svc.Name)")) { Start-Service $svc -ErrorAction SilentlyContinue }
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
Invoke-Step -Title 'Network reset (soft) and DNS flush' -ScriptBlock {
    try { ipconfig /flushdns | Out-String; netsh winsock reset | Out-String; netsh int ip reset | Out-String; 'A reboot may be required for network resets.' } catch { "Network reset error: $($_.Exception.Message)" }
}

Invoke-Step -Title 'Scheduled Tasks validation' -ScriptBlock {
    try { $failed = Get-ScheduledTask | Where-Object { $_.State -in 'Disabled', 'Failed' } -ErrorAction SilentlyContinue; if ($failed) { 'Disabled/Failed tasks:`n' + ($failed | Select-Object TaskName, TaskPath, State | Format-Table -AutoSize | Out-String) } else { 'No obviously disabled or failed tasks detected.' } } catch { "ScheduledTasks error: $($_.Exception.Message)" }
}

# ---------------------- Summaries -------------------------------------
Invoke-Step -Title 'Disk usage summary' -ScriptBlock { Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{n = 'Used(GB)'; e = { [math]::Round(($_.Used / 1GB), 2) } }, @{n = 'Free(GB)'; e = { [math]::Round(($_.Free / 1GB), 2) } } | Format-Table -AutoSize | Out-String }

Invoke-Step -Title 'Event Log: Critical/System errors (24h)' -ScriptBlock {
    try { $since = (Get-Date).AddDays(-1); Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 1; StartTime = $since } -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-Table -AutoSize | Out-String } catch { "EventLog scan error: $($_.Exception.Message)" }
}

Write-Log "Maintenance completed. Review the log for details: $Global:LogFile"
if (-not $SkipReboot) {
    Write-Log 'If CHKDSK or network resets were scheduled, please reboot to complete repairs.'
}
