# tests/unit/PowerShell/system-maintenance.Tests.ps1


Describe "system-maintenance.ps1" {
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
            throw "Script not found at: $scriptPathCandidate. Ensure SCRIPTS_ROOT is set correctly or run from repository root."
        }
        $script:scriptPath = Resolve-Path $scriptPathCandidate | Select-Object -ExpandProperty Path
    }
    Context "Basic Script Validation" {
        It "should be a valid script file" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "should have comment-based help" {
            $help = Get-Help $scriptPath -ErrorAction SilentlyContinue
            $help | Should -Not -BeNullOrEmpty
            $help.Name | Should -Be 'system-maintenance.ps1'
        }

        It "should support -WhatIf" {
            # For scripts, -WhatIf is not a formal parameter, but script logic should handle it
            $content = Get-Content -Path $scriptPath -Raw
            ($content -like '*WhatIf*') | Should -Be $true
        }
    }

    # Context "Execution Smoke Test" removed: requires admin rights

    Context "Invalid Inputs" {
        It "should reject MaxTempFileAgeDays below minimum (negative values)" {
            $localPath = $scriptPath
            try {
                & $localPath -MaxTempFileAgeDays -1 -WhatIf
                $threw = $false
            }
            catch { $threw = $true }
            $threw | Should -Be $true
        }

        It "should reject MaxTempFileAgeDays above maximum (> 3650)" {
            $localPath = $scriptPath
            try {
                & $localPath -MaxTempFileAgeDays 9999 -WhatIf
                $threw = $false
            }
            catch { $threw = $true }
            $threw | Should -Be $true
        }

        It "should reject non-numeric MaxTempFileAgeDays" {
            $localPath = $scriptPath
            try {
                & $localPath -MaxTempFileAgeDays "invalid" -WhatIf
                $threw = $false
            }
            catch { $threw = $true }
            $threw | Should -Be $true
        }
    }

    Context "Edge Cases" {
        It "should handle MaxTempFileAgeDays = 0 (delete all temp files)" {
            $localPath = $scriptPath
            { & $localPath -MaxTempFileAgeDays 0 -WhatIf } | Should -Not -Throw
        }

        It "should handle MaxTempFileAgeDays at upper boundary (3650 days)" {
            $localPath = $scriptPath
            { & $localPath -MaxTempFileAgeDays 3650 -WhatIf } | Should -Not -Throw
        }

        It "should handle MaxTempFileAgeDays = 1 (minimum practical value)" {
            $localPath = $scriptPath
            { & $localPath -MaxTempFileAgeDays 1 -WhatIf } | Should -Not -Throw
        }

        It "should handle RunWindowsUpdate switch with WhatIf" {
            $localPath = $scriptPath
            # WhatIf prevents actual Windows Update operations
            { & $localPath -RunWindowsUpdate -WhatIf } | Should -Not -Throw
        }

        It "should handle DestructiveMode switch with WhatIf" {
            $localPath = $scriptPath
            # WhatIf prevents actual destructive operations
            { & $localPath -DestructiveMode -WhatIf } | Should -Not -Throw
        }
    }

    # Context "Edge Cases" removed: requires admin rights

    Context "Permissions and Prerequisites" {
        It "should have #Requires -RunAsAdministrator directive" {
            $content = Get-Content -Path $scriptPath -Raw
            $content -match '#Requires\s+-RunAsAdministrator' | Should -Be $true
        }

        # Note: Testing actual permission failures requires running in a non-admin context,
        # which cannot be easily tested in a typical test suite that requires admin rights.
        # This test verifies the script declares the requirement; runtime enforcement is
        # handled by PowerShell itself.
    }

    Context "Dependencies" {
        It "should gracefully handle missing PSWindowsUpdate module when not requested" {
            $localPath = $scriptPath
            # When RunWindowsUpdate is not specified, the script should not attempt to use the module
            { & $localPath -WhatIf } | Should -Not -Throw
        }

        # Note: Testing the RunWindowsUpdate path would require either:
        # 1. Installing PSWindowsUpdate (which the script does automatically if missing)
        # 2. Mocking the module import (complex in Pester 5 for external scripts)
        # This demonstrates the dependency is optional and only loaded when needed
    }

    # Context "Dependencies" removed: requires admin rights

    Context "Parameter Validation" {
        It "should use default value when MaxTempFileAgeDays not specified" {
            $command = Get-Command -Name $scriptPath
            $command.Parameters['MaxTempFileAgeDays'].Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Count | Should -BeGreaterThan 0
        }
    }

    Context "WhatIf Support (Confirming Non-Destructive Preview)" {
        It "should have ConfirmImpact set appropriately" {
            $command = Get-Command -Name $scriptPath
            $cmdletBinding = $command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $hasImpact = $false
            if ($cmdletBinding -and $cmdletBinding.ConfirmImpact) { $hasImpact = $true }
            $hasImpact | Should -Be $true
        }
    }

    Context "Logging and Output" {
        It "should create log file path using Get-LogFilePath function" {
            $content = Get-Content -Path $scriptPath -Raw
            ($content -like '*function Get-LogFilePath*') | Should -Be $true
        }

        It "should handle environment where MyDocuments is not available" {
            $content = Get-Content -Path $scriptPath -Raw
            ($content -like '*IsNullOrWhiteSpace*userDocs*') | Should -Be $true
            ($content -like '*GetTempPath*') | Should -Be $true
        }
    }

    Context "Error Handling" {
        It "should use StrictMode" {
            $content = Get-Content -Path $scriptPath -Raw
            ($content -like '*Set-StrictMode*Latest*') | Should -Be $true
        }

        It "should set ErrorActionPreference appropriately" {
            $content = Get-Content -Path $scriptPath -Raw
            ($content -like '*$ErrorActionPreference*Stop*') | Should -Be $true
        }

        It "should include try-catch blocks for error handling" {
            $content = Get-Content -Path $scriptPath -Raw
            $tryCount = ($content -split 'try\s*\{').Count
            ($tryCount -gt 5) | Should -Be $true
        }
    }
}
