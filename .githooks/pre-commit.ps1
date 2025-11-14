#!/usr/bin/env pwsh
# Pre-commit hook: Run Pester tests for system-maintenance.ps1 and save results
$ErrorActionPreference = 'Stop'
$testScript = 'PowerShell/system-administration/maintenance/system-maintenance.ps1'
$testPath = 'tests/unit/PowerShell/system-maintenance.Tests.ps1'
$resultsPath = 'tests/results/system-maintenance.json'

if (Test-Path $testPath) {
    Write-Host "Running Pester tests for $testScript..."
    Invoke-Pester -Script $testPath -OutputFormat NUnitXml -OutputFile $resultsPath
    if (Test-Path $resultsPath) {
        git add $resultsPath
        Write-Host "Test results saved and staged: $resultsPath"
    }
    else {
        Write-Host "Test results not found, aborting commit."
        exit 1
    }
}
