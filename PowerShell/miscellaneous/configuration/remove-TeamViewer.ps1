#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Force-uninstalls TeamViewer on Windows with minimal disruption.
.DESCRIPTION
  - Elevates if not admin (via #Requires).
  - Stops services/processes.
  - Attempts MSI, registered uninstall strings, and bundled uninstallers.
  - Cleans residual services, tasks, files, and registry.
  - Safe if TeamViewer is already absent (no errors, no changes beyond cleanup).
.PARAMETER Quiet
  Switch to reduce console output.
.PARAMETER NoCleanup
  Skip removal of residual files/registry/services/tasks.
.EXAMPLE
  .\Remove-TeamViewer.ps1 -Quiet
#>

param(
  [switch]$Quiet,
  [switch]$NoCleanup
)

$ErrorActionPreference = 'SilentlyContinue'
$PSDefaultParameterValues['*:ErrorAction'] = 'SilentlyContinue'

function Write-Info($msg) { if (-not $Quiet) { Write-Host "[*] $msg" -ForegroundColor Cyan } }
function Write-Ok($msg)   { if (-not $Quiet) { Write-Host "[+] $msg" -ForegroundColor Green } }
function Write-Warn($msg) { if (-not $Quiet) { Write-Host "[!] $msg" -ForegroundColor Yellow } }

function Stop-TeamViewerServicesAndProcesses {
  Write-Info "Stopping TeamViewer services..."
  $svcNames = @('TeamViewer','TeamViewerVPN','tvnserver')
  foreach ($s in $svcNames) {
    sc.exe stop $s | Out-Null
  }

  # Give services a moment to stop
  Start-Sleep -Milliseconds 600

  Write-Info "Killing TeamViewer processes..."
  Get-Process *teamviewer* | Stop-Process -Force
}

function Try-UninstallByMSI {
  Write-Info "Trying MSI-based uninstall..."
  $products = Get-CimInstance Win32_Product | Where-Object { $_.Name -like 'TeamViewer*' }
  if ($products) {
    foreach ($p in $products) {
      $id = $p.IdentifyingNumber
      if ($id) {
        Write-Info "Uninstalling MSI product $($p.Name) $($p.Version) ($id)..."
        Start-Process msiexec.exe "/x $id /qn /norestart" -Wait
      }
    }
    return $true
  }
  return $false
}

function Get-UninstallCommandsFromRegistry {
  $keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )
  $cmds = @()
  foreach ($k in $keys) {
    foreach ($item in Get-ChildItem $k) {
      $u = Get-ItemProperty $item.PSPath
      if ($u.DisplayName -and ($u.DisplayName -like 'TeamViewer*') -and $u.UninstallString) {
        $cmds += [pscustomobject]@{
          DisplayName     = $u.DisplayName
          UninstallString = $u.UninstallString
        }
      }
    }
  }
  $cmds
}

function Normalize-UninstallCommand([string]$cmd) {
  # Ensure silent switches and flip any install to uninstall if needed
  $normalized = $cmd.Trim()

  # If it's quoted path followed by args, keep it; otherwise wrap path with quotes if needed
  if ($normalized -notmatch '^".*"\s' -and $normalized -match '^[^"]?:?\\') {
    $parts = $normalized -split '\s+', 2
    if ($parts.Count -gt 0) {
      $exe = $parts[0]
      $args = ''

      if ($parts.Count -gt 1) {
        $args = $parts[1]
      }

      if ($exe -notmatch '^".*"$') {
        $exe = '"' + $exe + '"'
      }

      if ($args) {
        $normalized = "$exe $args"
      } else {
        $normalized = $exe
      }
    }
  }

  # Convert install to uninstall for MSI syntax
  $normalized = $normalized -replace '(/|")I(\b)', '${1}X'

  # Add quiet flags if missing
  if ($normalized -notmatch '(?i)(/quiet|/qn|/s|/silent)\b') {
    $normalized += ' /quiet /qn /S /silent'
  }

  $normalized
}

function Try-UninstallByRegistry {
  Write-Info "Trying registry uninstall strings..."
  $cmds = Get-UninstallCommandsFromRegistry
  $ran = $false
  foreach ($c in $cmds) {
    $cmd = Normalize-UninstallCommand $c.UninstallString
    Write-Info "Running: $cmd"
    Start-Process cmd.exe "/c $cmd" -WindowStyle Hidden -Wait
    $ran = $true
  }
  return $ran
}

function Try-BundledUninstallers {
  Write-Info "Trying bundled uninstallers..."
  $paths = @(
    'C:\Program Files\TeamViewer\uninstall.exe',
    'C:\Program Files (x86)\TeamViewer\uninstall.exe',
    'C:\Program Files\TeamViewer\unins000.exe',
    'C:\Program Files (x86)\TeamViewer\unins000.exe'
  )
  $ran = $false
  foreach ($p in $paths) {
    if (Test-Path $p) {
      Write-Info "Launching uninstaller: $p"
      Start-Process $p '/S /silent /verysilent /norestart' -WindowStyle Hidden -Wait
      $ran = $true
    }
  }
  return $ran
}

function Remove-Residuals {
  Write-Info "Cleaning residual services..."
  foreach ($s in @('TeamViewer','TeamViewerVPN','tvnserver')) {
    sc.exe stop $s | Out-Null
    sc.exe delete $s | Out-Null
  }

  Write-Info "Removing scheduled tasks..."
  $tasks = schtasks.exe /Query /FO LIST /V | Select-String -Pattern '(?im)^TaskName:\s+(.+)$' | ForEach-Object {
    $_.Matches[0].Groups[1].Value.Trim()
  }
  foreach ($t in $tasks) {
    if ($t -match '(?i)teamviewer') {
      schtasks.exe /Delete /TN "$t" /F | Out-Null
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
  foreach ($f in $folders) {
    if (Test-Path $f) { Remove-Item $f -Recurse -Force }
  }

  Write-Info "Removing registry keys..."
  foreach ($rk in @(
    'HKLM:\SOFTWARE\TeamViewer',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer',
    'HKCU:\SOFTWARE\TeamViewer'
  )) {
    if (Test-Path $rk) { Remove-Item $rk -Recurse -Force }
  }

  Write-Ok "Cleanup complete."
}

function Is-Installed {
  $dirs = @('C:\Program Files\TeamViewer','C:\Program Files (x86)\TeamViewer')
  $hasDirs = $dirs | Where-Object { Test-Path $_ }
  $hasProcs = Get-Process *teamviewer*
  $hasReg = Get-UninstallCommandsFromRegistry
  return ($hasDirs -or $hasProcs -or $hasReg)
}

# Main
Write-Info "Starting TeamViewer removal..."

Stop-TeamViewerServicesAndProcesses

$didSomething = $false
$didSomething = Try-UninstallByMSI       -or $didSomething
$didSomething = Try-UninstallByRegistry  -or $didSomething
$didSomething = Try-BundledUninstallers  -or $didSomething

if (-not $didSomething) {
  if (-not (Is-Installed)) {
    Write-Ok "TeamViewer not detected. Nothing to uninstall."
  } else {
    Write-Warn "Could not run any uninstaller; proceeding to cleanup only."
  }
}

if (-not $NoCleanup) {
  Remove-Residuals
} else {
  Write-Warn "Skipping cleanup per -NoCleanup."
}

Write-Ok "Done. A reboot is recommended, especially if VPN drivers were installed."
