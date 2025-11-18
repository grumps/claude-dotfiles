# Contributing to Claude Dotfiles

Thanks for your interest in contributing!

## Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-dotfiles ~/.claude-dotfiles-dev
   ```
3. Create a test repository:
   ```bash
   mkdir test-repo && cd test-repo
   git init
   ```
4. Test your changes:
   ```bash
   ~/.claude-dotfiles-dev/install.sh
   ```

## Making Changes

### Code Style

**Python Projects:**
- Follow the [Python Style Guide](docs/python-style-guide.md)
- Key principles: readability over cleverness, explicit over implicit
- Use `just py-lint` and `just py-fmt` to check/format code
- Type hints required for all functions
- Docstrings required for all public functions

**General:**
- Use clear, descriptive variable names
- Add comments explaining why, not what
- Follow existing patterns in the codebase

### Justfiles
- Test all recipes work
- Add descriptions to new recipes
- Keep recipes focused (single responsibility)

### Skills
- Write in clear, instructional tone
- Include examples
- Be specific about process

### Documentation
- Update README for user-facing changes
- Update examples if workflows change
- Keep TESTING.md current

### Shell Scripts
- Run `just lint-shell` before committing
- ShellCheck validates scripts for common issues
- shfmt ensures consistent formatting
- Fix all warnings before submitting PR

## CI/CD and Local Validation

This repository uses **Just recipes** for all CI/CD tasks, ensuring local-CI parity. You can run the same validations locally that run in GitHub Actions.

### Available Validation Commands

**Shell Script Validation:**
```bash
just lint-shell        # Run ShellCheck + shfmt on all shell scripts
just format-shell      # Auto-format shell scripts with shfmt
```

**Full Validation:**
```bash
just validate          # Run all linters and tests (same as CI)
```

### CI/CD Architecture

- **Justfile-First**: All CI logic lives in Just recipes, not workflow YAML
- **Local-CI Parity**: Run `just <command>` locally to reproduce CI results
- **GitHub Actions**: Thin orchestration layer that calls Just recipes

### Fixing CI Failures

If GitHub Actions fails:

1. Check the workflow logs for the specific failure
2. Run the same Just command locally: `just lint-shell`
3. Fix the issues shown in the output
4. Re-run locally to verify the fix
5. Commit and push the fixes

**Example workflow:**
```bash
# CI failed on shell linting
just lint-shell                    # Reproduce the failure locally
# Fix the issues in your editor
just lint-shell                    # Verify the fix
git add .
git commit -m "fix: resolve shellcheck warnings"
git push
```

### Required Tools for Local Development

To run all validations locally, install:

- **Just** (task runner): https://just.systems
- **ShellCheck** (shell script linter): https://www.shellcheck.net
- **shfmt** (shell formatter): https://github.com/mvdan/sh

Installation:
```bash
# macOS
brew install just shellcheck shfmt

# Linux (Arch)
pacman -S just shellcheck shfmt

# Linux (Ubuntu/Debian)
apt-get install shellcheck
snap install just --classic
# For shfmt, download from: https://github.com/mvdan/sh/releases
```

## Testing

Run through TESTING.md checklist:
```bash
cat TESTING.md
```

Test in multiple scenarios:
- Fresh installation
- Existing installation
- Go project
- Python project
- K8s project

## Commit Messages

Follow conventional commits:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- refactor: Code refactor
- test: Testing changes
- chore: Maintenance

Examples:
```
feat(skills): add plan review skill

Adds SKILL.md for reviewing implementation plans with
checklist for completeness and technical approach.

docs(readme): clarify installation steps

Make it clearer that Just needs to be installed first
before running the installation script.

fix(hooks): handle missing justfile gracefully

Pre-commit hook now shows helpful message instead of
failing when justfile doesn't exist.
```

## Git Workflow: Linear History

**This repository requires a strict linear history workflow.**

Before creating a pull request, you MUST:

1. **Rebase and squash** your commits into single or discrete working commits
2. **Pull latest main** branch
3. **Rebase onto main** to ensure linear history
4. **Force push** your branch

See [docs/git-workflow.md](docs/git-workflow.md) for detailed instructions.

### Quick Commands

```bash
# Automated workflow (recommended)
./scripts/git-linear-history.sh

# Or manual workflow
git rebase -i $(git merge-base HEAD main)  # Squash commits
git fetch origin main                       # Get latest main
git rebase origin/main                      # Rebase onto main
git push origin YOUR_BRANCH --force-with-lease  # Force push
```

## Pull Requests

1. Create a branch: `git checkout -b feature/my-feature`
2. Make your changes
3. Test thoroughly
4. Commit following conventions
5. **Follow linear history workflow** (see above)
6. Push: `git push origin feature/my-feature --force-with-lease`
7. Open pull request

PR should include:
- Clear description of changes
- Why the change is needed
- Testing performed
- Screenshots (if UI/output changes)

## Questions?

- Open an issue for bugs
- Open a discussion for questions
- Tag maintainers for urgent matters

## Code of Conduct

Be respectful, constructive, and collaborative.
