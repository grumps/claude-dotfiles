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

## Pull Requests

1. Create a branch: `git checkout -b feature/my-feature`
2. Make your changes
3. Test thoroughly
4. Commit following conventions
5. Push: `git push origin feature/my-feature`
6. Open pull request

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
