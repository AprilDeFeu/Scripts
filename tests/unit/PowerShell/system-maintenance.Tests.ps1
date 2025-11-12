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
    $script:scriptPath = Join-Path $testDir "../../../PowerShell/system-administration/maintenance/system-maintenance.ps1" | Resolve-Path | Select-Object -ExpandProperty Path
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
