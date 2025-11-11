# Scripts Repository Instructions

## Repository Overview

This repository serves as a comprehensive collection of scripts across multiple programming languages, organized using a systematic three-tier hierarchy for easy navigation and contribution.

## Repository Structure

### Three-Tier Organization System

```text
Language/Category/Subcategory/
```

#### 1. **Languages (Tier 1)**

Top-level directories organized by programming language:

- `Bash/` - Bash shell scripts
- `Go/` - Go language scripts
- `JavaScript/` - JavaScript/Node.js scripts
- `PowerShell/` - PowerShell scripts
- `Python/` - Python scripts
- `Ruby/` - Ruby scripts

#### 2. **Categories (Tier 2)**

Each language directory contains these standardized categories:

- `automation/` - Task automation and scheduling scripts
- `data-processing/` - Data transformation, analysis, and manipulation
- `miscellaneous/` - Scripts that don't fit other specific categories
- `networking/` - Network utilities, monitoring, and management
- `system-administration/` - System management and administrative tools
- `text-processing/` - Text manipulation, parsing, and formatting
- `web-scraping/` - Web data extraction and scraping tools

#### 3. **Subcategories (Tier 3)**

Each category contains these use-case specific subdirectories:

- `api-integration/` - API clients, wrappers, and integration tools
- `backup/` - Backup and restore utilities
- `configuration/` - Configuration management and setup scripts
- `database/` - Database operations, queries, and management
- `deployment/` - Deployment automation and CI/CD scripts
- `file-operations/` - File and directory management utilities
- `logging/` - Logging utilities and log analysis tools
- `monitoring/` - System and application monitoring scripts
- `testing/` - Testing utilities, fixtures, and test automation

## Contributing Guidelines

### Script Placement Rules

1. **Choose the correct language directory** based on the primary language used
2. **Select the appropriate category** based on the script's main purpose
3. **Place in the relevant subcategory** based on the specific use case

#### Examples

- PowerShell script for removing software → `PowerShell/miscellaneous/configuration/`
- Python script for database backups → `Python/automation/backup/`
- Bash script for log analysis → `Bash/text-processing/logging/`
- JavaScript API client → `JavaScript/networking/api-integration/`

### Naming Conventions

#### File Naming

- Use **descriptive, kebab-case** names for clarity
- Include action verbs when appropriate
- Examples:
  - `backup-mysql-database.py`
  - `monitor-system-resources.ps1`
  - `scrape-product-data.js`
  - `configure-nginx-ssl.sh`

#### Directory Naming

- Stick to the predefined structure
- Use lowercase with hyphens for multi-word subcategories
- Don't create new top-level categories without discussion

### Code Quality Standards

#### General Requirements

- **Documentation**: Include clear comments and documentation
- **Error Handling**: Implement appropriate error handling
- **Configuration**: Use external configuration where possible
- **Security**: Follow security best practices for your language

#### Language-Specific Standards

##### PowerShell Scripts

- Use `#Requires` statements for prerequisites
- Include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, etc.)
- Follow PowerShell naming conventions (Verb-Noun)
- Use approved PowerShell verbs
- Example header format:

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

##### Python Scripts

- Follow PEP 8 style guidelines
- Include docstrings for modules, classes, and functions
- Use type hints where appropriate
- Include requirements.txt for dependencies
- Example header format:

```python
#!/usr/bin/env python3
"""
Brief description of the script.

Detailed description of functionality and usage.
"""
```

##### Bash Scripts

- Include shebang line (`#!/bin/bash`)
- Use `set -euo pipefail` for safer scripts
- Document functions and complex operations
- Follow bash best practices
- Example header format:

```bash
#!/bin/bash
# Script Name: script-name.sh
# Description: Brief description of functionality
# Author: Your Name
# Version: 1.0
```

##### JavaScript/Node.js Scripts

- Follow ESLint recommended rules
- Include JSDoc comments for functions
- Use package.json for Node.js dependencies
- Handle promises and async operations properly

##### Go Scripts

- Follow Go formatting standards (`gofmt`)
- Include package documentation
- Handle errors explicitly
- Use Go modules for dependencies

##### Ruby Scripts

- Follow Ruby style guide
- Include method documentation
- Use Gemfile for dependencies
- Handle exceptions appropriately

### Script Documentation Requirements

Every script should include:

1. **Header Documentation**
   - Purpose and functionality
   - Prerequisites and requirements
   - Usage examples
   - Author information (optional)

2. **Inline Comments**
   - Explain complex logic
   - Document important variables
   - Clarify non-obvious operations

3. **README Files** (for complex scripts)
   - Installation instructions
   - Configuration details
   - Usage examples
   - Troubleshooting guide

### Testing and Validation

#### Before Committing

- **Test thoroughly** in appropriate environments
- **Verify error handling** with invalid inputs
- **Check compatibility** with target platforms
- **Validate security implications**

#### Recommended Testing Approach

- Test with various input scenarios
- Verify cleanup operations work correctly
- Test with different user permissions
- Document any platform-specific requirements

### Security Considerations

#### General Security Guidelines

- **Never hardcode credentials** or sensitive information
- **Validate all user inputs** to prevent injection attacks
- **Use secure communication** for network operations
- **Follow principle of least privilege**
- **Sanitize file paths** and user-provided data

#### Language-Specific Security

- **PowerShell**: Use `-WhatIf` parameters for destructive operations
- **Python**: Validate inputs with libraries like `argparse`
- **Bash**: Quote variables to prevent word splitting
- **JavaScript**: Sanitize inputs and avoid `eval()`

### Version Control Best Practices

#### Commit Guidelines

- Use clear, descriptive commit messages
- Follow conventional commit format when possible
- Keep commits focused on single changes
- Test before committing

#### Branching Strategy

- Create feature branches for new scripts
- Use descriptive branch names
- Create pull requests for review

### Maintenance and Updates

#### Regular Maintenance

- **Update dependencies** regularly
- **Review and update documentation**
- **Test compatibility** with new platform versions
- **Archive outdated scripts** when necessary

#### Deprecation Process

- Mark deprecated scripts clearly
- Provide migration path to newer alternatives
- Maintain for reasonable transition period
- Remove after sufficient notice

## Usage Examples

### Finding Scripts

Use the hierarchical structure to locate scripts:

```bash
# Looking for a PowerShell backup script
cd PowerShell/automation/backup/

# Looking for Python API integration
cd Python/networking/api-integration/

# Looking for system monitoring tools
find . -path "*/monitoring/*" -name "*.py"
```

### Adding New Scripts

1. **Determine placement**:

   ```text
   Language: Python (data analysis script)
   Category: data-processing
   Subcategory: database (works with database data)
   Path: Python/data-processing/database/
   ```

2. **Create the script** with proper documentation
3. **Test thoroughly** in target environment
4. **Commit with clear message**

### Repository Navigation

The structure supports easy navigation and discovery:

- Browse by **language** when you have a preference
- Browse by **category** when you need functionality
- Browse by **subcategory** for specific use cases

## Support and Questions

### Getting Help

- Check existing scripts for similar functionality
- Review language-specific README files
- Consult the main repository README.md

### Reporting Issues

- Provide clear reproduction steps
- Include environment details
- Specify affected scripts and versions

### Suggesting Improvements

- Follow the established structure
- Provide clear rationale for changes
- Consider impact on existing organization

## License

This repository is licensed under the MIT License. See the `LICENSE` file for details.

---

*This instruction document helps maintain consistency and quality across all scripts in the repository. Please follow these guidelines to ensure the repository remains well-organized and useful for all contributors.*
