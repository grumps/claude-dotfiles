---
description: Get help with Just command runner and available recipes
---

This project uses Just (command runner) for task orchestration. All development tasks should go through Just recipes.

## Quick Reference

### Discover Available Commands
```bash
just          # Show list (default recipe)
just --list   # Show all recipes with descriptions
```

### Standard Recipes
From `_base.just`:
- `just validate` - Run all quality checks (lint + test)
- `just lint` - Run linters (must be implemented in project justfile)
- `just test` - Run tests (must be implemented in project justfile)
- `just info` - Display repository information and status
- `just check-clean` - Verify working directory is clean

## Protocol

The justfile **protocol** requires projects to implement:
- **`lint`** - Run whatever linters your project needs
- **`test`** - Run whatever tests your project has

The `validate` recipe depends on these, ensuring quality checks pass before commits.

## How Just Works

### Basic Syntax
```just
# This is a comment

# A simple recipe
recipe-name:
  command to run
  another command

# Recipe with parameters
recipe-with-args param1 param2:
  echo {{param1}} {{param2}}

# Recipe with dependencies
validate: lint test
  echo "All checks passed"
```

### Imports
The project justfile imports the base protocol:
```just
import? '~/.claude-dotfiles/justfiles/_base.just'
```

The `?` makes imports optional - no error if file doesn't exist.

This import provides the `validate`, `info`, and `check-clean` recipes.

## In Your Responses

### Always Prefer Just Recipes
**✅ Good**:
- "Run `just test` to verify the changes"
- "Validate with `just validate` before committing"
- "Check your code with `just lint`"

**❌ Avoid**:
- "Run `go test ./...`" (use `just test` instead)
- "Run `golangci-lint run`" (use `just lint` instead)
- Suggesting raw tool commands when Just recipes exist

### When Recipe Doesn't Exist
If user needs functionality not in justfile:

1. **Check if it should be added**:
   "I don't see a `deploy` recipe. Want me to add one to your justfile?"

2. **Provide both options**:
   "You can run `kubectl apply -f k8s/` directly, or add it as a Just recipe for consistency."

### Suggesting New Recipes
When suggesting adding a recipe:
```just
# Add to your justfile
deploy-staging:
  kubectl apply -f k8s/ --context=staging
  kubectl rollout status deployment/myapp -n myapp
```

## Git Integration

### Pre-commit Hook
The pre-commit hook runs `just validate`:
- Runs before every commit
- Blocks commit if validation fails
- Skip with `git commit --no-verify`

### What This Means
Before committing, ensure:
```bash
just validate   # Must pass
```

If it fails:
```bash
just lint       # Fix linting issues
just test       # Fix test failures
```

## Troubleshooting

### "Recipe not found"
- Check spelling: `just --list`
- Recipe might be in imported file
- You might need to implement it (lint/test are required)

### "Import failed"
- Check path to imported file
- Ensure `~/.claude-dotfiles` exists
- Verify imports use `import?` (with `?`)

### Validation Passes But Code is Broken
- Check if `lint` and `test` are actually implemented
- Default template has them commented out
- Uncomment and customize for your project

## Best Practices

1. **Always check for recipes first** - Run `just --list` before suggesting commands
2. **Encourage recipe creation** - If user runs same command repeatedly, suggest adding a recipe
3. **Use Just for consistency** - Even simple tasks benefit from discoverability
4. **Document new recipes** - Include comments explaining what they do
