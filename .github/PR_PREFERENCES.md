# Pull Request Preferences

This repository prefers plain Git for local operations and the GitHub web UI for
creating pull requests. This note documents that preference so contributors and
automation respect the chosen workflow.

## Recommendations

- Use git to create branches, stage, commit, and push. Example:

```powershell
# create branch, stage, commit and push
git checkout -b fix/my-change
git add <files>
git commit -m "Describe change"
git push -u origin fix/my-change
```

- Create the pull request using the GitHub web UI by visiting the branch URL.

  Example (replace placeholders with actual values):

  - `https://github.com/OWNER/REPO/pull/new/BRANCH`

  For this repository the shortcut after pushing a branch is:

  - `https://github.com/AprilDeFeu/Scripts/pull/new/BRANCH`

- Avoid using the GitHub CLI (`gh`) in automation for this repo. If you want to
  use `gh` in your local environment, that is fine — but do not rely on CI or
  repository-side automation that requires `gh` to be present.

- If you integrate other tools (for example GitKraken or GitHub Apps), only do
  so after confirming credentials and access are explicitly authorized.

## Why this preference

- Plain `git` is universally available and works in CI and local shells without
  adding additional tooling requirements.
- The web UI provides a clear, auditable PR creation step for maintainers.

If you'd like this document adjusted (formatting, wording, or to include a
specific workflow your team prefers), please open a PR against the main
branch.
