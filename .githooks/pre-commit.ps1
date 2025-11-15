#!/usr/bin/env pwsh
# Pre-commit hook: Run Pester tests for system-maintenance.ps1 and save results
$ErrorActionPreference = 'Stop'
$testScript = 'PowerShell/system-administration/maintenance/system-maintenance.ps1'
$testPath = 'tests/unit/PowerShell/system-maintenance.Tests.ps1'
$resultsPath = 'tests/results/system-maintenance.xml'

if (Test-Path $testPath) {
    Write-Host "Running Pester tests for $testScript..."

    # Set SCRIPTS_ROOT environment variable for tests
    $env:SCRIPTS_ROOT = (Get-Location).Path

    # Use Pester v5 configuration syntax
    $config = New-PesterConfiguration
    $config.Run.Path = $testPath
    $config.Run.PassThru = $true
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = $resultsPath
    $config.TestResult.OutputFormat = 'JUnitXml'

    $result = Invoke-Pester -Configuration $config

    if ($result.FailedCount -gt 0) {
        Write-Host "Tests failed. Aborting commit."
        exit 1
    }

    if (Test-Path $resultsPath) {
        Write-Host "Test results saved to: $resultsPath"
    }
    else {
        Write-Host "Test results not found, aborting commit."
        exit 1
    }
}
