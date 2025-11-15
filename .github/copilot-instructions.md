# Copilot Instructions for Scripts Repository

This repository is a comprehensive collection of scripts organized by programming language, category, and use-case subcategory.

## Repository Structure

The repository uses a strict **three-tier hierarchy**:

```text
{Language}/{Category}/{Subcategory}/script-name.ext
```

### Tier 1: Languages
- `Bash/` - Bash shell scripts
- `Go/` - Go language scripts
- `JavaScript/` - JavaScript/Node.js scripts
- `PowerShell/` - PowerShell scripts
- `Python/` - Python scripts
- `Ruby/` - Ruby scripts

### Tier 2: Categories
Each language directory contains these standardized categories:
- `automation/` - Task automation and scheduling scripts
- `data-processing/` - Data transformation, analysis, and manipulation
- `miscellaneous/` - Scripts that don't fit other specific categories
- `networking/` - Network utilities, monitoring, and management
- `system-administration/` - System management and administrative tools
- `text-processing/` - Text manipulation, parsing, and formatting
- `web-scraping/` - Web data extraction and scraping tools

### Tier 3: Subcategories
Each category contains use-case specific subdirectories:
- `api-integration/` - API clients, wrappers, and integration tools
- `backup/` - Backup and restore utilities
- `configuration/` - Configuration management and setup scripts
- `database/` - Database operations, queries, and management
- `deployment/` - Deployment automation and CI/CD scripts
- `file-operations/` - File and directory management utilities
- `logging/` - Logging utilities and log analysis tools
- `monitoring/` - System and application monitoring scripts
- `testing/` - Testing utilities, fixtures, and test automation

## Script Placement Rules

**CRITICAL**: Always place scripts in the correct location following the three-tier hierarchy.

Examples:
- PowerShell script for removing software → `PowerShell/miscellaneous/configuration/`
- Python script for database backups → `Python/automation/backup/`
- Bash script for log analysis → `Bash/text-processing/logging/`
- JavaScript API client → `JavaScript/networking/api-integration/`

## Naming Conventions

### File Naming
- Use **descriptive, kebab-case** names (lowercase with hyphens)
- Include action verbs when appropriate
- Examples:
  - `backup-mysql-database.py`
  - `monitor-system-resources.ps1`
  - `scrape-product-data.js`
  - `configure-nginx-ssl.sh`

### Directory Naming
- Stick to the predefined structure
- Use lowercase with hyphens for multi-word names
- Do NOT create new top-level categories without discussion

## Code Quality Standards

### General Requirements
- **Documentation**: Include clear header documentation and inline comments
- **Error Handling**: Implement appropriate error handling for all operations
- **Configuration**: Use external configuration/environment variables
- **Security**: Follow security best practices (see Security Guidelines below)
- **Testing**: Test thoroughly with valid inputs, invalid inputs, and edge cases

### Language-Specific Standards

#### PowerShell Scripts
- Use `#Requires` statements for prerequisites
- Include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`, `.PARAMETER`)
- Follow PowerShell naming conventions (Verb-Noun)
- Use approved PowerShell verbs
- Implement `-WhatIf` support for destructive operations
- Use proper parameter validation attributes

**Required Header Format**:
```powershell
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Brief description of what the script does
.DESCRIPTION
    Detailed description of functionality
.PARAMETER ParameterName
    Description of parameter
.EXAMPLE
    .\script-name.ps1 -Parameter Value
#>
```

#### Python Scripts
- Follow PEP 8 style guidelines
- Include docstrings for modules, classes, and functions
- Use type hints where appropriate
- Include `requirements.txt` for dependencies
- Use `argparse` for command-line arguments

**Required Header Format**:
```python
#!/usr/bin/env python3
"""
Brief description of the script.

Detailed description of functionality and usage.
"""
```

#### Bash Scripts
- Include shebang line (`#!/bin/bash`)
- Use `set -euo pipefail` for safer scripts
- Quote variables to prevent word splitting
- Document functions and complex operations
- Follow bash best practices

**Required Header Format**:
```bash
#!/bin/bash
# Script Name: script-name.sh
# Description: Brief description of functionality
# Author: Your Name
# Version: 1.0
```

#### JavaScript/Node.js Scripts
- Follow ESLint recommended rules
- Include JSDoc comments for functions
- Use `package.json` for Node.js dependencies
- Handle promises and async operations properly
- Include shebang for executable scripts: `#!/usr/bin/env node`

#### Go Scripts
- Follow Go formatting standards (`gofmt`)
- Include package documentation
- Handle errors explicitly
- Use Go modules for dependencies

#### Ruby Scripts
- Follow Ruby style guide
- Include method documentation
- Use Gemfile for dependencies
- Handle exceptions appropriately
- Include shebang: `#!/usr/bin/env ruby`

## Documentation Requirements

Every script MUST include:

1. **Header Documentation**
   - Purpose and functionality
   - Prerequisites and requirements
   - Usage examples
   - Parameter/argument descriptions

2. **Inline Comments**
   - Explain complex logic
   - Document important variables
   - Clarify non-obvious operations

3. **README Files** (for complex scripts with multiple files)
   - Installation instructions
   - Configuration details
   - Usage examples
   - Troubleshooting guide

## Security Guidelines

### CRITICAL Security Rules
- **NEVER hardcode credentials**, API keys, passwords, or sensitive information
- **ALWAYS validate and sanitize** all user inputs
- **ALWAYS use parameterized queries** for database operations
- **ALWAYS sanitize file paths** to prevent directory traversal
- **ALWAYS check file permissions** before file operations
- **ALWAYS escape output** when generating HTML or other formats

### Configuration Management
- Use **environment variables** for sensitive configuration
- Document required environment variables
- Provide example configuration files (without real values)

### Language-Specific Security
- **PowerShell**: Use `-WhatIf` parameters for destructive operations
- **Python**: Use libraries like `argparse` for input validation
- **Bash**: Quote variables and use `set -euo pipefail`
- **JavaScript**: Sanitize inputs and avoid `eval()`

## Testing Expectations

### Required Testing
Before submitting scripts, test with:
- **Valid inputs** (expected use cases)
- **Invalid inputs** (error conditions)
- **Edge cases** (empty inputs, maximum values, boundary conditions)
- **Different user permissions** (where applicable)

### Platform Testing Considerations
- Test on different operating systems (if cross-platform)
- Test with different versions of interpreters/runtime
- Verify in different user environments (paths, permissions)

## Working with This Repository

### When Adding Scripts
1. Determine the correct location using the three-tier hierarchy
2. Use the appropriate naming convention
3. Follow language-specific code quality standards
4. Include all required documentation
5. Test thoroughly before committing
6. Verify security best practices are followed

### When Modifying Scripts
1. Maintain existing style and conventions
2. Update documentation if functionality changes
3. Re-test after modifications
4. Do NOT remove existing error handling or validation

### Files to Review
- `INSTRUCTIONS.md` - Detailed repository instructions
- `CONTRIBUTING.md` - Contribution guidelines and checklists
- `README.md` - Repository overview
- `.github/PR_PREFERENCES.md` - Pull request workflow preferences

## Suitable Tasks for Copilot

### Good Tasks
- Adding new scripts following established patterns
- Improving documentation in existing scripts
- Adding error handling to scripts
- Fixing bugs in scripts
- Refactoring scripts to follow conventions
- Adding input validation
- Improving security practices

### Tasks Requiring Extra Caution
- Modifying scripts with complex dependencies
- Changes affecting production systems
- Security-sensitive operations
- Cross-language refactoring

## Important Notes

1. **Respect the Structure**: Do NOT create new categories or subcategories without explicit request
2. **Language Standards**: Always follow the language-specific standards for the script's language
3. **Security First**: When in doubt about security, err on the side of caution
4. **Test Everything**: All scripts must be tested before submission
5. **Documentation is Mandatory**: Never skip documentation, even for "simple" scripts
6. **Preserve Working Code**: Do NOT modify working code unless fixing bugs or security issues

## Git Workflow

This repository prefers:
- Use `git` commands for local operations (branch, commit, push)
- Create pull requests via GitHub web UI
- Avoid using `gh` CLI in automation
- Refer to `.github/PR_PREFERENCES.md` for detailed workflow guidance

## Copilot PR Review Policy

**IMPORTANT**: Do NOT automatically review pull requests when they are marked as "ready for review".
- Only perform PR reviews when explicitly requested by tagging @copilot in a comment
- Premium review requests should be used wisely and deliberately
- Wait for manual request before analyzing or reviewing code changes
