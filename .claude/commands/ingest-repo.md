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

**Never commit sensitive files** from ingested repositories to your project's git repository. The `.claude/context/` directory is git-ignored by default (except manifest.json).

## Examples

### Example 1: Python library

```text
User: "Add the click library to my context"
Claude: "I'll ingest the Click library. What version would you like? (default: main)"
User: "Use version 8.1.7"
Claude: [Runs: just ingest-repo https://github.com/pallets/click 8.1.7]
Claude: "✓ Ingested click @ 8.1.7
  Location: .claude/context/click/
  Files: 127 included, 89 filtered

  Click is a Python package for creating command line interfaces. See .claude/context/click/CONTEXT.md for usage examples.

  You can now ask me how to use Click in your application!"
```

### Example 2: Go library

```text
User: "Ingest the cobra CLI library"
Claude: [Runs: just ingest-repo https://github.com/spf13/cobra main]
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
