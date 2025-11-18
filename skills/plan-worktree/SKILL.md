# Plan Worktree Skill

Extract implementation stages from plans and create git worktrees for parallel development.

## When to Use

- User wants to set up worktrees for a plan
- User needs to work on specific stage of a plan in isolation
- User wants to see status of plan stages and their worktrees
- User asks "how do I set up worktrees for this plan?"

## What This Skill Does

This skill works with plans that follow the stage-based template (see `.claude/prompts/plan.md`). It:

1. **Parses plan metadata** from JSON metadata block to extract stage definitions
2. **Creates git worktrees** for each stage at the specified paths
3. **Creates branches** for each stage following the naming convention
4. **Symlinks the plan** into each worktree for easy reference
5. **Tracks dependencies** between stages to help with merge ordering

## Prerequisites

The plan file must follow the stage-based template with JSON metadata block:

```json metadata
{
  "plan_id": "2025-11-17-my-feature",
  "status": "draft",
  "stages": [
    {
      "id": "stage-1",
      "name": "Component Name",
      "branch": "feature/plan-id-stage-1",
      "worktree_path": "../worktrees/plan-id/stage-1",
      "status": "not-started",
      "depends_on": []
    }
  ]
}
```

## Commands

### Using Just (Recommended)

```bash
# List all available plans
just plan-ls

# Validate plan metadata
just plan-validate .claude/plans/YYYY-MM-DD-feature.md

# List all stages in a plan
just plan-list .claude/plans/YYYY-MM-DD-feature.md

# Setup all worktrees
just plan-setup .claude/plans/YYYY-MM-DD-feature.md

# Setup single stage
just plan-stage .claude/plans/YYYY-MM-DD-feature.md stage-1

# Show status
just plan-status .claude/plans/YYYY-MM-DD-feature.md

# View all active worktrees
just plan-worktrees

# Remove a worktree
just plan-remove ../worktrees/plan-id/stage-1

# Prune deleted worktrees
just plan-prune
```

### Direct Python Script Usage

```bash
# List stages
uv run scripts/planworktree.py list .claude/plans/YYYY-MM-DD-feature.md

# Setup all stages
uv run scripts/planworktree.py setup-all .claude/plans/YYYY-MM-DD-feature.md

# Setup single stage
uv run scripts/planworktree.py setup .claude/plans/YYYY-MM-DD-feature.md stage-1

# Show status
uv run scripts/planworktree.py status .claude/plans/YYYY-MM-DD-feature.md
```

## Process

When a user wants to set up worktrees for a plan:

### 1. Validate the Plan
- Read the plan file from `.claude/plans/`
- Verify it has JSON metadata block with stage definitions
- Check that required fields are present (id, branch, worktree_path)

```bash
just plan-validate .claude/plans/YYYY-MM-DD-feature.md
```

### 2. Show Stage Overview
Run the `list` command to show the user what stages will be created:
```bash
just plan-list .claude/plans/YYYY-MM-DD-feature.md
```

Display:
- Stage IDs and names
- Current status (not-started/in-progress/complete)
- Branch names
- Dependencies between stages

### 3. Create Worktrees
Based on user preference, either:

**Option A: Setup all stages at once**
```bash
just plan-setup .claude/plans/YYYY-MM-DD-feature.md
```

**Option B: Setup individual stage**
```bash
just plan-stage .claude/plans/YYYY-MM-DD-feature.md <stage-id>
```

The script will:
- Create parent directories if needed
- Create new branch from current HEAD (or use existing branch)
- Add git worktree at specified path
- Create `.claude/plans/CURRENT_STAGE.md` symlink to the plan

### 4. Verify Setup
Show the user what was created:
```bash
just plan-status .claude/plans/YYYY-MM-DD-feature.md
```

Also show all active worktrees:
```bash
just plan-worktrees
```

### 5. Provide Next Steps
Tell the user:
- How to navigate to each worktree: `cd ../worktrees/plan-id/stage-1`
- Where to find the plan: `.claude/plans/CURRENT_STAGE.md` in each worktree
- How to start work: Run tests, verify the environment works
- Remind about dependencies: Which stages should be completed first

## Worktree Workflow

After worktrees are created, the development workflow is:

1. **Work in isolation**: Each stage has its own worktree
   ```bash
   cd ../worktrees/plan-id/stage-1
   # Make changes, run tests
   git add . && git commit -m "Implement stage 1"
   ```

2. **Reference the plan**: Plan is symlinked in each worktree
   ```bash
   cat .claude/plans/CURRENT_STAGE.md
   ```

3. **Check stage status**: Update plan metadata as stages progress
   ```bash
   # In main repo, update plan frontmatter:
   # Change status from "not-started" to "in-progress" to "complete"
   ```

4. **Merge stages**: When stage is complete, merge to main
   ```bash
   cd /path/to/main/repo
   git merge feature/plan-id-stage-1
   ```

5. **Handle dependencies**: Merge stages in dependency order
   ```bash
   # If stage-2 depends on stage-1:
   git merge feature/plan-id-stage-1  # First
   git merge feature/plan-id-stage-2  # Second
   ```

6. **Clean up**: Remove worktrees when done
   ```bash
   git worktree remove ../worktrees/plan-id/stage-1
   ```

## Directory Structure

After setup, the structure looks like:
```
project/
├── .git/
├── .claude/
│   └── plans/
│       └── 2025-11-17-my-feature.md  # Original plan
├── src/
└── ...

worktrees/
└── 2025-11-17-my-feature/
    ├── stage-1/                # Worktree for stage 1
    │   ├── .git                # Points to main .git
    │   ├── .claude/
    │   │   └── plans/
    │   │       └── CURRENT_STAGE.md -> symlink to plan
    │   └── src/                # Same source tree
    └── stage-2/                # Worktree for stage 2
        └── ...
```

## Error Handling

Handle these common issues:

- **Plan file not found**: Verify path, suggest using tab completion
- **No frontmatter**: Plan uses old format, suggest updating to new template
- **Worktree already exists**: Offer to skip or remove existing
- **Branch conflicts**: Branch name already exists, suggest using existing or renaming
- **Dependency violations**: Warn if trying to work on stage before dependencies complete

## Best Practices

- **Stage granularity**: Each stage should be a meaningful, testable component
- **Branch naming**: Follow convention `feature/{plan-id}-{stage-id}`
- **Worktree location**: Use `../worktrees/{plan-id}/{stage-id}` to keep separate from main repo
- **Plan updates**: Update stage status in plan as work progresses
- **Testing**: Test each stage in its worktree before merging
- **Clean up**: Remove worktrees after merging to save disk space

## Integration with Just

This skill includes Just recipes in `justfiles/plans.just`. Include it in your project's `justfile`:

```makefile
import? 'justfiles/plans.just'
```

Available recipes:
- `plan-ls` - List all plans
- `plan-validate` - Validate plan metadata
- `plan-list` - List stages in a plan
- `plan-setup` - Setup all worktrees
- `plan-stage` - Setup specific stage
- `plan-status` - Show plan status
- `plan-worktrees` - View active worktrees
- `plan-remove` - Remove a worktree
- `plan-prune` - Prune deleted worktrees

## Examples

### Example 1: Setting up worktrees for notification hooks plan

```bash
# List stages
just plan-list .claude/plans/2025-11-17-notification-hooks.md

# Output shows rich table with:
#   ID | Name | Status | Branch | Dependencies
#   stage-1 | Linux Implementation | not-started | feature/... | None
#   stage-2 | macOS Documentation | not-started | feature/... | stage-1

# Setup all at once
just plan-setup .claude/plans/2025-11-17-notification-hooks.md

# Work on stage 1
cd ../worktrees/notification-hooks/stage-1
# Implement Linux notification hooks
git commit -am "Implement Linux notification hooks"

# Back to main repo, check status
cd -
just plan-status .claude/plans/2025-11-17-notification-hooks.md

# Merge stage 1
git merge feature/notification-hooks-stage-1

# Now work on stage 2
cd ../worktrees/notification-hooks/stage-2
# Document macOS approach
git commit -am "Document macOS notification approach"

# Merge stage 2
cd -
git merge feature/notification-hooks-stage-2

# Clean up
just plan-remove ../worktrees/notification-hooks/stage-1
just plan-remove ../worktrees/notification-hooks/stage-2
just plan-prune
```

### Example 2: Working on single stage

```bash
# Setup only the stage you need
just plan-stage .claude/plans/2025-11-17-feature.md stage-3

# Work on it
cd ../worktrees/feature/stage-3
# ... make changes ...

# Check if dependencies are met before merging
just plan-list .claude/plans/2025-11-17-feature.md
# Rich table shows: stage-3 depends on: stage-1, stage-2
# Make sure those are merged first!
```

## Troubleshooting

### Worktree path doesn't exist
The script creates parent directories automatically. If you get permission errors, check directory ownership.

### Branch already exists
If the branch exists from previous work:
- The script will create a worktree from the existing branch
- You can continue where you left off
- Or delete the branch first: `git branch -D feature/plan-id-stage-1`

### Symlink broken
If `.claude/plans/CURRENT_STAGE.md` is broken:
- The plan file may have moved
- Recreate: `ln -sf /absolute/path/to/plan.md .claude/plans/CURRENT_STAGE.md`

### Can't remove worktree
If `git worktree remove` fails:
- Check for uncommitted changes
- Use `git worktree remove --force` if needed
- Or manually delete and run `git worktree prune`
