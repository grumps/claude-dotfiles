#!/usr/bin/env python3
"""List all ingested repositories from manifest."""

import json
import sys
from pathlib import Path


def main() -> int:
    """List ingested repositories."""
    manifest_path = Path('.claude/context/manifest.json')

    if not manifest_path.exists():
        print('No repositories ingested yet.')
        return 0

    with open(manifest_path) as f:
        data = json.load(f)

    repos = data.get('repositories', {})
    if repos:
        for name, info in sorted(repos.items()):
            print(f'  {name}')
            print(f'    URL: {info["url"]}')
            print(f'    Version: {info["version"]}')
            print(f'    Commit: {info["commit_sha"][:8]}')
            print(f'    Ingested: {info["ingested_at"]}')
            print()
    else:
        print('  No repositories ingested yet.')

    return 0


if __name__ == '__main__':
    sys.exit(main())
