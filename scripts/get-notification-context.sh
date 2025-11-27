#!/usr/bin/env bash
# Get project context for notification

log() {
  logger --tag claude-notify-context "${0}"
}

get_git_context() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    # Get the remote URL and extract the repo name
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)
    if [ -n "$REMOTE_URL" ]; then
      # Extract repo name from URL (remove .git suffix and get last path component)
      REPO_NAME=$(echo "$REMOTE_URL" | sed 's/\.git$//' | awk -F'/' '{print $NF}')
    else
      # Fallback to local directory name if no remote
      GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
      REPO_NAME=$(basename "$GIT_ROOT")
    fi

    # Get current branch name
    BRANCH=$(git branch --show-current 2>/dev/null)

    if [ -n "$REPO_NAME" ] && [ -n "$BRANCH" ]; then
      echo "${REPO_NAME}:${BRANCH}"
      return 0
    elif [ -n "$REPO_NAME" ]; then
      echo "$REPO_NAME"
      return 0
    fi
  fi
  return 1
}

if ! get_git_context; then
  log "failed to get project context"
  echo "Claude: Unkown Project"
fi
