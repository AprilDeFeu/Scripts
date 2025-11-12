---
description: "Repo-specific instructions for GitHub Copilot"
applyTo: "**"
---

# Copilot Instructions for the 'Scripts' Repository

When making changes to this repository, you MUST follow the established testing and security framework.

## 1. Pre-Commit Hooks are Mandatory

This repository uses `pre-commit` to enforce code quality, formatting, and security checks.

- **After making ANY file modifications**, you MUST run the local linter to ensure your changes are compliant. Simulate this by stating you are running the command:
  ```bash
  pre-commit run --all-files
  ```
- If any hooks fail, you MUST fix the reported issues before proceeding.

## 2. Testing is Required

All new scripts or modifications to existing scripts MUST be accompanied by tests.

- **Test Location:** Tests are located in the `tests/` directory, organized by unit, integration, etc., and then by language.
  - Example: `tests/unit/PowerShell/`
- **PowerShell:** New PowerShell scripts require new Pester tests. Add them in the appropriate directory.
- **Running Tests:** To validate your changes, run the appropriate test command. For PowerShell, this is:
  ```powershell
  Invoke-Pester -Path 'tests/unit/PowerShell'
  ```

## 3. Continuous Integration (CI)

- A CI workflow is located at `.github/workflows/ci.yml`.
- This pipeline automatically runs all `pre-commit` checks and all Pester tests.
- All changes must pass CI. Ensure your local checks are passing before you consider your task complete.

## 4. Emphasize Edge Case Testing

As a repository focused on quality, all scripts must be robust. When creating or modifying scripts, you are expected to:

- **Identify and Test Edge Cases:** Explicitly consider and test for null inputs, empty strings, zero values, large inputs, and unexpected data types.
- **Validate and Sanitize All Inputs:** Assume all input is untrustworthy.
- **Ensure Graceful Failure:** Scripts should fail with clear, actionable error messages, especially for permission errors or missing dependencies.

## 5. Adding New Languages

When adding a script for a new language (e.g., Python, Bash):

1.  **Update Pre-Commit:** Add the appropriate linter/formatter to `.pre-commit-config.yaml`.
    - **Python:** Use `ruff` and `black`.
    - **Bash:** `shellcheck` is already configured.
    - **JavaScript/TypeScript:** Use `prettier` and `eslint`.
2.  **Add Test Scaffolding:** Create a new directory under `tests/unit/` for the language.
3.  **Add a Test File:** Implement a basic smoke test for the new script, including at least one edge case test.
4.  **Update CI:** Add a new job to `.github/workflows/ci.yml` to run the tests for the new language.

By following these rules, you will help maintain the quality, consistency, and security of this repository.
