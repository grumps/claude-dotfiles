# Justfile Integration Skill

This project uses Just (command runner) for task orchestration. All development tasks should go through Just recipes.

## Understanding Just

### What is Just?
Just is a command runner similar to Make but simpler and cross-platform. It uses a `justfile` to define recipes (tasks).

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

# Recipe with default parameter
recipe-with-default param="default-value":
  echo {{param}}
```

## Discovery

### When Starting Work
Always run `just` or `just --list` first to see available recipes:
```bash
just --list
```

This shows all recipes with their descriptions.

### Understanding Imports
The repo's justfile may import shared recipes:
```just
import? '~/.claude-dotfiles/justfiles/_base.just'
import? '~/.claude-dotfiles/justfiles/golang.just'
```

Recipes from imported files are available as if defined locally.

## Common Recipes

### Standard Recipes (from _base.just)
- `just validate` - Run all quality checks (lint + test)
- `just lint` - Run linters (must be implemented in project)
- `just test` - Run tests (must be implemented in project)
- `just info` - Display repository information and status
- `just check-clean` - Verify working directory is clean

### Project-Specific Recipes
Projects define their own `lint` and `test` implementations based on their needs.

Examples can be found in `~/.claude-dotfiles/examples/justfiles/` for:
- Go projects (golang.just)
- Python projects (python.just)
- Kubernetes projects (k8s.just)

## In Your Responses

### Prefer Just Recipes Over Raw Commands
**✅ Good**:
"Run `just test` to verify the changes"
"Validate with `just validate` before committing"

**❌ Avoid**:
"Run `go test ./...`" (unless Just recipe doesn't exist)
"Run `golangci-lint run`" (unless specific reason)

### When Recipe Doesn't Exist
If user needs functionality not in justfile:

1. Check if it should be added:
   "I don't see a `deploy` recipe. Want me to add one to your justfile?"

2. Provide both options:
   "You can run `kubectl apply -f k8s/` directly, or add it as a Just recipe for consistency."

### Suggesting New Recipes
When suggesting adding a recipe:
```just
# Add to your justfile
deploy-staging:
  kubectl apply -f k8s/ --context=staging
  kubectl rollout status deployment/myapp -n myapp
```

## Reading Justfiles

### How to Check Available Recipes
1. Look at repo's justfile
2. Check imported files in `~/.claude-dotfiles/justfiles/`
3. Run `just --list` to see all available recipes

### Understanding Recipe Dependencies
```just
# This recipe depends on lint and test
validate: lint test
  echo "All checks passed"
```

When user runs `just validate`, it runs `lint` and `test` first.

## Integration with Git Hooks

### Pre-commit Hook
The pre-commit hook runs `just validate`:
```bash
#!/bin/bash
just validate || exit 1
```

If validation fails, commit is blocked.

### Prepare-commit-msg Hook
May run `just commit-msg` to generate message.

## Best Practices

### Always Check for Recipes First
Before suggesting raw commands, check if a Just recipe exists.

### Encourage Recipe Creation
If user repeatedly runs the same command, suggest adding it as a recipe.

### Use Just for Consistency
Even if a task is simple, using Just creates consistency and discoverability.

### Document New Recipes
When adding recipes to justfile, include comments:
```just
# Deploy to staging environment with health checks
deploy-staging:
  kubectl apply -f k8s/ --context=staging
```

## Troubleshooting

### "Recipe not found"
- Check spelling
- Run `just --list` to see available recipes
- Recipe might be in imported file

### "Import failed"
- Check path to imported file
- Ensure `import?` (with `?`) is used for optional imports
