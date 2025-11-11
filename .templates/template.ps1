#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Brief one-line description of what this script does.

.DESCRIPTION
    Detailed description of the script's functionality, including:
    - What it does
    - When to use it
    - Any important limitations or requirements

.PARAMETER ParameterName
    Description of what this parameter does and expected values.

.PARAMETER Quiet
    Suppress non-essential output messages.

.EXAMPLE
    .\script-name.ps1 -ParameterName "value"
    Description of what this example does.

.EXAMPLE
    .\script-name.ps1 -ParameterName "value" -Quiet
    Description of this second example with quiet mode.

.NOTES
    Author: Your Name
    Version: 1.0
    Created: YYYY-MM-DD
    Last Modified: YYYY-MM-DD
    
    Prerequisites:
    - PowerShell 5.1 or later
    - Administrator privileges
    - Any specific modules or requirements

.LINK
    https://github.com/AprilDeFeu/Scripts
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Description of the parameter")]
    [ValidateNotNullOrEmpty()]
    [string]$ParameterName,
    
    [Parameter(Mandatory = $false)]
    [switch]$Quiet,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Set error handling
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Function definitions
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

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Main script logic
try {
    Write-Info "Starting script execution..."
    
    # Validate prerequisites
    if ($WhatIf) {
        Write-Info "WhatIf mode enabled - no changes will be made"
    }
    
    # Main script functionality goes here
    Write-Info "Processing parameter: $ParameterName"
    
    # Example of conditional execution
    if ($WhatIf) {
        Write-Info "Would perform action with parameter: $ParameterName"
    }
    else {
        # Actual execution logic here
        Write-Info "Performing action with parameter: $ParameterName"
    }
    
    Write-Success "Script completed successfully"
}
catch {
    Write-Error "Script failed with error: $($_.Exception.Message)"
    Write-Error "Line: $($_.InvocationInfo.ScriptLineNumber)"
    exit 1
}
finally {
    # Cleanup code here if needed
    Write-Info "Cleanup completed"
}