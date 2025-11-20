#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# ///
"""
Extract implementation stages from plans and create git worktrees.

This script parses plan files with JSON metadata blocks and creates
git worktrees for each stage, enabling parallel development.

Uses only Python stdlib - no external dependencies.

Usage:
    uv run scripts/planworktree.py list <plan-file>
    uv run scripts/planworktree.py setup <plan-file> <stage-id>
    uv run scripts/planworktree.py setup-all <plan-file>
    uv run scripts/planworktree.py status <plan-file>
"""

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import TypedDict, cast


# ANSI color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color


class Stage(TypedDict):
    """Stage definition from plan metadata."""

    id: str
    name: str
    branch: str
    worktree_path: str
    status: str
    depends_on: list[str]


class PlanMetadata(TypedDict):
    """Plan metadata structure."""

    plan_id: str
    created: str
    author: str
    status: str
    stages: list[Stage]


def print_error(msg: str) -> None:
    """Print error message in red."""
    print(f'{Colors.RED}{msg}{Colors.NC}', file=sys.stderr)


def print_success(msg: str) -> None:
    """Print success message in green."""
    print(f'{Colors.GREEN}{msg}{Colors.NC}')


def print_warning(msg: str) -> None:
    """Print warning message in yellow."""
    print(f'{Colors.YELLOW}{msg}{Colors.NC}')


def print_info(msg: str) -> None:
    """Print info message in blue."""
    print(f'{Colors.BLUE}{msg}{Colors.NC}')


def parse_plan_metadata(plan_file: Path) -> PlanMetadata | None:
    """
    Parse JSON metadata from plan markdown file.

    Looks for a fenced code block with 'json metadata' identifier.

    Args:
        plan_file: Path to the plan markdown file

    Returns:
        Parsed metadata dict or None if not found
    """
    content = plan_file.read_text()

    # Match ```json metadata ... ``` blocks
    pattern = r'```json metadata\s*\n(.*?)\n```'
    match = re.search(pattern, content, re.DOTALL)

    if not match:
        return None

    try:
        metadata = cast(PlanMetadata, json.loads(match.group(1)))
        return metadata
    except json.JSONDecodeError as e:
        print_error(f'Error parsing JSON metadata: {e}')
        return None


def get_stage_by_id(metadata: PlanMetadata, stage_id: str) -> Stage | None:
    """Get stage by ID from metadata."""
    for stage in metadata['stages']:
        if stage['id'] == stage_id:
            return stage
    return None


def print_table(headers: list[str], rows: list[list[str]]) -> None:
    """
    Print a simple ASCII table.

    Args:
        headers: List of column headers
        rows: List of rows, each row is a list of column values
    """
    # Calculate column widths
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(cell)))

    # Print separator
    def print_sep() -> None:
        print('+' + '+'.join('-' * (w + 2) for w in col_widths) + '+')

    # Print header
    print_sep()
    print('| ' + ' | '.join(h.ljust(col_widths[i]) for i, h in enumerate(headers)) + ' |')
    print_sep()

    # Print rows
    for row in rows:
        cells = ' | '.join(str(cell).ljust(col_widths[i]) for i, cell in enumerate(row))
        print(f'| {cells} |')

    print_sep()


def create_worktree(plan_file: Path, stage: Stage, metadata: PlanMetadata) -> bool:
    """
    Create git worktree for a stage.

    Args:
        plan_file: Path to plan file (for symlinking)
        stage: Stage definition
        metadata: Full plan metadata

    Returns:
        True if successful, False otherwise
    """
    stage_id = stage['id']
    stage_name = stage['name']
    branch = stage['branch']
    worktree_path = Path(stage['worktree_path']).expanduser()
    dependencies = stage.get('depends_on', [])

    print(f'\n{Colors.BOLD}=== Creating Worktree ==={Colors.NC}')
    print(f'{Colors.CYAN}Stage:{Colors.NC} {stage_name}')
    print(f'{Colors.CYAN}Stage ID:{Colors.NC} {stage_id}')
    print(f'{Colors.CYAN}Branch:{Colors.NC} {branch}')
    print(f'{Colors.CYAN}Path:{Colors.NC} {worktree_path}')

    if dependencies:
        dep_names = []
        for dep in dependencies:
            dep_stage = get_stage_by_id(metadata, dep)
            if dep_stage:
                dep_names.append(dep_stage['name'])
        print_warning(f'Dependencies: {", ".join(dep_names)}')
        print_warning('Ensure dependent stages are completed before merging')

    print()

    # Create parent directory
    worktree_path.parent.mkdir(parents=True, exist_ok=True)

    # Check if worktree already exists
    if worktree_path.exists():
        print_warning(f'Worktree already exists at {worktree_path}\n')
        return True

    # Check if branch exists
    result = subprocess.run(
        ['git', 'show-ref', '--verify', f'refs/heads/{branch}'], capture_output=True, text=True
    )
    branch_exists = result.returncode == 0

    try:
        if branch_exists:
            print_warning(f"Branch '{branch}' exists, using existing branch")
            subprocess.run(
                ['git', 'worktree', 'add', str(worktree_path), branch],
                check=True,
                capture_output=True,
            )
        else:
            print_success(f"Creating new branch '{branch}'")
            subprocess.run(
                ['git', 'worktree', 'add', '-b', branch, str(worktree_path)],
                check=True,
                capture_output=True,
            )

        # Create symlink to plan
        plan_link_dir = worktree_path / '.claude' / 'plans'
        plan_link_dir.mkdir(parents=True, exist_ok=True)
        plan_link = plan_link_dir / 'CURRENT_STAGE.md'

        # Create relative or absolute symlink to plan
        plan_realpath = plan_file.resolve()
        plan_link.symlink_to(plan_realpath)

        print_success('✓ Worktree created')
        print_success(f'✓ Plan symlinked to {plan_link}\n')
        return True

    except subprocess.CalledProcessError as e:
        print_error(f'Error creating worktree: {e}')
        if e.stderr:
            print_error(e.stderr.decode())
        return False


def list_stages(plan_file: Path) -> None:
    """List all stages in a plan."""
    metadata = parse_plan_metadata(plan_file)
    if not metadata:
        print_error('No metadata found in plan file')
        sys.exit(1)

    print(f'\n{Colors.BOLD}Plan:{Colors.NC} {metadata["plan_id"]}')
    print(f'{Colors.BOLD}Status:{Colors.NC} {metadata["status"]}\n')

    headers = ['ID', 'Name', 'Status', 'Branch', 'Dependencies']
    rows = []

    for stage in metadata['stages']:
        deps = ', '.join(stage.get('depends_on', [])) or 'None'
        rows.append([stage['id'], stage['name'], stage['status'], stage['branch'], deps])

    print_table(headers, rows)
    print()


def setup_stage(plan_file: Path, stage_id: str) -> None:
    """Setup worktree for a specific stage."""
    metadata = parse_plan_metadata(plan_file)
    if not metadata:
        print_error('No metadata found in plan file')
        sys.exit(1)

    stage = get_stage_by_id(metadata, stage_id)
    if not stage:
        print_error(f"Stage '{stage_id}' not found in plan")
        sys.exit(1)

    success = create_worktree(plan_file, stage, metadata)
    sys.exit(0 if success else 1)


def setup_all(plan_file: Path) -> None:
    """Setup worktrees for all stages."""
    metadata = parse_plan_metadata(plan_file)
    if not metadata:
        print_error('No metadata found in plan file')
        sys.exit(1)

    print_info(f'{Colors.BOLD}Setting up worktrees for all stages...{Colors.NC}\n')

    failures = []
    for stage in metadata['stages']:
        if not create_worktree(plan_file, stage, metadata):
            failures.append(stage['id'])

    if failures:
        print_error(f'Failed to create worktrees for: {", ".join(failures)}')
        sys.exit(1)
    else:
        print_success(f'{Colors.BOLD}All worktrees created successfully!{Colors.NC}\n')


def show_status(plan_file: Path) -> None:
    """Show status of all stages and their worktrees."""
    metadata = parse_plan_metadata(plan_file)
    if not metadata:
        print_error('No metadata found in plan file')
        sys.exit(1)

    print(f'\n{Colors.BOLD}Plan Status:{Colors.NC} {metadata["plan_id"]}\n')

    headers = ['Stage', 'Name', 'Stage Status', 'Worktree', 'Path']
    rows = []

    for stage in metadata['stages']:
        worktree_path = Path(stage['worktree_path']).expanduser()

        if worktree_path.exists():
            worktree_status = 'exists'
        else:
            worktree_status = 'not created'

        rows.append(
            [stage['id'], stage['name'], stage['status'], worktree_status, str(worktree_path)]
        )

    print_table(headers, rows)
    print()


def main() -> None:
    """Main entry point."""
    if len(sys.argv) < 3:
        print_error('Usage: planworktree.py <command> <plan-file> [stage-id]')
        print('\nCommands:')
        print('  list <plan-file>              - List all stages')
        print('  setup <plan-file> <stage-id>  - Setup specific stage')
        print('  setup-all <plan-file>         - Setup all stages')
        print('  status <plan-file>            - Show status')
        sys.exit(1)

    command = sys.argv[1]
    plan_file = Path(sys.argv[2])

    if not plan_file.exists():
        print_error(f'Plan file not found: {plan_file}')
        sys.exit(1)

    if command == 'list':
        list_stages(plan_file)
    elif command == 'setup':
        if len(sys.argv) < 4:
            print_error('Error: stage-id required for setup command')
            sys.exit(1)
        setup_stage(plan_file, sys.argv[3])
    elif command == 'setup-all':
        setup_all(plan_file)
    elif command == 'status':
        show_status(plan_file)
    else:
        print_error(f'Unknown command: {command}')
        sys.exit(1)


if __name__ == '__main__':
    main()
