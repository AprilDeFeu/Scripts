#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Force-uninstalls TeamViewer on Windows with minimal disruption.

.DESCRIPTION
    - Elevates if not admin (via #Requires).
    - Stops services and processes.
    - Attempts MSI, registered uninstall strings, and bundled uninstallers.
    - Cleans residual services, tasks, files, and registry.
    - Safe if TeamViewer is already absent (no errors, no changes beyond cleanup).

.PARAMETER Quiet
    Suppresses non-essential console output.

.PARAMETER NoCleanup
    Skips removal of residual files, registry entries, services, and tasks.

.EXAMPLE
    .\Remove-TeamViewer.ps1 -Quiet
#>

param (
  [Parameter(Mandatory = $false, HelpMessage = "Suppress non-essential output")]
  [switch]$Quiet,

  [Parameter(Mandatory = $false, HelpMessage = "Skip post-uninstall cleanup tasks")]
  [switch]$NoCleanup
)

$ErrorActionPreference = 'SilentlyContinue'
$PSDefaultParameterValues['*:ErrorAction'] = 'SilentlyContinue'

function Write-Info {
  param([string]$Message)
  if (-not $Quiet) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
  }
}

function Write-Success {
  param([string]$Message)
  if (-not $Quiet) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
  }
}

function Write-WarningMessage {
  param([string]$Message)
  Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
  param([string]$Message)
  Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Stop-TeamViewerServicesAndProcesses {
  Write-Info "Stopping TeamViewer services..."
  $serviceNames = @('TeamViewer', 'TeamViewerVPN', 'tvnserver')

  foreach ($serviceName in $serviceNames) {
    sc.exe stop $serviceName | Out-Null
  }

  # Allow services time to stop gracefully before terminating processes
  Start-Sleep -Milliseconds 600

  Write-Info "Killing TeamViewer processes..."
  Get-Process *teamviewer* | Stop-Process -Force
}

function Invoke-UninstallByMsi {
  Write-Info "Trying MSI-based uninstall..."
  $products = Get-CimInstance Win32_Product | Where-Object { $_.Name -like 'TeamViewer*' }

  if ($products) {
    foreach ($product in $products) {
      $productId = $product.IdentifyingNumber
      if ($productId) {
        Write-Info "Uninstalling MSI product $($product.Name) $($product.Version) ($productId)..."
        Start-Process msiexec.exe "/x $productId /qn /norestart" -Wait
      }
    }

    return $true
  }

  return $false
}

function Get-UninstallCommandsFromRegistry {
  $registryPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )

  $commands = @()

  foreach ($path in $registryPaths) {
    foreach ($item in Get-ChildItem $path) {
      $uninstallInfo = Get-ItemProperty $item.PSPath
      if ($uninstallInfo.DisplayName -and ($uninstallInfo.DisplayName -like 'TeamViewer*') -and $uninstallInfo.UninstallString) {
        $commands += [pscustomobject]@{
          DisplayName     = $uninstallInfo.DisplayName
          UninstallString = $uninstallInfo.UninstallString
        }
      }
    }
  }

  $commands
}

function Convert-UninstallCommand([string]$Command) {
  # Normalizes uninstall commands to run silently and flip install switches
  $normalized = $Command.Trim()

  # Ensure the executable path is quoted while keeping arguments intact
  if ($normalized -notmatch '^".*"\s' -and $normalized -match '^[^"]?:?\\') {
    $parts = $normalized -split '\s+', 2
    if ($parts.Count -gt 0) {
      $executablePath = $parts[0]
      $commandArguments = ''

      if ($parts.Count -gt 1) {
        $commandArguments = $parts[1]
      }

      if ($executablePath -notmatch '^".*"$') {
        $executablePath = '"' + $executablePath + '"'
      }

      if ($commandArguments) {
        $normalized = "$executablePath $commandArguments"
      }
      else {
        $normalized = $executablePath
      }
    }
  }

  # Convert install switches to uninstall switches for MSI syntax
  $normalized = $normalized -replace '(/|")I(\b)', '${1}X'

  # Ensure quiet execution flags are present
  if ($normalized -notmatch '(?i)(/quiet|/qn|/s|/silent)\b') {
    $normalized += ' /quiet /qn /S /silent'
  }

  $normalized
}

function Invoke-UninstallFromRegistry {
  Write-Info "Trying registry uninstall strings..."
  $commands = Get-UninstallCommandsFromRegistry
  $executed = $false

  foreach ($command in $commands) {
    $normalizedCommand = Convert-UninstallCommand $command.UninstallString
    Write-Info "Running: $normalizedCommand"
    Start-Process cmd.exe "/c $normalizedCommand" -WindowStyle Hidden -Wait
    $executed = $true
  }

  return $executed
}

function Invoke-BundledUninstallers {
  Write-Info "Trying bundled uninstallers..."
  $uninstallerPaths = @(
    'C:\Program Files\TeamViewer\uninstall.exe',
    'C:\Program Files (x86)\TeamViewer\uninstall.exe',
    'C:\Program Files\TeamViewer\unins000.exe',
    'C:\Program Files (x86)\TeamViewer\unins000.exe'
  )

  $executed = $false

  foreach ($path in $uninstallerPaths) {
    if (Test-Path $path) {
      Write-Info "Launching uninstaller: $path"
      Start-Process $path '/S /silent /verysilent /norestart' -WindowStyle Hidden -Wait
      $executed = $true
    }
  }

  return $executed
}

function Remove-Residuals {
  Write-Info "Cleaning residual services..."
  foreach ($serviceName in @('TeamViewer', 'TeamViewerVPN', 'tvnserver')) {
    sc.exe stop $serviceName | Out-Null
    sc.exe delete $serviceName | Out-Null
  }

  Write-Info "Removing scheduled tasks..."
  $tasks = schtasks.exe /Query /FO LIST /V | Select-String -Pattern '(?im)^TaskName:\s+(.+)$' | ForEach-Object {
    $_.Matches[0].Groups[1].Value.Trim()
  }

  foreach ($task in $tasks) {
    if ($task -match '(?i)teamviewer') {
      schtasks.exe /Delete /TN "$task" /F | Out-Null
    }
  }

  Write-Info "Deleting leftover folders..."
  $folders = @(
    'C:\Program Files\TeamViewer',
    'C:\Program Files (x86)\TeamViewer',
    "$env:ProgramData\TeamViewer",
    "$env:AppData\TeamViewer",
    "$env:LocalAppData\TeamViewer"
  )

  foreach ($folder in $folders) {
    if (Test-Path $folder) {
      Remove-Item $folder -Recurse -Force
    }
  }

  Write-Info "Removing registry keys..."
  foreach ($registryKey in @(
      'HKLM:\SOFTWARE\TeamViewer',
      'HKLM:\SOFTWARE\WOW6432Node\TeamViewer',
      'HKCU:\SOFTWARE\TeamViewer'
    )) {
    if (Test-Path $registryKey) {
      Remove-Item $registryKey -Recurse -Force
    }
  }

  Write-Success "Cleanup complete."
}

function Test-TeamViewerPresence {
  $installDirectories = @('C:\Program Files\TeamViewer', 'C:\Program Files (x86)\TeamViewer')
  $hasDirectories = $installDirectories | Where-Object { Test-Path $_ }
  $runningProcesses = Get-Process *teamviewer*
  $registryEntries = Get-UninstallCommandsFromRegistry

  return ($hasDirectories -or $runningProcesses -or $registryEntries)
}

# Main
try {
  Write-Info "Starting TeamViewer removal..."

  Stop-TeamViewerServicesAndProcesses

  $didSomething = $false
  $didSomething = Invoke-UninstallByMsi        -or $didSomething
  $didSomething = Invoke-UninstallFromRegistry -or $didSomething
  $didSomething = Invoke-BundledUninstallers   -or $didSomething

  if (-not $didSomething) {
    if (-not (Test-TeamViewerPresence)) {
      Write-Success "TeamViewer not detected. Nothing to uninstall."
    }
    else {
      Write-WarningMessage "Could not run any uninstaller; proceeding to cleanup only."
    }
  }

  if (-not $NoCleanup) {
    Remove-Residuals
  }
  else {
    Write-WarningMessage "Skipping cleanup per -NoCleanup."
  }

  Write-Success "Done. A reboot is recommended, especially if VPN drivers were installed."
}
catch {
  Write-ErrorMessage "Script failed with error: $($_.Exception.Message)"
  Write-ErrorMessage "Line: $($_.InvocationInfo.ScriptLineNumber)"
  exit 1
}
finally {
  Write-Info "Script execution finished."
}
