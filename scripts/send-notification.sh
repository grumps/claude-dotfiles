#!/usr/bin/bash

set -o errexit
set -o pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  logger --tag claude-notify "${0}"
}

log "starting claude notification"

claude_context="$("${SCRIPT_DIR}/get-notification-context.sh")"
claude_context_exit=$?

if [ $claude_context_exit -ne 0 ]; then
  log "get-notification-context.sh failed to get context"
fi

if ! notify-send --app-name="Claude Code" \
  --category=im.received \
  "${claude_context}" \
  "Claude is waiting for your input" \
  --urgency=normal \
  --icon=dialog-information \
  --expire-time=30000; then
  log "notify-send message failed to send for ${claude_context}"
fi
