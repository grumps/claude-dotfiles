# Testing Checklist

Test the complete claude-dotfiles setup before releasing.

## Prerequisites Test

- [ ] Just is installed and in PATH
- [ ] Git is installed and configured
- [ ] Test repository is initialized

## Installation Test

### Fresh Installation

- [ ] Clone claude-dotfiles to ~/.claude-dotfiles
- [ ] Create test repository
- [ ] Run install.sh
- [ ] Verify all files created:
  - [ ] justfile exists
  - [ ] .claude/ directory created
  - [ ] .claude/skills/shared symlink exists
  - [ ] .claude/prompts/ contains templates
  - [ ] .git/hooks/pre-commit exists and is executable
  - [ ] .git/hooks/prepare-commit-msg exists
  - [ ] .claude/context.yaml exists

### Existing Installation

- [ ] Run install.sh in repo that already has justfile
- [ ] Verify script skips existing files
- [ ] No files are overwritten

## Justfile Tests

### Base Recipes

- [ ] `just` shows list of recipes
- [ ] `just --list` works
- [ ] `just validate` runs (will fail if lint/test not implemented)
- [ ] `just info` outputs repository information

### Recipe Implementation

- [ ] Override `lint` recipe in justfile
- [ ] `just lint` runs custom command
- [ ] Add custom recipe to justfile
- [ ] Custom recipe appears in `just --list`

## Skills Tests

### File Structure

- [ ] All skill files exist in ~/.claude-dotfiles/skills/
- [ ] planning/SKILL.md is comprehensive
- [ ] reviewing/SKILL.md is comprehensive
- [ ] commits/SKILL.md has examples
- [ ] justfile-integration/SKILL.md explains Just

### Symlink

- [ ] .claude/skills/shared points to correct location
- [ ] Can read files through symlink
- [ ] Changes to source files visible through symlink

## Prompt Templates Tests

### File Copies

- [ ] plan.md copied to .claude/prompts/
- [ ] review-code.md copied to .claude/prompts/
- [ ] review-plan.md copied to .claude/prompts/
- [ ] commit.md copied to .claude/prompts/

### Customization

- [ ] Edit a prompt template
- [ ] Original in ~/.claude-dotfiles unchanged
- [ ] Modified version in .claude/prompts

## Git Hooks Tests

### Pre-commit Hook

- [ ] Make a change
- [ ] Stage change: `git add .`
- [ ] Try to commit
- [ ] Hook runs `just validate`
- [ ] If validation configured:
  - [ ] Hook blocks commit on failure
  - [ ] Hook allows commit on success
- [ ] If validation not configured:
  - [ ] Hook shows warning but allows commit

### Skip Hook

- [ ] `git commit --no-verify` skips hook

### Prepare-commit-msg Hook

- [ ] Hook exists but not executable by default
- [ ] Enable: `chmod +x .git/hooks/prepare-commit-msg`
- [ ] `git commit` opens editor with template/generated message
- [ ] Hook doesn't run for merge commits

## Context File Tests

### Default Context

- [ ] context.yaml created with template
- [ ] Contains project section
- [ ] Contains languages section
- [ ] Contains conventions section

### Customization

- [ ] Edit context.yaml with project details

## Integration Tests

### Go Project

- [ ] Initialize Go project with go.mod
- [ ] Install claude-dotfiles
- [ ] Implement lint recipe: `golangci-lint run ./...`
- [ ] Implement test recipe: `go test ./...`
- [ ] Run `just validate`
- [ ] Make invalid Go code
- [ ] Verify `just lint` catches it
- [ ] Verify pre-commit hook blocks commit

### Python Project

- [ ] Initialize Python project
- [ ] Install claude-dotfiles
- [ ] Implement lint recipe: `ruff check .`
- [ ] Implement test recipe: `pytest`
- [ ] Run `just validate`
- [ ] Make invalid Python code
- [ ] Verify `just lint` catches it

### Kubernetes Project

- [ ] Create k8s/ directory with manifests
- [ ] Install claude-dotfiles
- [ ] Implement lint recipe with yamllint
- [ ] Implement validation using kubectl
- [ ] Run `just validate`
- [ ] Create invalid YAML
- [ ] Verify `just lint` catches it

## Claude Integration Tests

### Manual Testing with Claude Code

- [ ] Slash commands are available in .claude/commands/
- [ ] Request: "/plan add a feature"
- [ ] Claude asks clarifying questions
- [ ] Claude runs `just info`
- [ ] Claude generates structured plan
- [ ] Claude saves to .claude/plans/

- [ ] Stage some changes
- [ ] Request: "/review-code"
- [ ] Claude mentions running lint/test
- [ ] Claude provides structured review
- [ ] Review follows template format

- [ ] Request: "/commit"
- [ ] Claude analyzes staged changes
- [ ] Claude generates conventional commit
- [ ] Commit follows format from skill

- [ ] Ask Claude about available Just recipes
- [ ] Claude suggests using `just --list`
- [ ] Claude recommends Just recipes over raw commands

## Uninstall Tests

### Clean Uninstall

- [ ] Run uninstall.sh
- [ ] Hooks removed
- [ ] Symlinks removed
- [ ] Script asks before removing justfile
- [ ] Script asks before removing .claude/
- [ ] Repository returned to clean state

## Documentation Tests

### README

- [ ] Installation instructions are clear
- [ ] Prerequisites listed
- [ ] Quick start works
- [ ] Examples are accurate
- [ ] Links work (when published)

### Examples

- [ ] workflows.md examples are realistic
- [ ] Commands in examples work
- [ ] Examples cover common scenarios

### Comments in Code

- [ ] Justfiles have clear comments
- [ ] Skills have good explanations
- [ ] Scripts have usage documentation

## Edge Cases

### No Just Installed

- [ ] Pre-commit hook shows error message
- [ ] Error message tells how to install Just

### No Justfile

- [ ] Pre-commit hook shows warning
- [ ] Pre-commit hook doesn't fail

### Network Issues

- [ ] Installation works offline (no network calls)

### Permission Issues

- [ ] Install handles permission errors gracefully
- [ ] Scripts check for write permissions

## Performance Tests

### Large Repositories

- [ ] Install in repo with 1000+ files
- [ ] `just info` completes quickly
- [ ] Pre-commit hook runs in reasonable time

### Multiple Projects

- [ ] Install in project A
- [ ] Install in project B
- [ ] Both work independently
- [ ] Shared commands update affects both

## Compatibility Tests

### Operating Systems

- [ ] macOS
- [ ] Linux (Ubuntu)
- [ ] Windows (WSL)
- [ ] Windows (Git Bash)

### Shell

- [ ] bash
- [ ] zsh
- [ ] fish (if applicable)

### Git Versions

- [ ] Git 2.x
- [ ] Git 2.30+

## Regression Tests

After any changes:

- [ ] Re-run complete test suite
- [ ] Test upgrade from previous version
- [ ] Test in fresh environment
