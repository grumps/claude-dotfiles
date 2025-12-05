#!/usr/bin/env bash
# Wrapper for Claude Code hooks
# Adapts standard tool exit codes and output streams to Claude's requirements:
#   - Exit 2 (instead of 1) to block actions when tools fail
#   - Output to stderr (instead of stdout) for visibility in Claude

set -o pipefail

# Color codes for stderr output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
  echo -e "${2:-}${1}${NC}" >&2
}

# Validate that a command was provided
if [ $# -eq 0 ]; then
  log "✗ Error: No command provided" "${RED}"
  exit 1
fi

# Check if the command exists
command_name="$1"
if ! command -v "$command_name" >/dev/null 2>&1; then
  log "✗ Error: Command '$command_name' not found" "${RED}"
  exit 1
fi

# Run the command and capture both stdout and stderr
# Redirect all output to stderr for Claude to see
log "Running: $*" "${YELLOW}"

# Execute command, capturing output and exit code
output=$("$@" 2>&1)
exit_code=$?

# Always show output on stderr so Claude can see it
if [ -n "$output" ]; then
  echo "$output" >&2
fi

# Transform exit codes for Claude:
# - 0 (success) -> 0 (allow action to proceed)
# - non-zero (failure) -> 2 (block action in Claude)
if [ $exit_code -eq 0 ]; then
  log "✓ Success" "${GREEN}"
  exit 0
else
  log "✗ Failed with exit code $exit_code" "${RED}"
  # Exit 2 tells Claude to block the action
  exit 2
fi
