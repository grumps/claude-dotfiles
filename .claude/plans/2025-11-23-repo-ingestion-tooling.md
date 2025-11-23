# Implementation Plan: Third-Party Repository Ingestion Tooling

<!--
This template uses JSON metadata to define extractable implementation stages.
Each stage can be developed in its own git worktree for parallel development.

To set up worktrees: just plan-setup .claude/plans/[this-file].md
See skills/plan-worktree/SKILL.md for details.
-->

```json metadata
{
  "plan_id": "2025-11-23-repo-ingestion",
  "created": "2025-11-23",
  "author": "Claude",
  "status": "draft",
  "stages": [
    {
      "id": "stage-1",
      "name": "Core Ingestion Script",
      "branch": "feature/repo-ingestion-stage-1",
      "worktree_path": "../worktrees/repo-ingestion/stage-1",
      "status": "not-started",
      "depends_on": []
    },
    {
      "id": "stage-2",
      "name": "Security Filtering System",
      "branch": "feature/repo-ingestion-stage-2",
      "worktree_path": "../worktrees/repo-ingestion/stage-2",
      "status": "not-started",
      "depends_on": ["stage-1"]
    },
    {
      "id": "stage-3",
      "name": "Context Extraction & Documentation",
      "branch": "feature/repo-ingestion-stage-3",
      "worktree_path": "../worktrees/repo-ingestion/stage-3",
      "status": "not-started",
      "depends_on": ["stage-1"]
    },
    {
      "id": "stage-4",
      "name": "Just Recipes & Slash Command",
      "branch": "feature/repo-ingestion-stage-4",
      "worktree_path": "../worktrees/repo-ingestion/stage-4",
      "status": "not-started",
      "depends_on": ["stage-1", "stage-2", "stage-3"]
    }
  ]
}
```

## Overview

Build tooling to safely ingest third-party repositories (open source or internal) into a project's `.claude/context/` directory, providing Claude with accurate library usage context while filtering out security-sensitive and agent-specific files. The tooling supports specific version selection (branch/tag) and integrates with the existing Just recipe patterns.

## Requirements

### Functional Requirements

- [ ] Clone or fetch third-party repositories to a local context directory
- [ ] Support version specification: branch, tag, or commit SHA
- [ ] Extract relevant documentation and usage examples
- [ ] Generate context summaries for Claude consumption
- [ ] Filter out agent configuration files (.claude/, .cursor/, etc.)
- [ ] Filter out security-sensitive files (.env, credentials, secrets)
- [ ] Support both public and private repositories (with auth)
- [ ] Integrate with existing Just recipe patterns
- [ ] Provide slash command interface for Claude users
- [ ] Support incremental updates (re-ingestion with new version)
- [ ] Track ingested repos in manifest file

### Non-Functional Requirements

- [ ] Security: Never commit sensitive files from third-party repos
- [ ] Security: Validate repository URLs to prevent injection attacks
- [ ] Security: Sanitize repository names to prevent path traversal attacks
- [ ] Security: Filter symlinks that point outside repository
- [ ] Security: Warn on large repositories to prevent resource exhaustion
- [ ] Performance: Use shallow clones to minimize disk usage
- [ ] Performance: Cache repositories to avoid re-downloading
- [ ] Usability: Clear error messages for common failures (auth, network, etc.)
- [ ] Usability: Automatic .gitignore updates to prevent accidental commits
- [ ] Compatibility: Python 3.9+ stdlib only (no external dependencies)
- [ ] Maintainability: Follow existing Python style guide (pyproject.toml standards)

## Technical Approach

### Architecture

The ingestion system consists of:

1. **Core Ingestion Engine** (`scripts/ingest-repo.py`): Python script handling cloning, filtering, and extraction
2. **Global Filter Configuration** (`filters/ingestion-filters.json`): Default pattern-based filtering rules (bundled with claude-dotfiles)
3. **Local Filter Override** (`.claude/ingestion-filters.json`): Per-project customizable filter overrides (created on first use)
4. **Context Directory Structure** (`.claude/context/<repo-name>/`): Standardized layout for ingested repositories
5. **Manifest Tracking** (`.claude/context/manifest.json`): Records all ingested repos, versions, and metadata
6. **Just Recipes** (`justfiles/context.just`): User-friendly interface for ingestion operations
7. **Slash Command** (`commands/ingest-repo.md`): Interactive Claude-driven ingestion

### Technologies

- **Language**: Python 3.9+ (stdlib only: json, subprocess, pathlib, shutil, re, hashlib)
- **Version Control**: Git (subprocess calls for clone, checkout, log)
- **Configuration**: JSON for filter rules and manifest (stdlib json module)
- **Integration**: Just task runner for recipe interface
- **Documentation**: Markdown for generated context summaries

### Design Patterns

- **Builder Pattern**: Construct ingestion requests with fluent API (repo URL, version, filters)
- **Strategy Pattern**: Different extraction strategies based on repo type (library, framework, tool)
- **Template Method**: Standardized ingestion workflow with customizable steps
- **Dependency Injection**: Filter rules loaded from configuration file

### Existing Code to Follow

- `scripts/planworktree.py`: Python stdlib-only script pattern, subprocess usage, JSON parsing
- `scripts/git-linear-history.sh`: Git subprocess interactions, error handling
- `scripts/helm-chart-render.sh`: Interactive user prompts, version selection
- `justfiles/ci.just`: Recipe organization and naming conventions
- `.claude/` directory structure: Existing patterns for plans, prompts, commands
- `docs/python-style-guide.md`: Python coding standards to follow

## Implementation Stages

Each stage below corresponds to a stage definition in the frontmatter and can be extracted to its own worktree.

### Stage 1: Core Ingestion Script

**Stage ID**: `stage-1`
**Branch**: `feature/repo-ingestion-stage-1`
**Status**: Not Started
**Dependencies**: None

#### What

Create the foundational Python script (`scripts/ingest-repo.py`) that can clone a third-party repository, checkout a specific version (branch/tag/commit), and copy files to `.claude/context/` with basic filtering.

#### Why

This provides the core functionality needed for all other stages. Without the ability to safely clone and version-select repositories, the security filtering and context extraction features can't be implemented.

#### How

**Architecture**:
The script acts as a standalone CLI tool that can be invoked directly or via Just recipes. It manages git operations in a temporary workspace and copies filtered results to the final destination.

**Implementation Details**:

- Use `argparse` for CLI argument parsing (repo URL, version, destination)
- Use `subprocess.run()` for git operations with proper error handling
- Use `pathlib.Path` for all file system operations
- Implement shallow clone (`--depth 1`) when possible for performance
- Store clones in `.claude/context/.cache/<repo-hash>/` for reuse
- Support authentication via git credential helper (no custom auth handling)
- Create manifest entry in `.claude/context/manifest.json`
- Validate and sanitize URLs using `urllib.parse` to prevent injection
- Sanitize repository names using regex to prevent path traversal
- Check repository size and warn if >50MB
- Update root `.gitignore` to exclude `.claude/context/` (except manifest.json)
- Provide clear error messages for authentication failures

**Files to Change**:

- Create: `scripts/ingest-repo.py`
- Create: `.claude/context/manifest.json` (if not exists)
- Create: `.claude/context/.gitignore` (to ignore cache and ingested repos)
- Modify: `.gitignore` (add .claude/context/ exclusion)

**Code Example**:

```python
#!/usr/bin/env python3
"""
Ingest third-party repository into Claude context directory.

This script clones a repository, checks out a specific version, and copies
relevant files to .claude/context/ for Claude Code usage.
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional
from urllib.parse import urlparse


class RepoIngestion:
    """Handles ingestion of third-party repositories."""

    def __init__(
        self,
        repo_url: str,
        version: str,
        context_dir: Path,
        cache_dir: Path,
    ) -> None:
        """Initialize repository ingestion."""
        self.repo_url = self._validate_url(repo_url)
        self.version = version
        self.context_dir = context_dir
        self.cache_dir = cache_dir
        self.repo_name = self._extract_and_sanitize_repo_name(repo_url)
        self.repo_hash = hashlib.sha256(repo_url.encode()).hexdigest()[:16]

    def _validate_url(self, url: str) -> str:
        """Validate repository URL to prevent injection attacks."""
        try:
            parsed = urlparse(url)
            # Ensure scheme is http/https/git/ssh
            if parsed.scheme and parsed.scheme not in ('http', 'https', 'git', 'ssh'):
                raise ValueError(f"Invalid URL scheme: {parsed.scheme}")
            return url
        except Exception as e:
            raise ValueError(f"Invalid repository URL: {e}")

    def _extract_and_sanitize_repo_name(self, url: str) -> str:
        """Extract and sanitize repository name from URL."""
        # Handle github.com/org/repo or git@github.com:org/repo
        parts = url.rstrip('/').rstrip('.git').split('/')
        raw_name = parts[-1]

        # Sanitize: allow only alphanumeric, hyphens, underscores
        # Replace any other characters with hyphen
        sanitized = re.sub(r'[^a-zA-Z0-9_-]', '-', raw_name)

        # Prevent path traversal attempts
        if sanitized.startswith('.') or '/' in sanitized or '\\' in sanitized:
            raise ValueError(f"Invalid repository name: {raw_name}")

        return sanitized

    def clone_or_update(self) -> Path:
        """Clone repository to cache or update if exists."""
        clone_path = self.cache_dir / self.repo_hash

        if clone_path.exists():
            print(f"Updating cached repository: {self.repo_name}")
            subprocess.run(
                ["git", "fetch", "--all", "--tags"],
                cwd=clone_path,
                check=True,
            )
        else:
            print(f"Cloning repository: {self.repo_name}")
            subprocess.run(
                ["git", "clone", self.repo_url, str(clone_path)],
                check=True,
            )

        return clone_path

    def checkout_version(self, clone_path: Path) -> None:
        """Checkout specific version (branch, tag, or commit)."""
        print(f"Checking out version: {self.version}")
        subprocess.run(
            ["git", "checkout", self.version],
            cwd=clone_path,
            check=True,
        )

    def get_commit_info(self, clone_path: Path) -> Dict[str, str]:
        """Get commit SHA and date for manifest."""
        result = subprocess.run(
            ["git", "log", "-1", "--format=%H|%ai"],
            cwd=clone_path,
            capture_output=True,
            text=True,
            check=True,
        )
        sha, date = result.stdout.strip().split('|')
        return {"commit_sha": sha, "commit_date": date}

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

        # TODO: Apply filters (Stage 2)
        # TODO: Extract context (Stage 3)

        # Update manifest
        self._update_manifest(commit_info)

        # Ensure .gitignore excludes context directory
        self._update_gitignore()

        print(f"✓ Ingested {self.repo_name} @ {self.version}")
        print(f"  Location: {dest_dir}")
        print(f"  Commit: {commit_info['commit_sha'][:8]}")

    def _check_repo_size(self, clone_path: Path) -> None:
        """Check repository size and warn if large."""
        try:
            result = subprocess.run(
                ["du", "-sm", str(clone_path)],
                capture_output=True,
                text=True,
                check=True,
            )
            size_mb = int(result.stdout.split()[0])
            if size_mb > 50:
                print(f"⚠️  Warning: Repository is large ({size_mb}MB)")
                print(f"   This may consume significant disk space.")

    def _update_manifest(self, commit_info: Dict[str, str]) -> None:
        """Update manifest with ingestion metadata."""
        manifest_path = self.context_dir / "manifest.json"

        # Load existing manifest or create new
        if manifest_path.exists():
            with open(manifest_path) as f:
                manifest = json.load(f)
        else:
            manifest = {"repositories": {}}

        # Add/update repository entry
        manifest["repositories"][self.repo_name] = {
            "url": self.repo_url,
            "version": self.version,
            "commit_sha": commit_info["commit_sha"],
            "commit_date": commit_info["commit_date"],
            "ingested_at": self._get_current_timestamp(),
        }

        # Write manifest with pretty formatting
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2, sort_keys=True)
            f.write('\n')  # Add trailing newline

    def _update_gitignore(self) -> None:
        """Ensure .gitignore excludes .claude/context/ to prevent accidental commits."""
        gitignore_path = Path(".gitignore")
        context_entry = ".claude/context/"
        manifest_exception = "!.claude/context/manifest.json"

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
                    f.write(f"\n# Exclude ingested third-party repositories\n")
                    f.write(f"{context_entry}\n")
                if not has_exception:
                    f.write(f"{manifest_exception}\n")
            print(f"  Updated .gitignore to exclude .claude/context/")

    def _get_current_timestamp(self) -> str:
        """Get current ISO timestamp."""
        return datetime.utcnow().isoformat() + 'Z'


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Ingest third-party repository into Claude context"
    )
    parser.add_argument("repo_url", help="Repository URL to ingest")
    parser.add_argument(
        "--version",
        default="main",
        help="Branch, tag, or commit to checkout (default: main)",
    )
    parser.add_argument(
        "--context-dir",
        type=Path,
        default=Path(".claude/context"),
        help="Context directory (default: .claude/context)",
    )

    args = parser.parse_args()

    # Setup directories
    context_dir = args.context_dir
    cache_dir = context_dir / ".cache"
    cache_dir.mkdir(parents=True, exist_ok=True)

    # Run ingestion
    try:
        ingestion = RepoIngestion(
            repo_url=args.repo_url,
            version=args.version,
            context_dir=context_dir,
            cache_dir=cache_dir,
        )
        ingestion.ingest()
        return 0
    except subprocess.CalledProcessError as e:
        # Provide helpful error messages for common git failures
        error_msg = str(e.stderr) if e.stderr else str(e)
        if "authentication" in error_msg.lower() or "permission denied" in error_msg.lower():
            print(f"Error: Authentication failed for {args.repo_url}", file=sys.stderr)
            print(f"  For private repositories, configure git credentials:", file=sys.stderr)
            print(f"    GitHub: gh auth login", file=sys.stderr)
            print(f"    Git: git config --global credential.helper cache", file=sys.stderr)
        elif "not found" in error_msg.lower() or "does not exist" in error_msg.lower():
            print(f"Error: Repository or version not found", file=sys.stderr)
            print(f"  Repository: {args.repo_url}", file=sys.stderr)
            print(f"  Version: {args.version}", file=sys.stderr)
        else:
            print(f"Error: Git operation failed: {e}", file=sys.stderr)
        return 1
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"Error: Unexpected failure: {e}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    sys.exit(main())
```

#### Validation

- [ ] Run `uv run scripts/ingest-repo.py https://github.com/example/repo --version v1.0.0`
- [ ] Verify repository cloned to `.claude/context/.cache/`
- [ ] Verify manifest created/updated in `.claude/context/manifest.json`
- [ ] Verify `.gitignore` updated with `.claude/context/` exclusion
- [ ] Test with branch name, tag, and commit SHA
- [ ] Test error handling for invalid URLs and versions
- [ ] Test URL validation (reject invalid schemes)
- [ ] Test repository name sanitization (try path traversal)
- [ ] Test size warning for large repositories (>50MB)
- [ ] Test authentication error message for private repo
- [ ] Run mypy and ruff linting: `just lint-python`

#### TODO for Stage 1

- [ ] Create `scripts/ingest-repo.py` with basic structure
- [ ] Implement URL validation to prevent injection (urllib.parse)
- [ ] Implement repository name sanitization (regex, prevent path traversal)
- [ ] Implement git clone with shallow clone optimization
- [ ] Implement git checkout for branch/tag/commit
- [ ] Implement repository size check with warnings (>50MB)
- [ ] Implement commit metadata extraction
- [ ] Create manifest JSON structure and update logic
- [ ] Implement .gitignore update logic (exclude .claude/context/)
- [ ] Add `.claude/context/.gitignore` with cache exclusion
- [ ] Implement detailed error messages for auth failures
- [ ] Write comprehensive docstrings (Google style)
- [ ] Add type hints for all functions
- [ ] Add error handling for network and git failures
- [ ] Test with various repository types (GitHub, GitLab, etc.)
- [ ] Test security features (URL validation, name sanitization)

---

### Stage 2: Security Filtering System

**Stage ID**: `stage-2`
**Branch**: `feature/repo-ingestion-stage-2`
**Status**: Not Started
**Dependencies**: stage-1

#### What

Implement security-conscious filtering to exclude agent configuration files, credentials, symlinks, and other sensitive content from ingested repositories. This uses a declarative JSON configuration with global defaults and per-project overrides.

#### Why

Third-party repositories often contain files that should not be ingested:

- Agent configurations (.claude/, .cursor/, .aider/, etc.) could confuse models
- Credentials (.env, secrets) pose security risks if accidentally committed
- Symlinks pointing outside repo are security risks
- Build artifacts and vendor directories waste space
- Test fixtures and mock data are not useful for understanding library usage

#### How

**Architecture**:
A declarative filter system with two levels:

1. **Global filters** (`filters/ingestion-filters.json` in claude-dotfiles): Default patterns bundled with the tool
2. **Local overrides** (`.claude/ingestion-filters.json` in user project): Per-project customizations

Filters are applied during file copy phase, using glob patterns for matching and supporting allowlist exceptions.

**Implementation Details**:

- Create global filter configuration in `filters/ingestion-filters.json`
- Load global filters first, then merge with local overrides if present
- Support glob patterns (`*.pyc`, `.env*`) for file matching
- Implement allowlist to force-include specific files (README.md, docs/)
- Filter categories: agent-tools, credentials, symlinks, build-artifacts, test-data
- Block symlinks that point outside the repository (security)
- Allow per-repository filter overrides in manifest.json
- Use `fnmatch` for glob matching, `os.path.islink()` for symlink detection
- Log filtered files for transparency (optional `--verbose` flag)
- Integrate filtering into Stage 1's ingestion workflow

**Files to Change**:

- Create: `filters/ingestion-filters.json` (global defaults)
- Modify: `scripts/ingest-repo.py` (add SecurityFilter class and filtering logic)
- Create: `docs/ingestion-filters.md` (documentation)

**Code Example**:

```json
// filters/ingestion-filters.json
// Global default filters for repository ingestion
{
  "version": 1,
  "description": "Security and quality filters for third-party repository ingestion",
  "global_filters": {
    "agent_tools": {
      "enabled": true,
      "description": "Agent and AI tooling configurations",
      "patterns": [
        ".claude/**",
        ".cursor/**",
        ".aider/**",
        ".continue/**",
        ".copilot/**",
        ".github/copilot-instructions.md",
        ".ai/**",
        "**/.ai/**",
        "**/ai-context.md"
      ]
    },
    "credentials": {
      "enabled": true,
      "description": "Credentials and secrets",
      "patterns": [
        ".env",
        ".env.*",
        "**/*.pem",
        "**/*.key",
        "**/*.pfx",
        "**/credentials.json",
        "**/secrets.yaml",
        "**/secrets.json",
        "**/*-secret.yaml",
        "**/token",
        "**/.aws/**",
        "**/.ssh/**",
        "**/.docker/config.json"
      ]
    },
    "symlinks": {
      "enabled": true,
      "description": "Symlinks (security risk if pointing outside repo)",
      "check_symlinks": true
    },
    "build_artifacts": {
      "enabled": true,
      "description": "Build artifacts and dependencies",
      "patterns": [
        "node_modules/**",
        "vendor/**",
        "__pycache__/**",
        "*.pyc",
        ".pytest_cache/**",
        ".mypy_cache/**",
        "dist/**",
        "build/**",
        "*.egg-info/**",
        "target/**",
        ".gradle/**",
        ".terraform/**",
        "*.tfstate",
        "*.tfstate.backup"
      ]
    },
    "test_fixtures": {
      "enabled": true,
      "description": "Test fixtures and mock data (often large, not useful for context)",
      "patterns": [
        "**/fixtures/**/*.json",
        "**/fixtures/**/*.xml",
        "**/fixtures/**/*.csv",
        "**/testdata/**/*.bin",
        "**/mocks/**/*.json"
      ]
    },
    "vcs_and_ide": {
      "enabled": true,
      "description": "Version control and IDE files",
      "patterns": [
        ".git/**",
        ".svn/**",
        ".hg/**",
        ".idea/**",
        ".vscode/**",
        "*.swp",
        "*.swo",
        "*~"
      ]
    },
    "large_binaries": {
      "enabled": true,
      "description": "Large binary files (>1MB)",
      "max_file_size_mb": 1
    }
  },
  "allowlist": [
    "**/README.md",
    "**/USAGE.md",
    "**/EXAMPLES.md",
    "**/docs/**/*.md",
    "**/LICENSE",
    "**/NOTICE"
  ]
}
```

Per-repository overrides can be set in `.claude/ingestion-filters.json`:

```json
// .claude/ingestion-filters.json (optional local overrides)
{
  "version": 1,
  "repository_overrides": {
    "example-repo": {
      "filters": {
        "test_fixtures": {
          "enabled": false
        }
      }
    }
  }
}
```

```python
# Addition to scripts/ingest-repo.py

import os
from typing import Optional


class SecurityFilter:
    """Applies security and quality filters to repository files."""

    def __init__(
        self,
        global_config_path: Path,
        local_config_path: Optional[Path] = None
    ) -> None:
        """Load filter configuration from global and local sources."""
        # Load global filters
        with open(global_config_path) as f:
            self.config = json.load(f)
        self.global_filters = self.config.get("global_filters", {})
        self.allowlist = self.config.get("allowlist", [])

        # Merge local overrides if present
        if local_config_path and local_config_path.exists():
            with open(local_config_path) as f:
                local_config = json.load(f)
                self._merge_overrides(local_config)

    def _merge_overrides(self, local_config: Dict[str, Any]) -> None:
        """Merge local configuration overrides into global filters."""
        repo_overrides = local_config.get("repository_overrides", {})
        for repo_name, overrides in repo_overrides.items():
            filters = overrides.get("filters", {})
            for filter_name, filter_config in filters.items():
                if filter_name in self.global_filters:
                    self.global_filters[filter_name].update(filter_config)

    def should_include_file(self, file_path: Path, repo_root: Path) -> bool:
        """Check if file should be included based on filters."""
        # Block symlinks (security risk)
        if os.path.islink(file_path):
            symlink_config = self.global_filters.get("symlinks", {})
            if symlink_config.get("enabled", True) and symlink_config.get("check_symlinks", True):
                # Check if symlink points outside repository
                try:
                    target = os.readlink(file_path)
                    if os.path.isabs(target) or ".." in target:
                        return False  # Block absolute or parent-directory symlinks
                except Exception:
                    return False  # Block if we can't read the symlink

        relative_path = file_path.relative_to(repo_root)
        relative_str = str(relative_path)

        # Check allowlist first (takes precedence)
        if self._matches_allowlist(relative_str):
            return True

        # Check file size limit
        large_binary_config = self.global_filters.get("large_binaries", {})
        if large_binary_config.get("enabled", True):
            max_size_mb = large_binary_config.get("max_file_size_mb", 1)
            try:
                size_mb = file_path.stat().st_size / (1024 * 1024)
                if size_mb > max_size_mb:
                    return False  # Filter out large files
            except Exception:
                pass  # If we can't stat, allow the file

        # Check each filter category
        for category, config in self.global_filters.items():
            if category in ("symlinks", "large_binaries"):  # Skip special filters
                continue

            if not config.get("enabled", True):
                continue

            patterns = config.get("patterns", [])
            for pattern in patterns:
                if self._matches_pattern(relative_str, pattern):
                    return False  # Filtered out

        return True  # Include by default

    def _matches_allowlist(self, path: str) -> bool:
        """Check if path matches allowlist."""
        import fnmatch
        for pattern in self.allowlist:
            if fnmatch.fnmatch(path, pattern):
                return True
        return False

    def _matches_pattern(self, path: str, pattern: str) -> bool:
        """Check if path matches filter pattern (glob or regex)."""
        import fnmatch
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
    ) -> Dict[str, int]:
        """Copy files from source to dest, applying filters."""
        import shutil

        stats = {"included": 0, "filtered": 0}

        for file_path in source_dir.rglob("*"):
            if file_path.is_file():
                if self.should_include_file(file_path, source_dir):
                    # Calculate destination path
                    rel_path = file_path.relative_to(source_dir)
                    dest_file = dest_dir / rel_path
                    dest_file.parent.mkdir(parents=True, exist_ok=True)

                    # Copy file
                    shutil.copy2(file_path, dest_file)
                    stats["included"] += 1
                else:
                    if verbose:
                        print(f"  Filtered: {file_path.relative_to(source_dir)}")
                    stats["filtered"] += 1

        return stats
```

#### Validation

- [ ] Create test repository with various file types
- [ ] Verify agent files (.claude/, .cursor/) are filtered
- [ ] Verify credentials (.env, *.pem) are filtered
- [ ] Verify symlinks pointing outside repo are filtered
- [ ] Verify large binary files (>1MB) are filtered
- [ ] Verify build artifacts (node_modules/, *.pyc) are filtered
- [ ] Verify allowlist works (README.md included even in filtered dirs)
- [ ] Test with `--verbose` flag to see filtered files
- [ ] Test local filter overrides in `.claude/ingestion-filters.json`
- [ ] Test per-repository overrides in manifest.json
- [ ] Run `just lint-python` for code quality
- [ ] Review filter configuration with security perspective

#### TODO for Stage 2

- [ ] Create `filters/ingestion-filters.json` with comprehensive patterns
- [ ] Add `SecurityFilter` class to `scripts/ingest-repo.py`
- [ ] Implement global + local filter loading and merging
- [ ] Implement glob pattern matching with fnmatch
- [ ] Implement symlink detection and filtering
- [ ] Implement file size checking and filtering
- [ ] Implement allowlist precedence logic
- [ ] Integrate filtering into ingestion workflow
- [ ] Add `--verbose` flag to show filtered files
- [ ] Add statistics reporting (X files included, Y filtered)
- [ ] Document filter categories in `docs/ingestion-filters.md`
- [ ] Document filter override mechanism (global vs local)
- [ ] Test with real-world repositories (numpy, flask, kubernetes-python-client)
- [ ] Add tests for edge cases (symlinks, permissions, large files)
- [ ] Test case-insensitive matching on case-insensitive filesystems

---

### Stage 3: Context Extraction & Documentation

**Stage ID**: `stage-3`
**Branch**: `feature/repo-ingestion-stage-3`
**Status**: Not Started
**Dependencies**: stage-1

#### What

Extract and generate contextual documentation from ingested repositories to help Claude understand library usage patterns. This includes README summarization, API documentation discovery, and example code extraction.

#### Why

Raw repository contents are useful but not optimized for Claude consumption. By extracting key documentation, API surfaces, and usage examples into a structured format, we provide Claude with high-quality context for answering questions about library usage.

#### How

**Architecture**:
A documentation extraction system that analyzes repository structure, identifies key files, and generates a context summary in `.claude/context/<repo-name>/CONTEXT.md`.

**Implementation Details**:

- Identify and prioritize documentation files (README, USAGE, EXAMPLES, docs/)
- Extract package/module structure for libraries (Python: setup.py/pyproject.toml, Go: go.mod, etc.)
- Find and extract code examples from documentation
- Generate CONTEXT.md with standardized sections:
  - Repository Overview
  - Installation Instructions
  - Key APIs/Modules
  - Usage Examples
  - Links to Full Documentation
- Support language-specific extraction strategies
- Use heuristics to identify library vs. application repositories
- Create index of important files for quick reference

**Files to Change**:

- Modify: `scripts/ingest-repo.py` (add context extraction)
- Create: Template for CONTEXT.md structure

**Code Example**:

```python
# Addition to scripts/ingest-repo.py

class ContextExtractor:
    """Extracts contextual information from repository."""

    def __init__(self, repo_path: Path, repo_name: str) -> None:
        """Initialize context extractor."""
        self.repo_path = repo_path
        self.repo_name = repo_name

    def extract_context(self) -> Dict[str, Any]:
        """Extract all contextual information."""
        return {
            "overview": self._extract_overview(),
            "installation": self._extract_installation(),
            "structure": self._detect_structure(),
            "examples": self._extract_examples(),
            "documentation_files": self._find_documentation(),
        }

    def _extract_overview(self) -> str:
        """Extract repository overview from README."""
        readme_paths = [
            "README.md",
            "README.rst",
            "README.txt",
            "readme.md",
        ]

        for readme in readme_paths:
            readme_file = self.repo_path / readme
            if readme_file.exists():
                # Read first 50 lines or up to first example
                with open(readme_file) as f:
                    lines = []
                    for i, line in enumerate(f):
                        if i >= 50:
                            break
                        if "```" in line and i > 10:  # Stop at first code block
                            break
                        lines.append(line)
                    return "".join(lines).strip()

        return f"No README found for {self.repo_name}"

    def _extract_installation(self) -> str:
        """Extract installation instructions."""
        # Look for installation section in README
        readme = self.repo_path / "README.md"
        if readme.exists():
            with open(readme) as f:
                content = f.read()
                # Simple heuristic: find section with "install" in heading
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if line.startswith('#') and 'install' in line.lower():
                        # Extract next 10 lines
                        return '\n'.join(lines[i:i+10])

        # Fallback: detect package type
        if (self.repo_path / "setup.py").exists() or \
           (self.repo_path / "pyproject.toml").exists():
            return f"`pip install {self.repo_name}`"
        elif (self.repo_path / "go.mod").exists():
            return f"`go get <module_path>`"
        elif (self.repo_path / "package.json").exists():
            return f"`npm install {self.repo_name}`"

        return "See README for installation instructions"

    def _detect_structure(self) -> Dict[str, Any]:
        """Detect repository structure (language, type, entry points)."""
        structure = {
            "language": "unknown",
            "type": "unknown",  # library, application, framework
            "entry_points": [],
        }

        # Detect language
        if (self.repo_path / "setup.py").exists() or \
           (self.repo_path / "pyproject.toml").exists():
            structure["language"] = "Python"
            structure["type"] = "library"
        elif (self.repo_path / "go.mod").exists():
            structure["language"] = "Go"
            structure["type"] = "library"
        elif (self.repo_path / "package.json").exists():
            structure["language"] = "JavaScript/TypeScript"
        elif (self.repo_path / "Cargo.toml").exists():
            structure["language"] = "Rust"

        # Find main modules/packages
        # Python: look for src/ or package name dir
        # Go: parse go.mod for module path
        # etc.

        return structure

    def _extract_examples(self) -> list[str]:
        """Extract code examples from documentation."""
        examples = []

        # Look in common locations
        example_paths = [
            "examples/",
            "EXAMPLES.md",
            "docs/examples/",
        ]

        for path in example_paths:
            full_path = self.repo_path / path
            if full_path.exists():
                if full_path.is_dir():
                    # List example files
                    for ex_file in full_path.glob("**/*.py"):
                        examples.append(str(ex_file.relative_to(self.repo_path)))
                else:
                    # Extract code blocks from markdown
                    with open(full_path) as f:
                        content = f.read()
                        # Simple extraction of code blocks
                        in_code_block = False
                        code_block = []
                        for line in content.split('\n'):
                            if line.startswith('```'):
                                if in_code_block:
                                    examples.append('\n'.join(code_block))
                                    code_block = []
                                in_code_block = not in_code_block
                            elif in_code_block:
                                code_block.append(line)

        return examples[:5]  # Limit to first 5 examples

    def _find_documentation(self) -> list[str]:
        """Find key documentation files."""
        doc_files = []

        # Common documentation patterns
        patterns = [
            "README.md",
            "USAGE.md",
            "API.md",
            "docs/**/*.md",
            "CONTRIBUTING.md",
            "LICENSE",
        ]

        for pattern in patterns:
            for file in self.repo_path.glob(pattern):
                if file.is_file():
                    doc_files.append(str(file.relative_to(self.repo_path)))

        return sorted(doc_files)

    def generate_context_md(self, context_data: Dict[str, Any]) -> str:
        """Generate CONTEXT.md content from extracted data."""
        sections = [
            f"# Context: {self.repo_name}",
            "",
            "This file provides contextual information about the repository for Claude Code.",
            "",
            "## Overview",
            "",
            context_data["overview"],
            "",
            "## Repository Structure",
            "",
            f"- **Language**: {context_data['structure']['language']}",
            f"- **Type**: {context_data['structure']['type']}",
            "",
            "## Installation",
            "",
            context_data["installation"],
            "",
            "## Key Documentation Files",
            "",
        ]

        for doc_file in context_data["documentation_files"]:
            sections.append(f"- `{doc_file}`")

        if context_data["examples"]:
            sections.append("")
            sections.append("## Example Usage")
            sections.append("")
            for i, example in enumerate(context_data["examples"], 1):
                if isinstance(example, str) and '\n' in example:
                    sections.append(f"### Example {i}")
                    sections.append("")
                    sections.append("```")
                    sections.append(example)
                    sections.append("```")
                else:
                    sections.append(f"- See: `{example}`")

        sections.append("")
        sections.append("## Full Repository")
        sections.append("")
        sections.append(
            f"Full repository contents are available in this directory. "
            f"Use standard file operations to explore the codebase."
        )

        return "\n".join(sections)
```

#### Validation

- [ ] Ingest a well-documented Python library (e.g., requests, click)
- [ ] Verify CONTEXT.md generated with overview, installation, examples
- [ ] Ingest a Go library (e.g., cobra, viper)
- [ ] Verify structure detection works for different languages
- [ ] Verify documentation files are correctly identified
- [ ] Test with library that has examples/ directory
- [ ] Manual review of generated context quality
- [ ] Run `just lint-python`

#### TODO for Stage 3

- [ ] Add `ContextExtractor` class to `scripts/ingest-repo.py`
- [ ] Implement README parsing and summarization
- [ ] Implement installation instruction extraction
- [ ] Implement language/type detection (Python, Go, JS, Rust)
- [ ] Implement example code extraction
- [ ] Implement documentation file discovery
- [ ] Create CONTEXT.md template and generator
- [ ] Integrate into main ingestion workflow
- [ ] Test with 5+ different repository types
- [ ] Handle edge cases (no README, unusual structure)

---

### Stage 4: Just Recipes & Slash Command

**Stage ID**: `stage-4`
**Branch**: `feature/repo-ingestion-stage-4`
**Status**: Not Started
**Dependencies**: stage-1, stage-2, stage-3

#### What

Create user-friendly interfaces for the ingestion tooling: Just recipes for command-line usage and a slash command for interactive Claude-driven ingestion.

#### Why

While the Python script is functional, integrating with the existing Just recipe ecosystem and providing a Claude slash command makes the tooling discoverable and easy to use, following established patterns in this repository.

#### How

**Architecture**:
Add recipes to a new `justfiles/context.just` file and create `commands/ingest-repo.md` slash command that guides users through interactive ingestion.

**Implementation Details**:

- Create `justfiles/context.just` with recipes:
  - `ingest-repo URL VERSION`: Ingest a repository
  - `list-ingested`: Show all ingested repositories from manifest
  - `update-ingested REPO`: Re-ingest with latest version
  - `remove-ingested REPO`: Remove from context directory
  - `context-info`: Show context directory usage and statistics
- Create `commands/ingest-repo.md` slash command:
  - Prompt for repository URL
  - Prompt for version (with sensible defaults)
  - Run ingestion with progress updates
  - Display summary of ingested content
- Update main justfile to import context.just
- Add documentation in README

**Files to Change**:

- Create: `justfiles/context.just`
- Create: `commands/ingest-repo.md`
- Modify: `justfile` (import context.just)
- Modify: `README.md` (add context management section)

**Code Example**:

```just
# justfiles/context.just
# Third-party repository context management

# Ingest third-party repository into .claude/context/
ingest-repo URL VERSION="main":
    @echo "Ingesting repository: {{URL}} @ {{VERSION}}"
    uv run scripts/ingest-repo.py "{{URL}}" --version "{{VERSION}}"
    @echo "✓ Repository ingested to .claude/context/"

# List all ingested repositories
list-ingested:
    @if [ -f .claude/context/manifest.json ]; then \
        echo "Ingested Repositories:"; \
        echo ""; \
        uv run -s - <<'EOF'
import json
from pathlib import Path
manifest_path = Path(".claude/context/manifest.json")
if manifest_path.exists():
    with open(manifest_path) as f:
        data = json.load(f)
    repos = data.get("repositories", {})
    if repos:
        for name, info in sorted(repos.items()):
            print(f"  {name}")
            print(f"    URL: {info['url']}")
            print(f"    Version: {info['version']}")
            print(f"    Commit: {info['commit_sha'][:8]}")
            print(f"    Ingested: {info['ingested_at']}")
            print()
    else:
        print("  No repositories ingested yet.")
EOF
    else \
        echo "No repositories ingested yet."; \
    fi

# Update ingested repository to latest version
update-ingested REPO VERSION="main":
    @echo "Updating {{REPO}} to {{VERSION}}"
    @uv run -s - <<'EOF'
import json
from pathlib import Path
import sys
manifest_path = Path(".claude/context/manifest.json")
if not manifest_path.exists():
    print("Error: No manifest found", file=sys.stderr)
    sys.exit(1)
with open(manifest_path) as f:
    data = json.load(f)
repos = data.get("repositories", {})
if "{{REPO}}" not in repos:
    print(f"Error: Repository '{{REPO}}' not found in manifest", file=sys.stderr)
    sys.exit(1)
url = repos["{{REPO}}"]["url"]
print(url)
EOF
    just ingest-repo $(just _get-repo-url {{REPO}}) {{VERSION}}

# Helper: Get repository URL from manifest
_get-repo-url REPO:
    @uv run -s - <<'EOF'
import json
from pathlib import Path
import sys
manifest_path = Path(".claude/context/manifest.json")
with open(manifest_path) as f:
    data = json.load(f)
repos = data.get("repositories", {})
if "{{REPO}}" in repos:
    print(repos["{{REPO}}"]["url"])
else:
    sys.exit(1)
EOF

# Remove ingested repository
remove-ingested REPO:
    @echo "Removing {{REPO}} from context..."
    rm -rf .claude/context/{{REPO}}
    @uv run -s - <<'EOF'
import json
from pathlib import Path
manifest_path = Path(".claude/context/manifest.json")
if manifest_path.exists():
    with open(manifest_path) as f:
        data = json.load(f)
    if "{{REPO}}" in data.get("repositories", {}):
        del data["repositories"]["{{REPO}}"]
        with open(manifest_path, 'w') as f:
            json.dump(data, f, indent=2, sort_keys=True)
            f.write('\n')
        print("✓ Removed {{REPO}} from manifest")
    else:
        print("Repository not found in manifest")
EOF

# Show context directory information
context-info:
    @echo "Context Directory Information:"
    @echo ""
    @echo "Location: .claude/context/"
    @if [ -d .claude/context ]; then \
        echo "Size: $$(du -sh .claude/context 2>/dev/null | cut -f1)"; \
        echo "Repositories: $$(find .claude/context -mindepth 1 -maxdepth 1 -type d ! -name '.*' | wc -l)"; \
        echo ""; \
        just list-ingested; \
    else \
        echo "Context directory does not exist yet."; \
    fi
```

```markdown
<!-- commands/ingest-repo.md -->
---
description: Ingest third-party repository into Claude context
---

You are helping the user ingest a third-party repository (open source or internal) into their project's `.claude/context/` directory for Claude Code usage.

## When to Use

- User wants to add a library or framework as context
- User asks "add <repo> to context" or "ingest <repo>"
- User needs documentation for a third-party dependency
- User wants to understand how to use an external library

## Process

### 1. Gather Repository Information

Ask the user for:

- **Repository URL**: Full git URL (e.g., `https://github.com/org/repo` or `git@github.com:org/repo.git`)
- **Version** (optional): Branch name, tag, or commit SHA (default: `main`)

Examples:
- "What repository would you like to ingest?"
- "Which version should I use? (branch/tag/commit, default: main)"

### 2. Validate Repository

Before ingesting:

- Confirm this is a repository the user has legal access to
- Warn if ingesting large repositories (>100MB)
- Explain that security filtering will be applied

### 3. Run Ingestion

Execute the ingestion using the Just recipe:

```bash
just ingest-repo <URL> <VERSION>
```

This will:
- Clone the repository to `.claude/context/.cache/`
- Check out the specified version
- Apply security filters (remove .env, credentials, agent files, symlinks, etc.)
- Extract context documentation
- Generate `.claude/context/<repo-name>/CONTEXT.md`
- Update `.claude/context/manifest.json`

### 4. Report Results

After ingestion completes, show the user:

- Repository name and version ingested
- Location: `.claude/context/<repo-name>/`
- Number of files included
- Summary from CONTEXT.md
- How to use: "You can now ask me questions about using this library"

### 5. Offer Next Steps

Suggest:

- "Would you like me to help you use this library in your code?"
- "Run `just list-ingested` to see all ingested repositories"
- "Run `just context-info` for context directory statistics"

## Security Notes

**IMPORTANT**: The ingestion process automatically filters:

- Agent configuration files (`.claude/`, `.cursor/`, `.aider/`, etc.)
- Credentials (`.env`, `*.pem`, `secrets.json`, `secrets.yaml`, etc.)
- Symlinks pointing outside the repository
- Large binary files (>1MB)
- Build artifacts (`node_modules/`, `__pycache__/`, etc.)
- Version control directories (`.git/`)

Global filters are defined in `filters/ingestion-filters.json` (bundled with claude-dotfiles). Users can add local overrides in `.claude/ingestion-filters.json`.

**Never commit sensitive files** from ingested repositories to your project's git repository. The `.claude/context/.cache/` directory is git-ignored by default.

## Examples

**Example 1: Python library**

```text
User: "Add the click library to my context"
Claude: "I'll ingest the Click library. What version would you like? (default: main)"
User: "Use version 8.1.7"
Claude: [Runs: just ingest-repo <https://github.com/pallets/click> 8.1.7]
Claude: "✓ Ingested click @ 8.1.7
  Location: .claude/context/click/
  Files: 127 included, 89 filtered

  Click is a Python package for creating command line interfaces. See .claude/context/click/CONTEXT.md for usage examples.

  You can now ask me how to use Click in your application!"
```

**Example 2: Go library**

```text
User: "Ingest the cobra CLI library"
Claude: [Runs: just ingest-repo <https://github.com/spf13/cobra> main]
Claude: "✓ Ingested cobra @ main

  Cobra is a Go library for creating powerful CLI applications. I can now help you use it in your Go projects."
```

## Troubleshooting

**Authentication errors**: If the repository is private, ensure git credentials are configured:

```bash
git config --global credential.helper cache
```

**Network errors**: The script will retry git operations. If persistent, check network connectivity.

**Version not found**: Verify the branch/tag exists: `git ls-remote <URL>`

**Disk space**: Check available space with `just context-info`

## Best Practices

- Ingest specific versions/tags rather than `main` for reproducibility
- Review `.claude/context/<repo>/CONTEXT.md` after ingestion
- Periodically update ingested repos: `just update-ingested <repo> <new-version>`
- Remove unused context: `just remove-ingested <repo>`
- Keep ingestion filters up-to-date for security

```text

#### Validation

- [ ] Run `just ingest-repo <https://github.com/pallets/click> 8.1.7`
- [ ] Verify repository ingested successfully
- [ ] Run `just list-ingested` and verify output
- [ ] Run `just context-info` and verify statistics
- [ ] Test slash command: user says "ingest click library"
- [ ] Verify slash command prompts for URL and version
- [ ] Test `just remove-ingested click`
- [ ] Test `just update-ingested click 8.1.8`
- [ ] Verify documentation in README is clear

#### TODO for Stage 4

- [ ] Create `justfiles/context.just` with all recipes
- [ ] Test each Just recipe independently
- [ ] Create `commands/ingest-repo.md` slash command
- [ ] Test slash command interaction flow
- [ ] Add import to main `justfile`
- [ ] Update `README.md` with context management section
- [ ] Add example workflows to `examples/workflows.md`
- [ ] Create `docs/context-management.md` with detailed guide
- [ ] Test integration with existing commands (e.g., /plan references ingested libs)
- [ ] Add shell completions if applicable

---

## Testing Strategy

### Unit Tests

**Coverage Goal**: Core functionality tested (ingestion, filtering, extraction)

**Key Scenarios**:

- URL parsing and validation
- Git operations (clone, checkout, commit info)
- Filter pattern matching (glob, allowlist precedence)
- Manifest creation and updates
- Context extraction for different repository types

**Approach**:

- Use temporary directories for test repositories
- Mock git commands where appropriate for speed
- Test both success and error paths

### Integration Tests

**Scenarios**:

- End-to-end ingestion of real public repositories (requests, click, cobra)
- Test with different git hosting (GitHub, GitLab, Bitbucket)
- Test authentication with private repositories (manual testing)
- Test version selection: branch, tag, commit SHA
- Test re-ingestion and updates
- Test removal and cleanup

### Manual Testing

**Checklist**:

- [ ] Ingest 3+ Python libraries and verify context quality
- [ ] Ingest 3+ Go libraries and verify context quality
- [ ] Test with a large repository (>10k files) for performance
- [ ] Verify security filters work (check no .env or .claude/ ingested)
- [ ] Test error scenarios (invalid URL, non-existent version, network failure)
- [ ] Ask Claude questions about ingested libraries to verify context usefulness
- [ ] Test Just recipes from different working directories
- [ ] Test slash command user experience

## Deployment Plan

### Pre-deployment

- [ ] Run `just validate` (all checks pass)
- [ ] Update `CHANGELOG.md` with new feature
- [ ] Update `README.md` with context management section
- [ ] Create example workflows in `examples/workflows.md`
- [ ] Review security filters comprehensiveness
- [ ] Test on Linux and macOS environments

### Documentation

- [ ] Create `docs/context-management.md` with comprehensive guide
- [ ] Create `docs/ingestion-filters.md` explaining filter system
- [ ] Add troubleshooting section to docs
- [ ] Update `QUICK_REFERENCE.md` with new Just recipes

### Rollout

This feature is additive and non-breaking:

- New files and scripts added
- Existing workflows unaffected
- Users opt-in by running `just ingest-repo`

### Rollback Plan

If issues detected:

1. Users can remove ingested content: `just remove-ingested <repo>`
2. Delete `.claude/context/` directory entirely if needed
3. Feature is isolated and can be reverted without affecting other functionality

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Ingesting malicious repositories | Medium | High | Document security best practices, warn users to only ingest trusted repos, apply strict filtering |
| Credentials accidentally ingested | Low | Critical | Comprehensive filter patterns for credentials, document review process, add .claude/context/ to .gitignore |
| Large repositories consume disk space | Medium | Medium | Implement shallow clones, document cleanup commands, add disk usage warnings |
| Filter rules too aggressive (miss useful files) | Medium | Low | Implement allowlist system, allow per-repo overrides, document filter customization |
| Network failures during git operations | Medium | Low | Implement retry logic, cache clones for reuse, clear error messages |
| Conflicting agent configurations | Low | Low | Filter all agent files, document in CONTEXT.md what was filtered |
| JSON parsing errors in config files | Low | Low | Validate JSON on load, provide clear error messages, include example configs |

## Dependencies

### Upstream Dependencies

- [ ] Git must be installed and accessible in PATH
- [ ] Network access to git hosting services
- [ ] Python 3.9+ with stdlib
- [ ] uv for running Python scripts (already required by repo)

### Downstream Impact

- **Just recipes**: New `context.just` file extends Just interface (non-breaking)
- **Slash commands**: New command available to Claude users (opt-in)
- **Git repository**: `.claude/context/` added to .gitignore (automatic)
- **Disk space**: Users should monitor `.claude/context/` size
- **Documentation**: Ingested context may improve Claude responses about libraries

## Open Questions

- [ ] Should we support ingesting from local file paths (not just remote git repos)?
- [ ] Should we support ingesting specific subdirectories of a repo?
- [ ] Should we generate embeddings/summaries of ingested content for RAG?
- [ ] Should we support automatic dependency ingestion (e.g., ingest all requirements.txt deps)?
- [ ] Should filters be applied at clone time (sparse checkout) or copy time?
- [ ] Should we support compressed archives instead of git clones?

## Success Criteria

- [ ] All tests pass (`just validate`)
- [ ] Documentation complete and reviewed
- [ ] Successfully ingest 10+ diverse repositories (Python, Go, JS, Rust)
- [ ] Security filters block all known credential patterns
- [ ] Generated CONTEXT.md files are helpful for Claude understanding
- [ ] Just recipes work on Linux and macOS
- [ ] Slash command provides good user experience
- [ ] No security vulnerabilities in URL handling or file operations
- [ ] Code follows Python style guide (type hints, docstrings, ruff/mypy clean)

## Overall TODO List

High-level tracking across all stages. Stage-specific TODOs are in each stage section above.

### Pre-Implementation

- [ ] Review and approve plan
- [ ] Clarify open questions
- [ ] Create `filters/` directory in repository
- [ ] Set up worktrees for stages (run `just plan-setup .claude/plans/2025-11-23-repo-ingestion-tooling.md`)

### Implementation (per stage)

- [ ] Stage 1: Core Ingestion Script - See Stage 1 TODO above
- [ ] Stage 2: Security Filtering System - See Stage 2 TODO above
- [ ] Stage 3: Context Extraction & Documentation - See Stage 3 TODO above
- [ ] Stage 4: Just Recipes & Slash Command - See Stage 4 TODO above

### Integration & Testing

- [ ] Merge all stage branches to main feature branch
- [ ] Run full integration tests with real repositories
- [ ] Address any conflicts or integration issues
- [ ] Performance testing with large repositories
- [ ] Security review of filter patterns

### Documentation & Deployment

- [ ] Update README.md with context management section
- [ ] Create docs/context-management.md
- [ ] Create docs/ingestion-filters.md
- [ ] Update CHANGELOG.md
- [ ] Add to examples/workflows.md
- [ ] Create pull request
- [ ] Code review and approval
- [ ] Merge to main

## References

- Existing script pattern: `scripts/planworktree.py`
- Existing Just recipes: `justfiles/ci.just`, `justfiles/plans.just`
- Python style guide: `docs/python-style-guide.md`
- Security best practices: OWASP Top 10, GitHub security advisories
- Similar tools: git-filter-repo, sparse checkout, git-cliff (for patterns)
