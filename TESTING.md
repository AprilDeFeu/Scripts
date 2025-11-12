# Testing Guide

This document outlines the testing framework for the `Scripts` repository.

## Local Testing

### 1. Pre-Commit Hooks (Linting & Formatting)

This repository uses `pre-commit` to run a suite of linters and formatters before each commit.

**Installation:**

1. Install Python 3.9+ and pip.
2. Install `pre-commit`:

   ```bash
   pip install pre-commit
   ```

3. Set up the git hooks:

   ```bash
   pre-commit install
   ```

**Usage:**

The hooks will run automatically on `git commit`. To run them manually across all files:

```bash
pre-commit run --all-files
```

### 2. PowerShell Unit Tests

PowerShell tests are written using the **Pester** framework.

**Prerequisites:**

*   PowerShell 7+
*   Pester module

**Installation (from PowerShell):**

```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

**Running Tests:**

To run all PowerShell unit tests:

```powershell
Invoke-Pester -Path 'tests/unit/PowerShell'
```

## Continuous Integration (CI)

The CI pipeline is defined in `.github/workflows/ci.yml` and runs automatically on pushes and pull requests to the
`main` branch.

It performs two main jobs:

1. **`lint`**: Runs all `pre-commit` hooks on an Ubuntu runner.
2. **`test-powershell`**: Runs all Pester tests on a Windows runner.
