---
description: Prepare feature branch for PR with linear history workflow
argument-hint: [base-branch]
---

# Prepare PR (ppr)

> Quick command: `/gdf:ppr [base-branch]` or `/ppr [base-branch]`
>
> Prepares feature branch for pull request by ensuring linear history,
> running tests, and creating PR with generated summary.

## Quick Reference

- **Usage**: `/ppr` or `/ppr main`
- **Arguments**:
  - `base-branch` (optional): Target branch for PR (defaults to main/master)
- **Prerequisites**: Feature branch with commits
- **Output**: Created pull request with summary and test plan

## Error Handling

- **Not on feature branch**: Shows error and current branch name
- **No commits to PR**: Shows error about missing commits
- **Rebase conflicts**: Guides through conflict resolution
- **Force push fails**: Shows error and suggests checking remote permissions
- **GH CLI not available**: Shows error about missing gh tool

## Examples

```bash
# Use default base branch
/ppr

# Specify base branch
/ppr develop
```

**CRITICAL: This repository requires a strict linear history workflow.**

When the user asks to prepare a PR, create a PR, or finish a feature branch, you MUST follow this workflow.

## Required Workflow Steps

### Step 1: Rebase and Squash Commits

**First, check current commits:**

```bash
git log origin/main..HEAD --oneline
```

**Then perform interactive rebase:**

```bash
git rebase -i $(git merge-base HEAD main)
```

**Squashing Guidelines:**

- **DEFAULT: Single commit** - Squash all commits into one for most features/fixes
- **Exception: Multiple discrete commits** - Only when each commit is:
  - A complete, working change on its own
  - Passes tests independently
  - Has a distinct, clear purpose
  - Example: "add database schema" + "add API endpoints" + "add UI components"

**During the interactive rebase:**

- Keep (`pick`) the first commit
- Squash (`squash` or `s`) all other commits into logical groups
- Edit the commit message to follow Conventional Commits format
- Ensure the final commit message is clear and descriptive

**Example rebase file:**

```text
pick abc1234 feat(feature): add new feature
squash def5678 fix typo
squash ghi9012 update tests
squash jkl3456 address review comments
```

### Step 2: Fetch Latest Main Branch

```bash
git fetch origin main
```

### Step 3: Rebase Onto Main

```bash
git rebase origin/main
```

**If conflicts occur:**

1. Resolve conflicts in affected files
2. Stage resolved files: `git add .`
3. Continue rebase: `git rebase --continue`
4. Repeat until rebase is complete

**If rebase fails and you need to abort:**

```bash
git rebase --abort
```

### Step 4: Force Push to Feature Branch

After rebasing, the branch history has changed, so force push is required:

```bash
git push origin BRANCH_NAME --force-with-lease
```

**Important:** Use `--force-with-lease` instead of `--force` for safety.

### Step 5: Create Pull Request

After completing the rebase workflow:

```bash
gh pr create --title "type(scope): description" --body "Detailed PR description"
```

## Complete Example

Here's what the full workflow looks like:

```bash
# 1. Check current commits
git log origin/main..HEAD --oneline

# 2. Interactive rebase to squash
git rebase -i $(git merge-base HEAD main)
# ... squash commits in the editor ...

# 3. Fetch latest main
git fetch origin main

# 4. Rebase onto main
git rebase origin/main
# ... resolve any conflicts ...

# 5. Force push
git push origin feature/my-feature --force-with-lease

# 6. Create PR
gh pr create --title "feat(auth): add OAuth 2.0 authentication" --body "..."
```

## Using the Automation Script

Alternatively, you can use the provided script that automates steps 1-4:

```bash
./scripts/git-linear-history.sh
```

This script will:

- Guide you through interactive rebase
- Fetch latest main
- Rebase onto main
- Force push your changes

## Claude AI Behavior

**When preparing a PR, Claude MUST:**

1. **NEVER skip the rebase and squash steps** - This is a hard requirement
2. **Always check commits first** to understand what needs to be squashed
3. **Default to single commit** unless there are genuinely discrete working changes
4. **Fetch and rebase onto main** before pushing
5. **Use `--force-with-lease`** when pushing after rebase
6. **Create PR only after** completing all rebase steps

## Why This Workflow?

This workflow ensures:

- **Clean history**: Easy to understand and review
- **Easy bisect**: Each commit is working and testable
- **Simple reverts**: Revert entire features with one command
- **Linear timeline**: No merge commits cluttering history

See [docs/git-workflow.md](../docs/git-workflow.md) for detailed explanation.

## Common Issues

### "Cannot force push"

- Make sure you're on a feature branch, not main
- Use `--force-with-lease` instead of `--force`

### "Rebase conflicts"

- Resolve conflicts in your editor
- `git add .` to stage resolved files
- `git rebase --continue` to proceed
- Or `git rebase --abort` to start over

### "Lost commits after rebase"

- Use `git reflog` to find lost commits
- `git cherry-pick COMMIT_HASH` to restore them

## References

- [Git Workflow Documentation](../docs/git-workflow.md)
- [Commit Message Standards](commit.md)
- [Contributing Guidelines](../CONTRIBUTING.md)
