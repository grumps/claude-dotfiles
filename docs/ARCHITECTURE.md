# Architecture Documentation

Design decisions and technical overview for Claude Dotfiles.

## Core Concepts

**Problem**: Claude Code can't know what commands to run for linting/testing across different projects (Go, Python, JavaScript, etc. all have different tools).

**Solution**: Define a protocol using Just recipes. Projects implement `lint` and `test` recipes using their specific tools. Claude calls standardized Just commands that work everywhere.

## How Components Work Together

1. **Just Recipes** - Shared base recipes in `~/.claude-dotfiles/justfiles/`
   - Projects import these and implement required recipes (`lint`, `test`)
   - Claude slash commands execute Just recipes to get lint/test results

2. **Slash Commands** - Markdown files in `~/.claude-dotfiles/commands/`
   - Symlinked to `~/.claude/commands/` so Claude Code can find them
   - Tell Claude how to run `just` commands and format output

3. **Git Hooks** - Pre-commit validation
   - Copied to `.git/hooks/` during installation
   - Runs `just validate` (lint + test) before allowing commits

### 1. Why Just Instead of Make?

**Decision**: Use Just as the task runner.

**Reasons**:

- Cross-platform (Make is POSIX-focused)
- Better error messages
- Simpler syntax (no tab requirements)
- Built for command running, not build systems

### 2. Symlinks vs Copies

**Decision**: Symlink commands to `~/.claude/`, copy hooks to projects.

**Reasons**:

- Commands rarely need per-project customization → symlink for easy updates
- Hooks often need project-specific tweaks → copy for isolation
- Prompts might be customized → copy to `.claude/prompts/` in projects

### 3. Global vs Per-Project

**Decision**: Install dotfiles globally, configure per-project.

**What's global** (in `~/.claude-dotfiles/` and `~/.claude/`):

- Shared Just recipes
- Slash command definitions
- Base hooks and prompts

**What's per-project** (in `your-project/`):

- justfile with project-specific `lint` and `test` implementations
- Git hooks (copies)
- Generated plans in `.claude/plans/`

**Why**: Allows consistent workflow across all projects while enabling project-specific tool configurations.

### 4. Pre-commit Hook Behavior

**Decision**: Pre-commit runs `just validate`, blocking commits that fail.

**Why**: Catches issues before they enter version control. Developers can skip with `--no-verify` if needed, but default is quality enforcement.

### 5. Plan Storage

**Decision**: Plans go in `.claude/plans/` within projects.

**Why**: Keeps AI-generated plans separate from human documentation, easy to `.gitignore` if desired, clear ownership.

## Extension Points

Want to customize? You can:

1. **Project level**: Edit your `justfile` to add custom recipes
2. **Team level**: Fork this repo and add team-specific commands/skills
3. **Tool integration**: Add scripts in `scripts/` for custom automation

## Related Documentation

- [README.md](../README.md) - Quick start and usage
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Development guidelines
- [examples/workflows.md](../examples/workflows.md) - Workflow examples

---

**Last Updated**: 2025-11-18
