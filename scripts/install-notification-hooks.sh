#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_CONFIG_DIR="${HOME}/.claude"
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
# The $(...) will be evaluated at runtime when the hook executes
# --app-name helps SwayNC identify and style notifications
# --category helps with notification classification
NOTIFICATION_CMD="notify-send --app-name=\"Claude Code\" --category=im.received \"\$(${CONTEXT_SCRIPT})\" \"Claude is waiting for your input\" --urgency=normal --icon=dialog-information --expire-time=10000"

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

# Create the hook configuration using jq to properly escape the command
HOOK_CONFIG=$(jq -n \
  --arg cmd "$NOTIFICATION_CMD" \
  '{
    "hooks": {
      "Notification": [
        {
          "matcher": "waiting for input|awaiting input",
          "hooks": [
            {
              "type": "command",
              "command": $cmd
            }
          ]
        }
      ]
    }
  }')

# Merge with existing settings using jq
# Strategy: upsert Notification hook by matcher, preserve all other hooks
# Example: If existing has Notification[custom] and new has Notification[waiting],
# result will be Notification[custom, waiting]
if ! jq -s '
  .[0] as $existing |
  .[1] as $new |
  # Merge top-level settings
  $existing * $new |
  # Deep merge hooks
  .hooks = (
    ($existing.hooks // {}) as $eh |
    ($new.hooks // {}) as $nh |
    # Process each hook type
    $eh |
    to_entries |
    map(
      .key as $hook_type |
      if ($nh | has($hook_type)) then
        # Hook type exists in new config - merge arrays by matcher
        .value = (
          .value as $existing_hooks |
          $nh[$hook_type] as $new_hooks |
          # Get matchers from new hooks
          ($new_hooks | map(.matcher)) as $new_matchers |
          # Keep existing hooks that dont match new matchers, then add all new hooks
          ($existing_hooks | map(select(.matcher as $m | $new_matchers | index($m) | not))) + $new_hooks
        )
      else
        # Hook type not in new config - keep as is
        .
      end
    ) |
    from_entries |
    # Add hook types that only exist in new config
    . + (
      $nh |
      to_entries |
      map(select(.key as $k | $eh | has($k) | not)) |
      from_entries
    )
  )
' "$SETTINGS_FILE" <(echo "$HOOK_CONFIG") >"${SETTINGS_FILE}.tmp"; then
  echo "❌ Failed to merge settings with notification hooks"
  echo "   Your settings file may have invalid JSON syntax: $SETTINGS_FILE"
  echo "   A backup was created at: $BACKUP_FILE"
  echo "   You can restore it with: cp \"$BACKUP_FILE\" \"$SETTINGS_FILE\""
  exit 1
fi
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
