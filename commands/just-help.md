---
description: Get help with Just command runner and available recipes
---

# Just Command Runner Help

This project uses Just for task orchestration. All development tasks should go through Just recipes.

## Quick Start

### Discover Available Recipes

```bash
just --list
```

Shows all available recipes with descriptions.

### Standard Recipes

From `_base.just` (imported by all projects):

- `just validate` - Run all quality checks (lint + test)
- `just lint` - Run linters (implemented per-project)
- `just test` - Run tests (implemented per-project)
- `just info` - Display repository information and status
- `just check-clean` - Verify working directory is clean

## The Just Protocol

Projects **must implement**:

- `lint` - Run project-specific linters
- `test` - Run project-specific tests

The `validate` recipe depends on these, ensuring quality before commits.

## How to Respond to Users

### Always Prefer Just Recipes

**✅ Correct**:

- "Run `just test` to verify changes"
- "Validate with `just validate`"

**❌ Avoid**:

- "Run `go test ./...`" (use `just test`)
- "Run `pytest`" (use `just test`)

### When Recipe Doesn't Exist

1. Offer to add it: "I don't see a `deploy` recipe. Want me to add one?"
2. Provide both options: "Run `kubectl apply -f k8s/` directly, or add a Just recipe for consistency."

### Suggesting New Recipes

```just
# Add to your justfile
recipe-name:
  command to run
```

## Integration Points

**Pre-commit Hook**: Runs `just validate` before every commit (blocks if fails)
**Post-edit Hook**: May run `just lint test` after code changes

## Reference

See `skills/justfile-integration/SKILL.md` for:

- Just syntax and features
- How imports work
- Best practices
- Troubleshooting guide
