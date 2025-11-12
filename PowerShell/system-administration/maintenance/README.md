# PowerShell — system-administration/maintenance

This folder contains PowerShell scripts focused on system maintenance tasks.

Typical responsibilities include package cleanup, service health checks,
temporary-file housekeeping, and other routine maintenance utilities.

## Usage and placement

- Place small, single-purpose maintenance scripts here.
- For complex tools with multiple files, include a top-level README and a
  subfolder with implementation files.

## Naming and contribution

- Use descriptive kebab-case names, e.g. `clean-temp-folders.ps1` or
  `check-service-health.ps1`.
- Add header documentation (comment-based help) and examples for each script.
- Include `-WhatIf` support for potentially destructive operations.

## Examples

- `clean-temp-folders.ps1` — remove old files from temporary directories
- `rotate-logs.ps1` — rotate and compress log files

Thank you for contributing maintenance scripts — please follow the
repository's contribution guidelines in the main `CONTRIBUTING.md`.
