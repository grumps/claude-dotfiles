#!/usr/bin/env python3
"""Remove repository from manifest."""

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    """Remove repository from manifest."""
    parser = argparse.ArgumentParser(description='Remove repository from manifest')
    parser.add_argument('repo', help='Repository name')
    args = parser.parse_args()

    manifest_path = Path('.claude/context/manifest.json')
    if not manifest_path.exists():
        print('No manifest found')
        return 0

    with open(manifest_path) as f:
        data = json.load(f)

    if args.repo in data.get('repositories', {}):
        del data['repositories'][args.repo]
        with open(manifest_path, 'w') as f:
            json.dump(data, f, indent=2, sort_keys=True)
            f.write('\n')
        print(f'✓ Removed {args.repo} from manifest')
    else:
        print('Repository not found in manifest')

    return 0


if __name__ == '__main__':
    sys.exit(main())
