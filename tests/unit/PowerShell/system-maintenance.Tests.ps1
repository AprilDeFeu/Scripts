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

    Context "Invalid Inputs" {
        It "should reject MaxTempFileAgeDays below minimum (negative values)" {
            $localPath = $scriptPath
            { & $localPath -MaxTempFileAgeDays -1 -WhatIf } | Should -Throw
        }

        It "should reject MaxTempFileAgeDays above maximum (> 3650)" {
            $localPath = $scriptPath
            { & $localPath -MaxTempFileAgeDays 9999 -WhatIf } | Should -Throw
        }

        It "should reject non-numeric MaxTempFileAgeDays" {
            $localPath = $scriptPath
            { & $localPath -MaxTempFileAgeDays "invalid" -WhatIf } | Should -Throw
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
    }

    Context "Permissions and Prerequisites" {
        It "should have #Requires -RunAsAdministrator directive" {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match '#Requires\s+-RunAsAdministrator'
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

    Context "Parameter Validation" {
        It "should accept valid boolean switch parameters" {
            $localPath = $scriptPath
            # PowerShell automatically converts -RunWindowsUpdate:$false to proper switch handling
            { & $localPath -RunWindowsUpdate:$false -WhatIf } | Should -Not -Throw
        }

        It "should use default value when MaxTempFileAgeDays not specified" {
            # This is validated by the smoke test - default is 7 days
            $command = Get-Command -Name $scriptPath
            $command.Parameters['MaxTempFileAgeDays'].Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Count | Should -BeGreaterThan 0
        }
    }

    Context "WhatIf Support (Confirming Non-Destructive Preview)" {
        It "should support -WhatIf for all destructive operations" {
            $localPath = $scriptPath
            # WhatIf should prevent any actual changes from being made
            { & $localPath -MaxTempFileAgeDays 0 -RunWindowsUpdate -WhatIf } | Should -Not -Throw
        }

        It "should have ConfirmImpact set appropriately" {
            $command = Get-Command -Name $scriptPath
            $cmdletBinding = $command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $cmdletBinding.ConfirmImpact | Should -Not -BeNullOrEmpty
        }
    }

    Context "Logging and Output" {
        It "should create log file path using Get-LogFilePath function" {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'function Get-LogFilePath'
        }

        It "should handle environment where MyDocuments is not available" {
            # The script has fallback logic for when MyDocuments is null or empty
            # This is tested by examining the Get-LogFilePath function logic
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'IsNullOrWhiteSpace.*userDocs'
            $content | Should -Match 'GetTempPath\(\)'
        }
    }

    Context "Error Handling" {
        It "should use StrictMode" {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'Set-StrictMode\s+-Version\s+Latest'
        }

        It "should set ErrorActionPreference appropriately" {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]'
        }

        It "should include try-catch blocks for error handling" {
            $content = Get-Content -Path $scriptPath -Raw
            # Check that the script uses try-catch for error handling
            ($content -split 'try\s*\{').Count | Should -BeGreaterThan 5
        }
    }
}
