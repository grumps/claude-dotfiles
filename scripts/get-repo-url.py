#!/usr/bin/env python3
"""Get repository URL from manifest."""

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    """Get repository URL from manifest."""
    parser = argparse.ArgumentParser(description='Get repository URL from manifest')
    parser.add_argument('repo', help='Repository name')
    args = parser.parse_args()

    manifest_path = Path('.claude/context/manifest.json')
    if not manifest_path.exists():
        print('Error: No manifest found', file=sys.stderr)
        return 1

    with open(manifest_path) as f:
        data = json.load(f)

    repos = data.get('repositories', {})
    if args.repo in repos:
        print(repos[args.repo]['url'])
        return 0
    else:
        print(f"Error: Repository '{args.repo}' not found in manifest", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
