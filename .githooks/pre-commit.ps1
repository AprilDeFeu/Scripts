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

    # Ensure the results directory exists before running Pester
    New-Item -ItemType Directory -Path (Split-Path $resultsPath -Parent) -Force -ErrorAction SilentlyContinue | Out-Null

    # Use Pester v5 configuration syntax
    $config = New-PesterConfiguration
    $config.Run.Path = $testPath
    $config.Run.PassThru = $true
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = $resultsPath
    $config.TestResult.OutputFormat = 'JUnitXml'

    # Ensure the results directory exists before running Pester
    New-Item -ItemType Directory -Path (Split-Path $resultsPath -Parent) -Force -ErrorAction SilentlyContinue
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
else {
    Write-Host "Test file not found: $testPath"
    Write-Host "Cannot verify script quality. Aborting commit."
    exit 1
}
