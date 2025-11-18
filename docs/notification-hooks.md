# Notification Hooks for Claude Code

Get desktop notifications when Claude Code is waiting for your input. Never miss a prompt again!

## Quick Start

### Linux (Automatic Installation)

Run the installation script:

```bash
~/.claude-dotfiles/scripts/install-notification-hooks.sh
```

Or during initial setup:

```bash
./install.sh  # Select 'y' when prompted for notifications
```

### macOS (Manual Configuration - Scoped)

> **Note**: macOS support is documented but not yet fully implemented or tested. This configuration is provided as a starting point. See [issue #TBD](link-to-issue) for full macOS implementation tracking.

Add to `~/.config/claude-code/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "waiting for input|awaiting input",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude is waiting for your input\" with title \"'\"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\"'\" sound name \"Purr\"'"
          }
        ]
      }
    ]
  }
}
```

**Contributions Welcome**: If you're a macOS user and want to help test and improve macOS support, please see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Manual Configuration (Linux)

For power users who want to customize their notification setup, add to `~/.config/claude-code/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "waiting for input|awaiting input",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send \"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\" 'Claude is waiting for your input' --urgency=normal --icon=dialog-information --expire-time=10000"
          }
        ]
      }
    ]
  }
}
```

## How It Works

### Context Detection

Notifications automatically include project context to help you identify which Claude session needs attention:

- **In tmux**: Shows pane title or window name
- **In git repository**: Shows repository name
- **Fallback**: Shows "Claude"

This is especially useful when running multiple Claude sessions across different projects.

### The Hook System

Claude Code's built-in hook system triggers when specific events occur. The `Notification` hook fires when Claude displays notifications. We filter for "waiting for input" events using a matcher pattern and execute a platform-specific notification command.

**Data Flow**:
1. Claude Code generates a notification event (e.g., "awaiting input")
2. Hook system checks matcher pattern
3. If matched, executes configured shell command
4. Desktop notification system displays alert

## Platform-Specific Details

### Linux (SwayNotificationCenter / notify-send)

**Prerequisites**:
- `notify-send` command (usually from `libnotify-bin` package)
- A notification daemon (e.g., SwayNotificationCenter, dunst, mako)

**Installation**:
```bash
# Debian/Ubuntu
sudo apt install libnotify-bin

# Arch Linux
sudo pacman -S libnotify

# Fedora
sudo dnf install libnotify
```

**Test your setup**:
```bash
notify-send "Test" "Notification system working!"
```

### macOS (osascript)

**Prerequisites**:
- `osascript` (built into macOS)
- macOS notification center enabled

**Test your setup**:
```bash
osascript -e 'display notification "Test notification" with title "Claude Code"'
```

**Known Limitations** (documented but not tested):
- Cannot customize notification icon via osascript
- Sound names must match system sounds (e.g., "Purr", "Ping", "Pop")
- Notifications appear in macOS Notification Center

## Customization Examples

### Silent Notifications (Linux)

Remove sound by omitting urgency or setting to low:

```json
{
  "type": "command",
  "command": "notify-send \"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\" 'Claude is waiting for your input' --urgency=low --icon=dialog-information --expire-time=10000"
}
```

### Silent Notifications (macOS)

Remove the `sound name` parameter:

```json
{
  "type": "command",
  "command": "osascript -e 'display notification \"Claude is waiting for your input\" with title \"'\"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\"'\"'"
}
```

### Different Notification Timings (Linux)

Adjust `--expire-time` (in milliseconds):

**5 seconds**:
```bash
notify-send "..." "..." --expire-time=5000
```

**15 seconds**:
```bash
notify-send "..." "..." --expire-time=15000
```

**30 seconds**:
```bash
notify-send "..." "..." --expire-time=30000
```

**Persistent** (until clicked):
```bash
notify-send "..." "..." --expire-time=0
```

### Custom Sound (macOS)

Choose from system sounds:

```bash
# List available sounds
ls /System/Library/Sounds/

# Common options: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink
osascript -e 'display notification "..." with title "..." sound name "Hero"'
```

### Different Icons (Linux)

Use any icon from your system:

```bash
# Using icon names
notify-send "..." "..." --icon=emblem-important

# Using icon paths
notify-send "..." "..." --icon=/path/to/icon.png

# Common icons: dialog-information, dialog-warning, dialog-error, emblem-important
```

### Critical Urgency (Linux)

For important prompts you don't want to miss:

```json
{
  "type": "command",
  "command": "notify-send \"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\" 'Claude is waiting for your input' --urgency=critical --icon=emblem-important --expire-time=0"
}
```

### With Subtitle (macOS)

Add more context with a subtitle:

```json
{
  "type": "command",
  "command": "osascript -e 'display notification \"Awaiting your input\" with title \"'\"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\"'\" subtitle \"Claude Code\" sound name \"Purr\"'"
}
```

## Troubleshooting

### Linux: Notifications Not Appearing

**Check if notify-send is installed**:
```bash
command -v notify-send
```

If not found, install:
```bash
# Debian/Ubuntu
sudo apt install libnotify-bin

# Arch
sudo pacman -S libnotify

# Fedora
sudo dnf install libnotify
```

**Check if notification daemon is running**:
```bash
# For SwayNotificationCenter
pgrep -a swaync

# For dunst
pgrep -a dunst

# For mako
pgrep -a mako
```

**Test notification manually**:
```bash
notify-send "Test" "This is a test notification"
```

**Check Claude Code settings**:
```bash
cat ~/.config/claude-code/settings.json
```

Ensure the `hooks.Notification` section exists and has correct JSON syntax.

### Linux: No Sound

**Check notification daemon settings**:
- SwayNotificationCenter: Check `~/.config/swaync/config.json` for sound settings
- dunst: Check `~/.config/dunst/dunstrc` for sound settings
- Some notification daemons require explicit sound configuration

**Test with explicit sound** (if supported by your daemon):
```bash
notify-send "Test" "Test" --hint=string:sound-name:message-new-instant
```

### macOS: Notifications Not Appearing

**Check notification permissions**:
1. Open System Settings > Notifications
2. Find Terminal (or your terminal app)
3. Ensure "Allow Notifications" is enabled

**Test osascript directly**:
```bash
osascript -e 'display notification "Test" with title "Test"'
```

**Check if Do Not Disturb is enabled**:
Notifications may be silenced if Do Not Disturb is active.

### macOS: Wrong Sound or No Sound

**Check available sounds**:
```bash
ls /System/Library/Sounds/
```

**Test with different sound**:
```bash
osascript -e 'display notification "Test" with title "Test" sound name "Ping"'
```

**Sound name must match exactly** (case-sensitive, without extension).

### Context Script Not Working

**Test context script directly**:
```bash
~/.claude-dotfiles/scripts/get-notification-context.sh
```

Should output your current context (tmux window, git repo name, or "Claude").

**Make sure script is executable**:
```bash
chmod +x ~/.claude-dotfiles/scripts/get-notification-context.sh
```

**Test in different environments**:
```bash
# In tmux
tmux
~/.claude-dotfiles/scripts/get-notification-context.sh

# In git repo
cd ~/some-git-repo
~/.claude-dotfiles/scripts/get-notification-context.sh

# Outside both
cd /tmp
~/.claude-dotfiles/scripts/get-notification-context.sh
```

### Command Substitution Issues

If `$(...)` substitution isn't working, check your shell and quoting:

**For bash/zsh**, the command in settings.json should work as-is.

**For fish or other shells**, you may need to adjust the command substitution syntax.

### Settings Not Taking Effect

**Restart Claude Code** after modifying settings.json.

**Validate JSON syntax**:
```bash
python3 -m json.tool ~/.config/claude-code/settings.json
```

If JSON is invalid, you'll see a helpful error message.

## Advanced Configuration

### Multiple Notification Types

You can configure different notifications for different events:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "waiting for input|awaiting input",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send \"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\" 'Claude is waiting for your input' --urgency=normal --icon=dialog-information --expire-time=10000"
          }
        ]
      },
      {
        "matcher": "error|failed",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Error' 'Something went wrong' --urgency=critical --icon=dialog-error"
          }
        ]
      }
    ]
  }
}
```

### Project-Specific Notifications

Use environment variables or scripts to customize notifications per project:

```bash
# In your project's .envrc (if using direnv)
export CLAUDE_NOTIFICATION_ICON=/path/to/project/icon.png
```

Then in settings.json:
```json
{
  "command": "notify-send \"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\" 'Claude is waiting' --icon=${CLAUDE_NOTIFICATION_ICON:-dialog-information}"
}
```

### Logging Notifications

Track when notifications are sent:

```json
{
  "type": "command",
  "command": "notify-send \"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\" 'Claude is waiting' && echo \"[$(date)] Notification sent\" >> ~/.claude-notifications.log"
}
```

## Disabling Notifications

### Temporary Disable

**Linux**:
Most notification daemons have a "Do Not Disturb" mode. Check your daemon's documentation.

**macOS**:
Enable Do Not Disturb in Control Center.

### Permanent Disable

Remove the `Notification` section from `~/.config/claude-code/settings.json`:

```json
{
  "hooks": {
    // Remove this entire Notification section
  }
}
```

Or comment it out if your JSON parser supports comments (most don't):

```jsonc
{
  "hooks": {
    // "Notification": [ ... ]
  }
}
```

### Conditional Disable

Use environment variables to conditionally enable notifications:

```json
{
  "type": "command",
  "command": "[ -n \"$CLAUDE_NOTIFICATIONS\" ] && notify-send '...' '...'"
}
```

Then:
```bash
# Enable
export CLAUDE_NOTIFICATIONS=1

# Disable
unset CLAUDE_NOTIFICATIONS
```

## Security Considerations

### Command Injection

The notification hooks execute shell commands. Be cautious with:
- User input in notification text
- Environment variables
- Dynamic command construction

The provided scripts use safe patterns:
- Context detection script has no user input
- Commands use proper quoting
- No `eval` or dangerous constructs

### Permissions

Notification hooks run with your user privileges. They:
- Cannot access system-level resources without your permissions
- Cannot run with elevated privileges (no sudo)
- Respect your shell environment and restrictions

## FAQ

**Q: Can I use this with Wayland?**
A: Yes! `notify-send` works with both X11 and Wayland. Make sure you have a compatible notification daemon (e.g., SwayNotificationCenter for Sway, mako for other Wayland compositors).

**Q: Do I need tmux for this to work?**
A: No. Tmux support is optional. The context detection falls back to git repository name or "Claude" if tmux isn't available.

**Q: Can I customize the notification appearance?**
A: Yes, but the level of customization depends on your notification daemon. Check your daemon's documentation for supported features (custom CSS, layouts, etc.).

**Q: Will this work in SSH sessions?**
A: For local notifications, no. You'd need to forward notifications over SSH or use a different approach (e.g., webhook to a notification service).

**Q: Can I integrate this with mobile notifications?**
A: Not directly, but you could modify the hook command to call a service like Pushover, ntfy.sh, or similar that sends mobile notifications.

**Q: Does this slow down Claude Code?**
A: No. Hooks run asynchronously and don't block Claude Code's execution.

## Related Documentation

- [Claude Code Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide)
- [Claude Code Hooks Reference](https://docs.claude.com/en/docs/claude-code/hooks)
- [freedesktop Notifications Spec](https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html)
- [notify-send man page](https://manpages.ubuntu.com/manpages/lunar/man1/notify-send.1.html)
- [SwayNotificationCenter](https://github.com/ErikReider/SwayNotificationCenter)

## Contributing

Found a bug? Have a suggestion? Contributions are welcome!

- **Linux users**: Help improve Linux documentation and test on different distros
- **macOS users**: Help implement and test full macOS support (see issue #TBD)
- **Windows users**: Help add Windows notification support

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

This notification hooks configuration is part of claude-dotfiles and follows the same license. See [LICENSE](../LICENSE) for details.
