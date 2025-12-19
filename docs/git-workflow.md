# Git Workflow: Linear History

This repository follows a **strict linear history workflow** using rebase and squash.

## Overview

The goal is to maintain a clean, linear git history that is easy to understand, bisect, and review. Every feature branch should be rebased and squashed before merging into the main branch.

## Workflow Steps

### 1. Before Creating a Pull Request

When you're ready to create a pull request, follow these steps:

#### Step 1: Rebase and Squash Your Feature Branch

First, clean up your feature branch by squashing commits into discrete, logical units:

```bash
# Interactive rebase to squash commits
git rebase -i HEAD~N  # where N is the number of commits to review

# Or rebase from the branch point
git rebase -i $(git merge-base HEAD main)
```

**Squashing Guidelines:**

- **Prefer a single commit** for small features/fixes
- **Use multiple commits** only when they represent discrete, working changes:
  - Each commit should be a complete, working change
  - Each commit should pass tests independently
  - Each commit should have a clear, distinct purpose
  - Example: "add database schema" + "add API endpoints" + "add frontend UI"

**During Interactive Rebase:**

- Keep (`pick`) the first commit
- Squash (`squash` or `s`) subsequent commits into logical groups
- Edit commit messages to follow [Conventional Commits](https://www.conventionalcommits.org) (or use `/gdf:commit` for help)

#### Step 2: Pull Latest Changes from Main

```bash
# Fetch latest changes
git fetch origin main

# Pull and ensure you're up to date
git pull origin main --rebase
```

#### Step 3: Rebase Onto Main

Rebase your feature branch onto the latest main:

```bash
# Rebase your branch onto main
git rebase origin/main

# Resolve any conflicts
# After resolving each conflict:
git add .
git rebase --continue
```

#### Step 4: Force Push to Your Branch

After rebasing, you'll need to force push (your branch history has changed):

```bash
# Force push with lease (safer than --force)
git push origin YOUR_BRANCH_NAME --force-with-lease
```

### 2. Creating the Pull Request

After completing the rebase workflow:

```bash
# Create PR using GitHub CLI
gh pr create --title "feat(scope): description" --body "PR description"
```

## Complete Workflow Script

You can use the provided script to automate this workflow:

```bash
# Run the linear history workflow
./scripts/git-linear-history.sh
```

This script will:

1. Prompt you to squash commits interactively
2. Pull the latest main branch
3. Rebase your feature branch onto main
4. Push changes with force-with-lease

## Claude AI Instructions

**When Claude is asked to create a PR or finish a feature branch, Claude MUST:**

1. **Always rebase and squash first:**

   ```bash
   git rebase -i $(git merge-base HEAD main)
   ```

2. **Squash to single commit or discrete working commits:**
   - Default to single commit unless multiple logical units exist
   - Each remaining commit must be complete and working

3. **Pull and rebase onto main:**

   ```bash
   git fetch origin main
   git pull origin main --rebase
   git rebase origin/main
   ```

4. **Force push with lease:**

   ```bash
   git push origin BRANCH_NAME --force-with-lease
   ```

5. **Then create PR:**

   ```bash
   gh pr create --title "..." --body "..."
   ```

**Never skip these steps.** Linear history is a requirement, not optional.

## Why Linear History?

### Benefits

1. **Easier Code Review**
   - Each commit represents a complete change
   - No "fix typo" or "oops forgot file" commits
   - Reviewers can understand the change progression

2. **Better Bisect**
   - `git bisect` works cleanly when each commit is working
   - Easy to find which commit introduced a bug

3. **Cleaner History**
   - `git log` shows clear progression of features
   - No merge commits cluttering the history
   - Easy to understand project evolution

4. **Simpler Reverts**
   - Reverting a feature is one commit (or a few discrete commits)
   - No need to track down multiple scattered commits

### Example: Bad vs Good History

**Bad (without squash):**

```text
* fix typo in variable name
* forgot to commit test file
* update based on review feedback
* fix linting errors
* add user authentication feature
```

**Good (with squash):**

```text
* feat(auth): add user authentication with OAuth 2.0
```

Or with discrete commits:

```text
* feat(auth): add OAuth 2.0 frontend integration
* feat(auth): add OAuth 2.0 API endpoints
* feat(auth): add OAuth 2.0 database schema
```

## Handling Conflicts

When rebasing, you may encounter conflicts:

```bash
# During rebase, if conflicts occur:
# 1. Fix conflicts in your editor
# 2. Stage the resolved files
git add .

# 3. Continue the rebase
git rebase --continue

# If you want to abort and start over:
git rebase --abort
```

## Common Commands

```bash
# Check what commits will be squashed
git log origin/main..HEAD --oneline

# Interactive rebase from branch point
git rebase -i $(git merge-base HEAD main)

# Pull latest main and rebase
git fetch origin main && git rebase origin/main

# Force push safely
git push origin $(git branch --show-current) --force-with-lease

# Abort if something goes wrong
git rebase --abort
```

## Best Practices

1. **Commit often locally** - Small commits while developing
2. **Squash before PR** - Clean up before sharing
3. **Test after rebase** - Ensure everything still works
4. **Force push carefully** - Use `--force-with-lease` to avoid overwriting others' work
5. **Communicate** - Let team know if you're force pushing to a shared branch

## References

- [Conventional Commits](https://www.conventionalcommits.org)
- [Contributing Guidelines](../CONTRIBUTING.md)
- [Git Rebase Documentation](https://git-scm.com/docs/git-rebase)
