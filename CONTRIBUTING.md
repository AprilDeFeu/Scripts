# Contributing to Scripts Repository

Thank you for your interest in contributing to our Scripts repository!

This document provides specific guidelines for contributing scripts across different programming languages.

## Quick Start

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a feature branch for your script
4. **Follow** the placement and naming conventions
5. **Test** your script thoroughly
6. **Submit** a pull request

## Script Placement Guide

### Determining the Right Location

Follow this decision tree to place your script correctly:

```text
1. What programming language? → Choose language directory
2. What's the main purpose? → Choose category
3. What's the specific use case? → Choose subcategory
```

### Examples by Use Case

| Script Purpose | Suggested Location |
|----------------|-------------------|
| Automated database backup | `{Language}/automation/backup/` |
| Web scraping for data collection | `{Language}/web-scraping/api-integration/` |
| Log file analysis | `{Language}/text-processing/logging/` |
| System resource monitoring | `{Language}/system-administration/monitoring/` |
| Configuration deployment | `{Language}/automation/deployment/` |
| File cleanup utilities | `{Language}/miscellaneous/file-operations/` |

## Code Quality Checklist

### Pre-Submission Checklist

- [ ] **Documentation**: Script includes clear header documentation
- [ ] **Comments**: Complex logic is explained with inline comments
- [ ] **Error Handling**: Appropriate error handling is implemented
- [ ] **Input Validation**: User inputs are validated and sanitized
- [ ] **Testing**: Script has been tested with various scenarios
- [ ] **Dependencies**: External dependencies are documented
- [ ] **Security**: No hardcoded credentials or security vulnerabilities
- [ ] **Compatibility**: Platform/version requirements are specified

### Language-Specific Checklists

#### PowerShell Scripts

- [ ] Uses `#Requires` for prerequisites (admin rights, PowerShell version, modules)
- [ ] Includes comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`
- [ ] Parameters use proper types and validation attributes
- [ ] Functions use approved PowerShell verbs
- [ ] Error handling uses try/catch blocks appropriately
- [ ] Uses `$ErrorActionPreference` and `-ErrorAction` parameters
- [ ] Includes `-WhatIf` support for destructive operations

#### Python Scripts

- [ ] Includes proper shebang line (`#!/usr/bin/env python3`)
- [ ] Follows PEP 8 style guidelines
- [ ] Uses type hints for function parameters and return values
- [ ] Includes module-level docstring
- [ ] Functions have descriptive docstrings
- [ ] Uses `argparse` for command-line arguments
- [ ] Includes `requirements.txt` for external dependencies
- [ ] Handles exceptions appropriately

#### Bash Scripts

- [ ] Includes proper shebang (`#!/bin/bash`)
- [ ] Uses `set -euo pipefail` for safety
- [ ] Variables are quoted to prevent word splitting
- [ ] Functions are documented with comments
- [ ] Uses `local` variables in functions
- [ ] Includes usage information and help text
- [ ] Handles signals appropriately (trap)

#### JavaScript/Node.js Scripts

- [ ] Includes appropriate shebang for Node.js (`#!/usr/bin/env node`)
- [ ] Uses modern JavaScript features appropriately
- [ ] Includes JSDoc comments for functions
- [ ] Handles promises and async operations correctly
- [ ] Uses `package.json` for dependencies
- [ ] Includes error handling for async operations
- [ ] Validates input parameters

#### Go Scripts

- [ ] Follows Go formatting standards (use `gofmt`)
- [ ] Includes package documentation
- [ ] Uses Go modules for dependency management
- [ ] Handles errors explicitly (no ignored errors)
- [ ] Uses appropriate Go naming conventions
- [ ] Includes tests where applicable

#### Ruby Scripts

- [ ] Includes appropriate shebang (`#!/usr/bin/env ruby`)
- [ ] Follows Ruby style guide conventions
- [ ] Uses proper Ruby naming conventions
- [ ] Includes method documentation
- [ ] Uses Gemfile for dependencies
- [ ] Handles exceptions appropriately

## Security Guidelines

### Sensitive Information

- **Never commit** credentials, API keys, or passwords
- **Use environment variables** for configuration
- **Document** required environment variables
- **Provide example** configuration files (without real values)

### Input Validation

- **Validate all user inputs** before processing
- **Sanitize file paths** to prevent directory traversal
- **Use parameterized queries** for database operations
- **Escape output** when generating HTML or other formats

### File Operations

- **Check file permissions** before operations
- **Use absolute paths** when possible
- **Validate file extensions** and types
- **Implement proper cleanup** for temporary files

## Testing Requirements

### Basic Testing

All scripts must be tested with:

- **Valid inputs** (expected use cases)
- **Invalid inputs** (error conditions)
- **Edge cases** (empty inputs, maximum values)
- **Different user permissions** (where applicable)

### Platform Testing

Consider testing on:

- **Different operating systems** (if applicable)
- **Different versions** of interpreters/runtime
- **Different user environments** (paths, permissions)

### Documentation Testing

- **Verify examples work** as documented
- **Test installation instructions**
- **Validate dependency requirements**

## Documentation Standards

### Header Documentation Template

#### PowerShell Example

```powershell
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Brief one-line description of what the script does.

.DESCRIPTION
    Detailed description of the script's functionality, including:
    - What it does
    - When to use it
    - Any important limitations or requirements

.PARAMETER ParameterName
    Description of what this parameter does and expected values.

.EXAMPLE
    .\script-name.ps1 -Parameter Value
    Description of what this example does.

.EXAMPLE
    .\script-name.ps1 -Parameter Value -Verbose
    Description of this second example.

.NOTES
    Author: Your Name
    Version: 1.0
    Last Modified: YYYY-MM-DD
    
.LINK
    https://github.com/YourRepo/Scripts
#>
```

#### Python Example

```python
#!/usr/bin/env python3
"""
Script Name: Descriptive script name

Description:
    Detailed description of what the script does, including:
    - Primary functionality
    - Use cases
    - Important limitations

Requirements:
    - Python 3.8+
    - Required packages (see requirements.txt)
    - Any system requirements

Usage:
    python script_name.py [arguments]
    
Examples:
    python script_name.py --input file.txt --output result.txt
    python script_name.py --help

Author: Your Name
Version: 1.0
License: MIT
"""
```

### README Files for Complex Scripts

For scripts with multiple files or complex setup, include a README.md:

```markdown
# Script Name

Brief description of the script's purpose.

## Features

- List key features
- Highlight important capabilities

## Requirements

- System requirements
- Dependencies
- Prerequisites

## Installation

```bash
# Step-by-step installation commands
```

## Usage

```bash
# Basic usage examples
```

## Configuration

Details about configuration files or environment variables.

## Troubleshooting

Common issues and solutions.

## Review Process

### What Reviewers Look For

1. **Correct placement** in the repository structure
2. **Code quality** and adherence to language standards
3. **Security considerations** and best practices
4. **Documentation completeness** and clarity
5. **Testing evidence** (mention testing performed)

### Responding to Review Feedback

- **Address all comments** before requesting re-review
- **Explain your reasoning** for any disagreements
- **Test changes** after making modifications
- **Update documentation** if functionality changes

## Getting Help

### Before Asking for Help

1. **Check existing scripts** for similar patterns
2. **Review the INSTRUCTIONS.md** file
3. **Search closed issues** for similar problems

### How to Ask for Help

1. **Create an issue** with a clear title
2. **Describe your goal** and what you've tried
3. **Include relevant code snippets** (without sensitive data)
4. **Specify your environment** (OS, language version, etc.)

## Community Standards

### Code of Conduct

- **Be respectful** to all contributors
- **Provide constructive feedback** in reviews
- **Help newcomers** learn the conventions
- **Focus on the code**, not the person

### Recognition

Contributors are recognized through:

- **Git commit history**
- **Pull request discussions**
- **Issue interactions**

Thank you for contributing to make this repository a valuable resource for everyone!
