# Claude Dotfiles Project Guide

This repository provides Just task runner integration, slash commands, skills, and hooks for Claude Code.

## Project Context

**Tech Stack**: Bash, Python, Just, Git hooks, Markdown
**Purpose**: Provide reusable dotfiles and tooling for Claude Code across projects

## Key Directories

- `commands/` - Custom slash commands (see reference/slash-commands.md for documentation)
- `skills/` - AI skill guides referenced by commands
- `justfiles/` - Shared Just recipes for linting, testing, validation
- `hooks/` - Git hook templates
- `scripts/` - Utility scripts (Python and Bash)
- `prompts/` - Output format templates
- `docs/` - Documentation
- `examples/` - Example configurations and workflows
- `reference/` - Official Claude Code documentation

## Important Files

- `install.sh` - Installation script (symlinks commands, skills, sets up hooks)
- `uninstall.sh` - Cleanup script
- `justfile` - Development tasks for this repository
- `.claude/ci-contract.md` - CI/CD workflow contract

## Slash Commands

Custom slash commands are defined in `commands/`. Each command is a Markdown file that Claude Code executes.

**For detailed documentation on creating and using slash commands**, see:

- `reference/slash-commands.md` - Official Claude Code slash command documentation

Key features:

- Commands in `commands/` are project-specific
- Support frontmatter (allowed-tools, description, model, argument-hint)
- Can execute bash commands with `!` prefix
- Can reference files with `@` prefix
- Support arguments with `$ARGUMENTS`, `$1`, `$2`, etc.

## Skills

Skills are referenced by slash commands as documentation:

- `skills/commits/` - Commit message standards
- `skills/justfile-integration/` - Just recipe documentation
- `skills/planning/` - Planning methodology
- `skills/plan-worktree/` - Worktree workflow
- `skills/reviewing/` - Code review checklists

Skills are symlinked to `~/.claude/skills/` during installation.

## Development Workflow

### Testing Changes

```bash
just lint        # Run shellcheck, ruff
just test        # Run unit tests
just validate    # Run both lint and test
```

### Making Changes

1. Use `/plan` for complex features
2. Use `/review-code` before committing
3. Use `/commit` to generate commit messages
4. Follow Conventional Commits format

### Git Workflow

This repository enforces linear history:

- Squash commits before PR
- Rebase onto main
- Use `/prepare-pr` for assistance

See `docs/git-workflow.md` for details.

## Code Style

**Shell Scripts**:

- Use shellcheck and shfmt
- Follow Google Shell Style Guide
- Prefer `[[` over `[`
- Quote all variables

**Python**:

- Use ruff for linting and formatting
- Follow PEP 8
- Type hints where beneficial
- See `docs/python-style-guide.md`

**Markdown**:

- Use markdownlint
- Check links with lychee
- Follow consistent heading levels

## Quality Standards

All code must pass:

- `just lint` - No linting errors
- `just test` - All tests passing
- Git hooks run `just validate` automatically

## References

- `reference/slash-commands.md` - Official slash command documentation
- `docs/` - Project-specific documentation
- `README.md` - Installation and usage guide
- `CONTRIBUTING.md` - Development guidelines
- `TESTING.md` - Testing procedures
