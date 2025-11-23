#!/usr/bin/env python3
"""
Ingest third-party repository into Claude context directory.

This script clones a repository, checks out a specific version, and copies
relevant files to .claude/context/ for Claude Code usage.
"""

import argparse
import fnmatch
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


class SecurityFilter:
    """Applies security and quality filters to repository files."""

    def __init__(self, global_config_path: Path, local_config_path: Path | None = None) -> None:
        """Load filter configuration from global and local sources."""
        # Load global filters
        with open(global_config_path) as f:
            self.config = json.load(f)
        self.global_filters = self.config.get('global_filters', {})
        self.allowlist = self.config.get('allowlist', [])

        # Merge local overrides if present
        if local_config_path and local_config_path.exists():
            with open(local_config_path) as f:
                local_config = json.load(f)
                self._merge_overrides(local_config)

    def _merge_overrides(self, local_config: dict[str, Any]) -> None:
        """Merge local configuration overrides into global filters."""
        repo_overrides = local_config.get('repository_overrides', {})
        for repo_name, overrides in repo_overrides.items():
            filters = overrides.get('filters', {})
            for filter_name, filter_config in filters.items():
                if filter_name in self.global_filters:
                    self.global_filters[filter_name].update(filter_config)

    def should_include_file(self, file_path: Path, repo_root: Path) -> bool:
        """Check if file should be included based on filters."""
        # Block symlinks (security risk)
        if os.path.islink(file_path):
            symlink_config = self.global_filters.get('symlinks', {})
            if symlink_config.get('enabled', True) and symlink_config.get('check_symlinks', True):
                # Check if symlink points outside repository
                try:
                    target = os.readlink(file_path)
                    if os.path.isabs(target) or '..' in target:
                        return False  # Block absolute or parent-directory symlinks
                except Exception:
                    return False  # Block if we can't read the symlink

        relative_path = file_path.relative_to(repo_root)
        relative_str = str(relative_path)

        # Check allowlist first (takes precedence)
        if self._matches_allowlist(relative_str):
            return True

        # Check file size limit
        large_binary_config = self.global_filters.get('large_binaries', {})
        if large_binary_config.get('enabled', True):
            max_size_mb = large_binary_config.get('max_file_size_mb', 1)
            try:
                size_mb = file_path.stat().st_size / (1024 * 1024)
                if size_mb > max_size_mb:
                    return False  # Filter out large files
            except Exception:
                pass  # If we can't stat, allow the file

        # Check each filter category
        for category, config in self.global_filters.items():
            if category in ('symlinks', 'large_binaries'):  # Skip special filters
                continue

            if not config.get('enabled', True):
                continue

            patterns = config.get('patterns', [])
            for pattern in patterns:
                if self._matches_pattern(relative_str, pattern):
                    return False  # Filtered out

        return True  # Include by default

    def _matches_allowlist(self, path: str) -> bool:
        """Check if path matches allowlist."""
        for pattern in self.allowlist:
            if fnmatch.fnmatch(path, pattern):
                return True
        return False

    def _matches_pattern(self, path: str, pattern: str) -> bool:
        """Check if path matches filter pattern (glob or regex)."""
        # Try glob matching first
        if fnmatch.fnmatch(path, pattern):
            return True
        # Could add regex matching here if needed
        return False

    def copy_filtered_files(
        self,
        source_dir: Path,
        dest_dir: Path,
        verbose: bool = False,
    ) -> dict[str, int]:
        """Copy files from source to dest, applying filters."""
        stats = {'included': 0, 'filtered': 0}

        for file_path in source_dir.rglob('*'):
            if file_path.is_file():
                if self.should_include_file(file_path, source_dir):
                    # Calculate destination path
                    rel_path = file_path.relative_to(source_dir)
                    dest_file = dest_dir / rel_path
                    dest_file.parent.mkdir(parents=True, exist_ok=True)

                    # Copy file
                    shutil.copy2(file_path, dest_file)
                    stats['included'] += 1
                else:
                    if verbose:
                        print(f'  Filtered: {file_path.relative_to(source_dir)}')
                    stats['filtered'] += 1

        return stats


class ContextExtractor:
    """Extracts contextual information from repository."""

    def __init__(self, repo_path: Path, repo_name: str) -> None:
        """Initialize context extractor."""
        self.repo_path = repo_path
        self.repo_name = repo_name

    def extract_context(self) -> dict[str, Any]:
        """Extract all contextual information."""
        return {
            'overview': self._extract_overview(),
            'installation': self._extract_installation(),
            'structure': self._detect_structure(),
            'examples': self._extract_examples(),
            'documentation_files': self._find_documentation(),
        }

    def _extract_overview(self) -> str:
        """Extract repository overview from README."""
        readme_paths = [
            'README.md',
            'README.rst',
            'README.txt',
            'readme.md',
        ]

        for readme in readme_paths:
            readme_file = self.repo_path / readme
            if readme_file.exists():
                # Read first 50 lines or up to first example
                try:
                    with open(readme_file, encoding='utf-8', errors='ignore') as f:
                        lines = []
                        for i, line in enumerate(f):
                            if i >= 50:
                                break
                            if '```' in line and i > 10:  # Stop at first code block
                                break
                            lines.append(line)
                        return ''.join(lines).strip()
                except Exception:
                    pass

        return f'No README found for {self.repo_name}'

    def _extract_installation(self) -> str:
        """Extract installation instructions."""
        # Look for installation section in README
        readme = self.repo_path / 'README.md'
        if readme.exists():
            try:
                with open(readme, encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    # Simple heuristic: find section with "install" in heading
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if line.startswith('#') and 'install' in line.lower():
                            # Extract next 10 lines
                            return '\n'.join(lines[i : i + 10])
            except Exception:
                pass

        # Fallback: detect package type
        if (self.repo_path / 'setup.py').exists() or (self.repo_path / 'pyproject.toml').exists():
            return f'`pip install {self.repo_name}`'
        elif (self.repo_path / 'go.mod').exists():
            return '`go get <module_path>`'
        elif (self.repo_path / 'package.json').exists():
            return f'`npm install {self.repo_name}`'
        elif (self.repo_path / 'Cargo.toml').exists():
            return f'`cargo add {self.repo_name}`'

        return 'See README for installation instructions'

    def _detect_structure(self) -> dict[str, Any]:
        """Detect repository structure (language, type, entry points)."""
        structure: dict[str, Any] = {
            'language': 'unknown',
            'type': 'unknown',  # library, application, framework
            'entry_points': [],
        }

        # Detect language
        if (self.repo_path / 'setup.py').exists() or (self.repo_path / 'pyproject.toml').exists():
            structure['language'] = 'Python'
            structure['type'] = 'library'
        elif (self.repo_path / 'go.mod').exists():
            structure['language'] = 'Go'
            structure['type'] = 'library'
        elif (self.repo_path / 'package.json').exists():
            structure['language'] = 'JavaScript/TypeScript'
            structure['type'] = 'library'
        elif (self.repo_path / 'Cargo.toml').exists():
            structure['language'] = 'Rust'
            structure['type'] = 'library'
        elif (self.repo_path / 'pom.xml').exists() or (self.repo_path / 'build.gradle').exists():
            structure['language'] = 'Java'
            structure['type'] = 'library'

        return structure

    def _extract_examples(self) -> list[str]:
        """Extract code examples from documentation."""
        examples = []

        # Look in common locations
        example_paths = [
            'examples/',
            'EXAMPLES.md',
            'docs/examples/',
        ]

        for path in example_paths:
            full_path = self.repo_path / path
            if full_path.exists():
                if full_path.is_dir():
                    # List example files
                    for pattern in ['**/*.py', '**/*.go', '**/*.js', '**/*.rs']:
                        for ex_file in full_path.glob(pattern):
                            rel_path = str(ex_file.relative_to(self.repo_path))
                            examples.append(rel_path)
                            if len(examples) >= 5:
                                break
                        if len(examples) >= 5:
                            break
                else:
                    # Extract code blocks from markdown
                    try:
                        with open(full_path, encoding='utf-8', errors='ignore') as f:
                            content = f.read()
                            # Simple extraction of code blocks
                            in_code_block = False
                            code_block: list[str] = []
                            for line in content.split('\n'):
                                if line.startswith('```'):
                                    if in_code_block:
                                        examples.append('\n'.join(code_block))
                                        code_block = []
                                        if len(examples) >= 5:
                                            break
                                    in_code_block = not in_code_block
                                elif in_code_block:
                                    code_block.append(line)
                    except Exception:
                        pass

            if len(examples) >= 5:
                break

        return examples[:5]  # Limit to first 5 examples

    def _find_documentation(self) -> list[str]:
        """Find key documentation files."""
        doc_files = []

        # Common documentation patterns
        patterns = [
            'README.md',
            'USAGE.md',
            'API.md',
            'CONTRIBUTING.md',
            'LICENSE',
            'NOTICE',
        ]

        for pattern in patterns:
            for file in self.repo_path.glob(pattern):
                if file.is_file():
                    doc_files.append(str(file.relative_to(self.repo_path)))

        # Add docs directory files
        docs_dir = self.repo_path / 'docs'
        if docs_dir.exists() and docs_dir.is_dir():
            for file in docs_dir.glob('**/*.md'):
                if file.is_file():
                    rel_path = str(file.relative_to(self.repo_path))
                    doc_files.append(rel_path)

        return sorted(doc_files)

    def generate_context_md(self, context_data: dict[str, Any]) -> str:
        """Generate CONTEXT.md content from extracted data."""
        sections = [
            f'# Context: {self.repo_name}',
            '',
            'This file provides contextual information about the repository for Claude Code.',
            '',
            '## Overview',
            '',
            context_data['overview'],
            '',
            '## Repository Structure',
            '',
            f'- **Language**: {context_data["structure"]["language"]}',
            f'- **Type**: {context_data["structure"]["type"]}',
            '',
            '## Installation',
            '',
            context_data['installation'],
            '',
            '## Key Documentation Files',
            '',
        ]

        for doc_file in context_data['documentation_files']:
            sections.append(f'- `{doc_file}`')

        if context_data['examples']:
            sections.append('')
            sections.append('## Example Usage')
            sections.append('')
            for i, example in enumerate(context_data['examples'], 1):
                if isinstance(example, str) and '\n' in example:
                    sections.append(f'### Example {i}')
                    sections.append('')
                    sections.append('```')
                    sections.append(example)
                    sections.append('```')
                    sections.append('')
                else:
                    sections.append(f'- See: `{example}`')

        sections.append('')
        sections.append('## Full Repository')
        sections.append('')
        sections.append(
            'Full repository contents are available in this directory. '
            'Use standard file operations to explore the codebase.'
        )
        sections.append('')

        return '\n'.join(sections)


class RepoIngestion:
    """Handles ingestion of third-party repositories."""

    def __init__(
        self,
        repo_url: str,
        version: str,
        context_dir: Path,
        cache_dir: Path,
        filter_config_path: Path,
        verbose: bool = False,
    ) -> None:
        """Initialize repository ingestion."""
        self.repo_url = self._validate_url(repo_url)
        self.version = version
        self.context_dir = context_dir
        self.cache_dir = cache_dir
        self.verbose = verbose
        self.repo_name = self._extract_and_sanitize_repo_name(repo_url)
        self.repo_hash = hashlib.sha256(repo_url.encode()).hexdigest()[:16]

        # Initialize security filter
        local_filter_path = Path('.claude/ingestion-filters.json')
        self.security_filter = SecurityFilter(
            filter_config_path, local_filter_path if local_filter_path.exists() else None
        )

    def _validate_url(self, url: str) -> str:
        """Validate repository URL to prevent injection attacks."""
        try:
            parsed = urlparse(url)
            # Ensure scheme is http/https/git/ssh
            if parsed.scheme and parsed.scheme not in ('http', 'https', 'git', 'ssh'):
                raise ValueError(f'Invalid URL scheme: {parsed.scheme}')
            return url
        except Exception as e:
            raise ValueError(f'Invalid repository URL: {e}')

    def _extract_and_sanitize_repo_name(self, url: str) -> str:
        """Extract and sanitize repository name from URL."""
        # Check for path traversal attempts in URL before extraction
        if '..' in url:
            raise ValueError(f'Invalid repository URL (contains ".."): {url}')

        # Handle github.com/org/repo or git@github.com:org/repo
        parts = url.rstrip('/').rstrip('.git').split('/')
        raw_name = parts[-1]

        # Reject empty names
        if not raw_name or raw_name in ('.', '..'):
            raise ValueError(f'Invalid repository name: {raw_name}')

        # Sanitize: allow only alphanumeric, hyphens, underscores
        # Replace any other characters with hyphen
        sanitized = re.sub(r'[^a-zA-Z0-9_-]', '-', raw_name)

        # Prevent path traversal attempts and ensure valid name
        if sanitized.startswith('.') or '/' in sanitized or '\\' in sanitized or not sanitized:
            raise ValueError(f'Invalid repository name: {raw_name}')

        return sanitized

    def clone_or_update(self) -> Path:
        """Clone repository to cache or update if exists."""
        clone_path = self.cache_dir / self.repo_hash

        if clone_path.exists():
            print(f'Updating cached repository: {self.repo_name}')
            subprocess.run(
                ['git', 'fetch', '--all', '--tags'],
                cwd=clone_path,
                check=True,
            )
        else:
            print(f'Cloning repository: {self.repo_name}')
            subprocess.run(
                ['git', 'clone', self.repo_url, str(clone_path)],
                check=True,
            )

        return clone_path

    def checkout_version(self, clone_path: Path) -> None:
        """Checkout specific version (branch, tag, or commit)."""
        print(f'Checking out version: {self.version}')
        subprocess.run(
            ['git', 'checkout', self.version],
            cwd=clone_path,
            check=True,
        )

    def get_commit_info(self, clone_path: Path) -> dict[str, str]:
        """Get commit SHA and date for manifest."""
        result = subprocess.run(
            ['git', 'log', '-1', '--format=%H|%ai'],
            cwd=clone_path,
            capture_output=True,
            text=True,
            check=True,
        )
        sha, date = result.stdout.strip().split('|')
        return {'commit_sha': sha, 'commit_date': date}

    def ingest(self) -> None:
        """Run full ingestion workflow."""
        # Clone or update repository
        clone_path = self.clone_or_update()

        # Checkout requested version
        self.checkout_version(clone_path)

        # Check repository size and warn if large
        self._check_repo_size(clone_path)

        # Get commit metadata
        commit_info = self.get_commit_info(clone_path)

        # Create destination directory
        dest_dir = self.context_dir / self.repo_name
        dest_dir.mkdir(parents=True, exist_ok=True)

        # Apply security filters and copy files
        print('Copying files with security filtering...')
        stats = self.security_filter.copy_filtered_files(clone_path, dest_dir, verbose=self.verbose)
        print(f'  Files: {stats["included"]} included, {stats["filtered"]} filtered')

        # Extract context and generate CONTEXT.md
        print('Extracting context documentation...')
        extractor = ContextExtractor(dest_dir, self.repo_name)
        context_data = extractor.extract_context()
        context_md = extractor.generate_context_md(context_data)

        # Write CONTEXT.md
        context_file = dest_dir / 'CONTEXT.md'
        with open(context_file, 'w', encoding='utf-8') as f:
            f.write(context_md)
        print('  Generated: CONTEXT.md')

        # Update manifest
        self._update_manifest(commit_info)

        # Ensure .gitignore excludes context directory
        self._update_gitignore()

        print(f'✓ Ingested {self.repo_name} @ {self.version}')
        print(f'  Location: {dest_dir}')
        print(f'  Commit: {commit_info["commit_sha"][:8]}')

    def _check_repo_size(self, clone_path: Path) -> None:
        """Check repository size and warn if large."""
        try:
            result = subprocess.run(
                ['du', '-sm', str(clone_path)],
                capture_output=True,
                text=True,
                check=True,
            )
            size_mb = int(result.stdout.split()[0])
            if size_mb > 50:
                print(f'⚠️  Warning: Repository is large ({size_mb}MB)')
                print('   This may consume significant disk space.')
        except Exception:
            pass  # If du fails, just skip the warning

    def _update_manifest(self, commit_info: dict[str, str]) -> None:
        """Update manifest with ingestion metadata."""
        manifest_path = self.context_dir / 'manifest.json'

        # Load existing manifest or create new
        if manifest_path.exists():
            with open(manifest_path) as f:
                manifest = json.load(f)
        else:
            manifest = {'repositories': {}}

        # Add/update repository entry
        manifest['repositories'][self.repo_name] = {
            'url': self.repo_url,
            'version': self.version,
            'commit_sha': commit_info['commit_sha'],
            'commit_date': commit_info['commit_date'],
            'ingested_at': self._get_current_timestamp(),
        }

        # Write manifest with pretty formatting
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2, sort_keys=True)
            f.write('\n')  # Add trailing newline

    def _update_gitignore(self) -> None:
        """Ensure .gitignore excludes .claude/context/ to prevent accidental commits."""
        gitignore_path = Path('.gitignore')
        context_entry = '.claude/context/'
        manifest_exception = '!.claude/context/manifest.json'

        # Read existing .gitignore
        existing_lines = []
        if gitignore_path.exists():
            with open(gitignore_path) as f:
                existing_lines = [line.rstrip() for line in f]

        # Check if entries already exist
        has_context = context_entry in existing_lines
        has_exception = manifest_exception in existing_lines

        # Add entries if missing
        if not has_context or not has_exception:
            with open(gitignore_path, 'a') as f:
                if not has_context:
                    f.write('\n# Exclude ingested third-party repositories\n')
                    f.write(f'{context_entry}\n')
                if not has_exception:
                    f.write(f'{manifest_exception}\n')
            print('  Updated .gitignore to exclude .claude/context/')

    def _get_current_timestamp(self) -> str:
        """Get current ISO timestamp."""
        return datetime.utcnow().isoformat() + 'Z'


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Ingest third-party repository into Claude context'
    )
    parser.add_argument('repo_url', help='Repository URL to ingest')
    parser.add_argument(
        '--version',
        default='main',
        help='Branch, tag, or commit to checkout (default: main)',
    )
    parser.add_argument(
        '--context-dir',
        type=Path,
        default=Path('.claude/context'),
        help='Context directory (default: .claude/context)',
    )
    parser.add_argument(
        '--filter-config',
        type=Path,
        default=None,
        help='Path to filter configuration (default: filters/ingestion-filters.json)',
    )
    parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help='Show filtered files during ingestion',
    )

    args = parser.parse_args()

    # Setup directories
    context_dir = args.context_dir
    cache_dir = context_dir / '.cache'
    cache_dir.mkdir(parents=True, exist_ok=True)

    # Determine filter config path
    if args.filter_config:
        filter_config = args.filter_config
    else:
        # Try to find the global filter config
        # Check common installation locations
        possible_paths = [
            Path(__file__).parent.parent / 'filters' / 'ingestion-filters.json',
            Path('filters/ingestion-filters.json'),
            Path('/usr/local/share/claude-dotfiles/filters/ingestion-filters.json'),
        ]
        filter_config = None
        for path in possible_paths:
            if path.exists():
                filter_config = path
                break

        if not filter_config:
            print('Error: Could not find filter configuration file', file=sys.stderr)
            print('  Tried: filters/ingestion-filters.json', file=sys.stderr)
            print('  Use --filter-config to specify location', file=sys.stderr)
            return 4

    # Run ingestion
    try:
        ingestion = RepoIngestion(
            repo_url=args.repo_url,
            version=args.version,
            context_dir=context_dir,
            cache_dir=cache_dir,
            filter_config_path=filter_config,
            verbose=args.verbose,
        )
        ingestion.ingest()
        return 0
    except subprocess.CalledProcessError as e:
        # Provide helpful error messages for common git failures
        error_msg = str(e.stderr) if e.stderr else str(e)
        if 'authentication' in error_msg.lower() or 'permission denied' in error_msg.lower():
            print(f'Error: Authentication failed for {args.repo_url}', file=sys.stderr)
            print('  For private repositories, configure git credentials:', file=sys.stderr)
            print('    GitHub: gh auth login', file=sys.stderr)
            print('    Git: git config --global credential.helper cache', file=sys.stderr)
        elif 'not found' in error_msg.lower() or 'does not exist' in error_msg.lower():
            print('Error: Repository or version not found', file=sys.stderr)
            print(f'  Repository: {args.repo_url}', file=sys.stderr)
            print(f'  Version: {args.version}', file=sys.stderr)
        else:
            print(f'Error: Git operation failed: {e}', file=sys.stderr)
        return 1
    except ValueError as e:
        print(f'Error: {e}', file=sys.stderr)
        return 2
    except Exception as e:
        print(f'Error: Unexpected failure: {e}', file=sys.stderr)
        return 3


if __name__ == '__main__':
    sys.exit(main())
