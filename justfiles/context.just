# Third-party repository context management

# Ingest third-party repository into .claude/context/
ingest-repo URL VERSION="main":
    @echo "Ingesting repository: {{URL}} @ {{VERSION}}"
    uv run scripts/ingest-repo.py "{{URL}}" --version "{{VERSION}}"
    @echo "✓ Repository ingested to .claude/context/"

# Ingest repository with verbose output showing filtered files
ingest-repo-verbose URL VERSION="main":
    @echo "Ingesting repository: {{URL}} @ {{VERSION}} (verbose mode)"
    uv run scripts/ingest-repo.py "{{URL}}" --version "{{VERSION}}" --verbose
    @echo "✓ Repository ingested to .claude/context/"

# List all ingested repositories
list-ingested:
    @echo "Ingested Repositories:"
    @echo ""
    @uv run scripts/list-ingested-repos.py

# Update ingested repository to latest version
update-ingested REPO VERSION="main":
    @echo "Updating {{REPO}} to {{VERSION}}"
    @URL=$(just _get-repo-url {{REPO}}) && \
        just ingest-repo "$$URL" {{VERSION}}

# Helper: Get repository URL from manifest
_get-repo-url REPO:
    @uv run scripts/get-repo-url.py "{{REPO}}"

# Remove ingested repository
remove-ingested REPO:
    @echo "Removing {{REPO}} from context..."
    rm -rf .claude/context/{{REPO}}
    @uv run scripts/remove-ingested-repo.py "{{REPO}}"

# Show context directory information
context-info:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Context Directory Information:"
    echo ""
    echo "Location: .claude/context/"
    if [ -d .claude/context ]; then
        echo "Size: $(du -sh .claude/context 2>/dev/null | cut -f1)"
        echo "Repositories: $(find .claude/context -mindepth 1 -maxdepth 1 -type d ! -name '.*' | wc -l)"
        echo ""
        just list-ingested
    else
        echo "Context directory does not exist yet."
    fi
