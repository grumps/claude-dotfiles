# Prepare Pull Request

[This file is used by Claude when preparing a branch for PR]

## Workflow

When preparing a pull request, follow the linear history workflow:

1. **Rebase and squash commits**
2. **Pull latest main branch**
3. **Rebase onto main**
4. **Force push branch**
5. **Create pull request**

## Instructions

See `commands/prepare-pr.md` for detailed workflow instructions.

**CRITICAL:** Never skip the rebase and squash steps. This repository requires strict linear history.
