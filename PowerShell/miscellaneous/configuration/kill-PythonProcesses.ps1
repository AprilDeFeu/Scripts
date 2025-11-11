<#
.SYNOPSIS
	Terminates Python-related services, processes, and running scheduled tasks.

.DESCRIPTION
	- Ensures the script runs with administrator privileges (with prompt to elevate if needed).
	- Stops services whose name or display name starts with "python".
	- Terminates processes whose names begin with "python" (e.g., python.exe, pythonw.exe).
	- Stops running scheduled tasks whose name or path contains "python".
	- Verifies that no Python processes remain running.

.PARAMETER Quiet
	Suppresses non-essential informational output.

.EXAMPLE
	.\kill-PythonProcesses.ps1

.EXAMPLE
	.\kill-PythonProcesses.ps1 -Quiet
#>

param (
	[Parameter(Mandatory = $false, HelpMessage = "Suppress non-essential output")]
	[switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

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

function Ensure-Administrator {
	$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

	if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		return
	}

	Write-WarningMessage "Administrator privileges are required to stop services and scheduled tasks."

	if (-not $PSCommandPath) {
		Write-WarningMessage "Cannot self-elevate because the script path is unavailable. Please rerun this script from an elevated PowerShell session."
		exit 1
	}

	$response = Read-Host "Run this script with elevated permissions now? (Y/N)"
	if ($response -match '^(?i)y(es)?$') {
		$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
		if ($Quiet) {
			$arguments += ' -Quiet'
		}

		try {
			Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments | Out-Null
		}
		catch {
			Write-ErrorMessage "Failed to launch elevated PowerShell instance: $($_.Exception.Message)"
		}
	}
	else {
		Write-WarningMessage "User declined elevation. No actions were performed."
	}

	exit 1
}

function Stop-PythonServices {
	Write-Info "Scanning for Python-related services..."

	$services = Get-Service | Where-Object {
		($_.Name -match '^(?i)python') -or ($_.DisplayName -match '^(?i)python')
	}

	$stopped = $false

	foreach ($service in $services) {
		if ($service.Status -eq 'Running') {
			Write-Info "Stopping service: $($service.Name)"
			try {
				Stop-Service -Name $service.Name -Force -ErrorAction Stop
				$stopped = $true
			}
			catch {
				Write-ErrorMessage "Failed to stop service $($service.Name): $($_.Exception.Message)"
			}
		}
	}

	return $stopped
}

function Stop-PythonProcesses {
	Write-Info "Scanning for Python processes..."

	$processes = Get-Process -Name 'python*' -ErrorAction SilentlyContinue | Where-Object {
		$_.Name -match '^(?i)python'
	}

	$terminated = $false

	foreach ($process in $processes) {
		Write-Info "Terminating process: $($process.Name) (PID: $($process.Id))"
		try {
			Stop-Process -Id $process.Id -Force -ErrorAction Stop
			$terminated = $true
		}
		catch {
			Write-ErrorMessage "Failed to terminate process $($process.Name) (PID: $($process.Id)): $($_.Exception.Message)"
		}
	}

	return $terminated
}

function Stop-PythonScheduledTasks {
	if (-not (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)) {
		Write-WarningMessage "Scheduled task cmdlets are unavailable on this system. Skipping task check."
		return $false
	}

	Write-Info "Scanning for running scheduled tasks referencing Python..."

	$tasks = Get-ScheduledTask | Where-Object {
		$_.TaskName -match '(?i)python' -or $_.TaskPath -match '(?i)python'
	}

	$stopped = $false

	foreach ($task in $tasks) {
		$taskInfo = Get-ScheduledTaskInfo -TaskPath $task.TaskPath -TaskName $task.TaskName
		if ($taskInfo.State -eq 'Running') {
			Write-Info "Stopping scheduled task: $($task.TaskPath)$($task.TaskName)"
			try {
				Stop-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
				$stopped = $true
			}
			catch {
				Write-ErrorMessage "Failed to stop scheduled task $($task.TaskPath)$($task.TaskName): $($_.Exception.Message)"
			}
		}
	}

	return $stopped
}

function Test-PythonProcessesPresent {
	return [bool](Get-Process -Name 'python*' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(?i)python' })
}

try {
	Ensure-Administrator

	$serviceStopped   = Stop-PythonServices
	$processTerminated = Stop-PythonProcesses
	$tasksStopped     = Stop-PythonScheduledTasks

	if (-not ($serviceStopped -or $processTerminated -or $tasksStopped)) {
		Write-Info "No Python-related services, processes, or running tasks were found."
	}

	if (Test-PythonProcessesPresent) {
		Write-WarningMessage "Python processes are still running after attempted termination. Manual investigation is recommended."
		exit 1
	}

	Write-Success "No Python processes are currently running."
	exit 0
}
catch {
	Write-ErrorMessage "Script failed with error: $($_.Exception.Message)"
	Write-ErrorMessage "Line: $($_.InvocationInfo.ScriptLineNumber)"
	exit 1
}
finally {
	Write-Info "Script execution finished."
}
