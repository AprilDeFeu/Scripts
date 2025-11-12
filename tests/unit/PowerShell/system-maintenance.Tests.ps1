# tests/unit/PowerShell/system-maintenance.Tests.ps1

BeforeAll {
    # Suppress verbose output from the script itself during tests
    $VerbosePreference = 'SilentlyContinue'
    # Path to the script being tested
    $scriptPath = "$PSScriptRoot/../../../PowerShell/system-administration/maintenance/system-maintenance.ps1"
}

Describe "system-maintenance.ps1" {
    Context "Basic Script Validation" {
        It "should be a valid script file" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "should have comment-based help" {
            $help = Get-Help -Path $scriptPath -ErrorAction SilentlyContinue
            $help | Should -Not -BeNull
            ($help.Name -eq 'system-maintenance') | Should -Be $true
        }

        It "should support -WhatIf" {
            $command = Get-Command -Path $scriptPath
            $command.Parameters.Keys | Should -Contain 'WhatIf'
        }
    }

    Context "Execution Smoke Test" {
        It "should run without throwing errors with default parameters" {
            & $scriptPath -WhatIf | Should -Not -Throw
        }
    }
}
# tests/unit/PowerShell/system-maintenance.Tests.ps1

BeforeAll {
    # Suppress verbose output from the script itself during tests
    $VerbosePreference = 'SilentlyContinue'
    # Path to the script being tested
    $scriptPath = "$PSScriptRoot/../../../PowerShell/system-administration/maintenance/system-maintenance.ps1"
}

Describe "system-maintenance.ps1" {
    Context "Basic Script Validation" {
        It "should be a valid script file" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "should have comment-based help" {
            $help = Get-Help -Path $scriptPath -ErrorAction SilentlyContinue
            $help | Should -Not -BeNull
            ($help.Name -eq 'system-maintenance') | Should -Be $true
        }

        It "should support -WhatIf" {
            $command = Get-Command -Path $scriptPath
            $command.Parameters.Keys | Should -Contain 'WhatIf'
        }
    }

    Context "Execution Smoke Test" {
        It "should run without throwing errors with default parameters" {
            & $scriptPath -WhatIf | Should -Not -Throw
        }
    }
}
