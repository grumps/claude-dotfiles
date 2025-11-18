# Plan Worktree Management
# Recipes for working with implementation plans and git worktrees

# List all stages in a plan
plan-list plan-file:
  uv run scripts/planworktree.py list {{plan-file}}

# Show status of all stages and their worktrees
plan-status plan-file:
  uv run scripts/planworktree.py status {{plan-file}}

# Setup worktree for a specific stage
plan-stage plan-file stage-id:
  uv run scripts/planworktree.py setup {{plan-file}} {{stage-id}}

# Setup worktrees for all stages in a plan
plan-setup plan-file:
  uv run scripts/planworktree.py setup-all {{plan-file}}

# List all plans in .claude/plans/
plan-ls:
  #!/usr/bin/env bash
  echo "## Available Plans"
  echo ""
  if [ -d .claude/plans ]; then
    for plan in .claude/plans/*.md; do
      if [ -f "$plan" ]; then
        basename "$plan"
      fi
    done
  else
    echo "No .claude/plans directory found"
  fi

# Show active git worktrees
plan-worktrees:
  @git worktree list

# Remove a worktree (use with caution)
plan-remove worktree-path:
  git worktree remove {{worktree-path}}

# Prune deleted worktrees
plan-prune:
  git worktree prune

# Validate a plan file has proper JSON metadata
plan-validate plan-file:
  #!/usr/bin/env bash
  if ! grep -q '```json metadata' {{plan-file}}; then
    echo "❌ No JSON metadata block found in {{plan-file}}"
    exit 1
  fi

  # Extract and validate JSON
  python3 -c "
  import re
  import json
  import sys

  with open('{{plan-file}}') as f:
      content = f.read()

  match = re.search(r'\`\`\`json metadata\s*\n(.*?)\n\`\`\`', content, re.DOTALL)
  if not match:
      print('❌ Could not extract JSON metadata')
      sys.exit(1)

  try:
      metadata = json.loads(match.group(1))
      required_fields = ['plan_id', 'status', 'stages']
      for field in required_fields:
          if field not in metadata:
              print(f'❌ Missing required field: {field}')
              sys.exit(1)

      for i, stage in enumerate(metadata['stages']):
          stage_required = ['id', 'name', 'branch', 'worktree_path', 'status']
          for field in stage_required:
              if field not in stage:
                  print(f'❌ Stage {i}: Missing required field: {field}')
                  sys.exit(1)

      print(f'✅ Plan metadata is valid')
      print(f'   Plan ID: {metadata[\"plan_id\"]}')
      print(f'   Stages: {len(metadata[\"stages\"])}')
  except json.JSONDecodeError as e:
      print(f'❌ Invalid JSON: {e}')
      sys.exit(1)
  "
