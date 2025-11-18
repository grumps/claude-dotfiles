#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_CONFIG_DIR="${HOME}/.config/claude-code"
SETTINGS_FILE="${CLAUDE_CONFIG_DIR}/settings.json"

echo "🔔 Installing Claude Code Notification Hooks for Sway/Linux"
echo ""

# Detect notification system (prefer SwayNC for Sway users)
NOTIFICATION_DAEMON="generic"
if command -v swaync-client &>/dev/null || pgrep -x swaync >/dev/null 2>&1; then
  NOTIFICATION_DAEMON="swaync"
  echo "✓ Found SwayNotificationCenter"
elif command -v notify-send &>/dev/null; then
  echo "✓ Found notify-send (generic notification support)"
else
  echo "❌ No notification system found"
  echo ""
  echo "For Sway users, install SwayNotificationCenter:"
  echo "  Arch Linux:    sudo pacman -S sway-notification-center"
  echo "  Or build from: https://github.com/ErikReider/SwayNotificationCenter"
  echo ""
  echo "Alternatively, install libnotify for basic support:"
  echo "  Ubuntu/Debian: sudo apt install libnotify-bin"
  echo "  Arch Linux:    sudo pacman -S libnotify"
  echo "  Fedora:        sudo dnf install libnotify"
  echo ""
  exit 1
fi

# Verify notify-send is available (both SwayNC and generic use it)
if ! command -v notify-send &>/dev/null; then
  echo "❌ notify-send not found"
  echo ""
  echo "Please install libnotify:"
  echo "  Ubuntu/Debian: sudo apt install libnotify-bin"
  echo "  Arch Linux:    sudo pacman -S libnotify"
  echo "  Fedora:        sudo dnf install libnotify"
  echo ""
  exit 1
fi

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "❌ jq not found (required for JSON configuration)"
  echo ""
  echo "Please install jq:"
  echo "  Ubuntu/Debian: sudo apt install jq"
  echo "  Arch Linux:    sudo pacman -S jq"
  echo "  Fedora:        sudo dnf install jq"
  echo ""
  exit 1
fi

echo "✓ Found jq"

# Make context script executable
CONTEXT_SCRIPT="${DOTFILES_ROOT}/scripts/get-notification-context.sh"
if [ ! -f "$CONTEXT_SCRIPT" ]; then
  echo "❌ Context detection script not found at: $CONTEXT_SCRIPT"
  exit 1
fi
chmod +x "$CONTEXT_SCRIPT"
echo "✓ Context detection script ready"

# Build notification command
# Using single quotes around command to prevent expansion during settings.json creation
# The $(...) will be evaluated at runtime when the hook executes
# --app-name helps SwayNC identify and style notifications
# --category helps with notification classification
NOTIFICATION_CMD="notify-send --app-name='Claude Code' --category=im.received \"\$(${CONTEXT_SCRIPT})\" 'Claude is waiting for your input' --urgency=normal --icon=dialog-information --expire-time=10000"

echo ""
echo "Notification command:"
echo "  $NOTIFICATION_CMD"
echo ""

if [ "$NOTIFICATION_DAEMON" = "swaync" ]; then
  echo "💡 SwayNC Tips:"
  echo "   - Configure notification sounds in: ~/.config/swaync/config.json"
  echo "   - Add sound for 'Claude Code' app under 'scripts' section"
  echo "   - Example: add sound alert for category 'im.received'"
  echo "   - See: https://github.com/ErikReider/SwayNotificationCenter#scripting"
  echo ""
fi

# Create config directory if it doesn't exist
mkdir -p "${CLAUDE_CONFIG_DIR}"

# Create or update settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Creating new settings.json..."
  echo '{}' >"$SETTINGS_FILE"
fi

# Backup existing settings
BACKUP_FILE="${SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo "✓ Backed up existing settings to: $BACKUP_FILE"

# Create the hook configuration
HOOK_CONFIG=$(
  cat <<EOF
{
  "hooks": {
  "Notification": [
    {
    "matcher": "waiting for input|awaiting input",
    "hooks": [
      {
      "type": "command",
      "command": "$NOTIFICATION_CMD"
      }
    ]
    }
  ]
  }
}
EOF
)

# Merge with existing settings using jq
# This preserves all existing settings and adds/updates the Notification hook
echo "$HOOK_CONFIG" | jq -s '.[0] * .[1]' "$SETTINGS_FILE" - >"${SETTINGS_FILE}.tmp"
mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

echo "✓ Updated settings.json with notification hooks"
echo ""
echo "Installation complete! 🎉"
echo ""
echo "The notification hook will trigger when Claude is waiting for your input."
echo "The notification will include your project context (tmux window/pane or git repo name)."
echo ""

if [ "$NOTIFICATION_DAEMON" = "swaync" ]; then
  echo "🔊 To add sound alerts in SwayNC:"
  echo "   Edit ~/.config/swaync/config.json and add to 'scripts':"
  echo '   {'
  echo '     "app-name": "Claude Code",'
  echo '     "exec": "mpv /usr/share/sounds/freedesktop/stereo/message.oga"'
  echo '   }'
  echo ""
fi

echo "To test, run Claude Code and trigger a prompt that requires input."
echo ""
echo "To customize or disable notifications, edit:"
echo "  $SETTINGS_FILE"
echo ""
