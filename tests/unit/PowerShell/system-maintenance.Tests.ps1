# tests/unit/PowerShell/system-maintenance.Tests.ps1

BeforeAll {
    # Suppress verbose output from the script itself during tests
    $VerbosePreference = 'SilentlyContinue'
    # Path to the script being tested - resolve to absolute path
    $testDir = $PSScriptRoot
    if (-not $testDir) {
        $testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if (-not $testDir) {
        $testDir = Get-Location
    }
    # Try to get scripts root from environment variable, else find repo root by traversing up to 'PowerShell' directory
    $scriptsRoot = $env:SCRIPTS_ROOT
    if (-not $scriptsRoot) {
        $currentDir = $testDir
        while ($true) {
            if (Test-Path (Join-Path $currentDir "PowerShell")) {
                $scriptsRoot = $currentDir
                break
            }
            $parentDir = Split-Path -Parent $currentDir
            if ($parentDir -eq $currentDir) {
                break
            }
            $currentDir = $parentDir
        }
    }
    if (-not $scriptsRoot) {
        throw "Could not determine scripts root. Set SCRIPTS_ROOT environment variable or ensure 'PowerShell' directory exists in a parent directory."
    }
    $scriptPathCandidate = Join-Path $scriptsRoot "PowerShell/system-administration/maintenance/system-maintenance.ps1"
    if (-not (Test-Path $scriptPathCandidate)) {
        throw "Script not found at: $scriptPathCandidate"
    }
    $script:scriptPath = Resolve-Path $scriptPathCandidate | Select-Object -ExpandProperty Path
}

Describe "system-maintenance.ps1" {
    Context "Basic Script Validation" {
        It "should be a valid script file" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "should have comment-based help" {
            $help = Get-Help $scriptPath -ErrorAction SilentlyContinue
            $help | Should -Not -BeNull
            $help.Name | Should -Be 'system-maintenance.ps1'
        }

        It "should support -WhatIf" {
            $command = Get-Command -Name $scriptPath
            $command.Parameters.Keys | Should -Contain 'WhatIf'
        }
    }

    Context "Execution Smoke Test" {
        It "should run without throwing errors with default parameters" {
            # Capture the path in a local variable to ensure it's available in the scriptblock
            $localPath = $scriptPath
            { & $localPath -WhatIf } | Should -Not -Throw
        }
    }
}
