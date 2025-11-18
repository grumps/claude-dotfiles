# Implementation Plan: Notification Hooks for Claude Awaiting Input

<!--
This template uses JSON metadata to define extractable implementation stages.
Each stage can be developed in its own git worktree for parallel development.

To set up worktrees: just plan-setup .claude/plans/2025-11-17-notification-hooks-waiting-for-input-v2.md
See skills/plan-worktree/SKILL.md for details.
-->

```json metadata
{
  "plan_id": "2025-11-17-notification-hooks",
  "created": "2025-11-17",
  "author": "Claude Code",
  "status": "draft",
  "stages": [
    {
      "id": "context-script",
      "name": "Context Detection Script",
      "branch": "feature/notification-hooks-context-script",
      "worktree_path": "../worktrees/notification-hooks/context-script",
      "status": "not-started",
      "depends_on": []
    },
    {
      "id": "linux-setup",
      "name": "Linux Notification Configuration",
      "branch": "feature/notification-hooks-linux-setup",
      "worktree_path": "../worktrees/notification-hooks/linux-setup",
      "status": "not-started",
      "depends_on": ["context-script"]
    },
    {
      "id": "documentation",
      "name": "User Documentation and Examples",
      "branch": "feature/notification-hooks-docs",
      "worktree_path": "../worktrees/notification-hooks/documentation",
      "status": "not-started",
      "depends_on": ["context-script", "linux-setup"]
    },
    {
      "id": "macos-docs",
      "name": "macOS Documentation (Scoped)",
      "branch": "feature/notification-hooks-macos-docs",
      "worktree_path": "../worktrees/notification-hooks/macos-docs",
      "status": "not-started",
      "depends_on": []
    }
  ]
}
```

## Overview

Implement notification hooks that alert users when Claude Code is waiting for input. The solution leverages Claude Code's built-in notification hook system to trigger desktop notifications via platform-specific notification systems (SwayNotificationCenter for Linux, macOS notification center for macOS).

## Requirements

### Functional Requirements
- [ ] Send desktop notification when Claude is waiting for user input
- [ ] Notification includes project context (tmux window/pane name or git repository name)
- [ ] Notification includes sound alert
- [ ] Notifications auto-dismiss (non-persistent)
- [ ] Only trigger for user prompt events (not other notification types)
- [ ] Works on Linux systems with SwayNotificationCenter/notify-send
- [ ] Support tmux environment detection (window/pane name)
- [ ] Fallback to git repository name if tmux not available
- [ ] Scoped support for macOS (documented but not implemented)
- [ ] Notification hook configured through Claude Code settings
- [ ] Documentation for users to set up notifications on their system

### Non-Functional Requirements
- [ ] Security: Hooks run with user credentials, no elevated permissions needed
- [ ] Compatibility: Works with standard freedesktop notification protocol
- [ ] Usability: Simple configuration, clear documentation

## Technical Approach

### Architecture

Claude Code provides a `Notification` hook event that triggers when Claude sends notifications. We'll configure this hook to execute platform-specific shell commands that send desktop notifications.

**Data Flow**:
1. Claude Code generates notification event (e.g., waiting for input)
2. Hook system intercepts notification event
3. Configured shell command executes (notify-send on Linux, osascript on macOS)
4. Desktop notification system displays alert to user

### Technologies
- **Claude Code**: Built-in hook system (Notification event)
- **Linux**:
  - SwayNotificationCenter (notification daemon for Wayland/Sway)
  - notify-send (CLI tool for sending notifications via D-Bus)
  - D-Bus (freedesktop.Notifications protocol)
- **macOS (scoped)**:
  - osascript (AppleScript from command line)
  - macOS notification center

### Design Patterns
- **Event Hook Pattern**: Register callback that executes on notification events
- **Command Pattern**: Execute platform-specific commands via shell
- **Configuration-based**: User controls hook behavior through settings file

### Existing Code to Follow
- Existing git hooks in `hooks/` directory use shell scripts
- Claude Code hook documentation shows JSON configuration format
- Example from docs: `{"type": "command", "command": "notify-send 'Claude Code' 'Awaiting your input'"}`

## Implementation Stages

Each stage below corresponds to a stage definition in the frontmatter and can be extracted to its own worktree.

### Stage 1: Context Detection Script

**Stage ID**: `context-script`
**Branch**: `feature/notification-hooks-context-script`
**Status**: Not Started
**Dependencies**: None

#### What
Create a shell script that detects project context (tmux window/pane name or git repository) to include in notifications.

#### Why
Notifications need to include project information so users know which Claude instance needs attention, especially when running multiple sessions.

#### How

**Architecture**:
Standalone shell script that outputs project context as a string. Can be called from notification hooks via command substitution.

**Implementation Details**:
- Check for `$TMUX` environment variable
- If in tmux, try to get pane title first (`#T`), then window name (`#W`)
- Fall back to git repository name if not in tmux
- Final fallback to "Claude" if neither available
- Return simple string suitable for notification title

**Files to Change**:
- Create: `scripts/get-notification-context.sh`

**Code Example**:
```bash
#!/usr/bin/env bash
# Get project context for notification

get_tmux_context() {
    if [ -n "$TMUX" ]; then
        PANE_TITLE=$(tmux display-message -p '#T' 2>/dev/null)
        WINDOW_NAME=$(tmux display-message -p '#W' 2>/dev/null)

        if [ -n "$PANE_TITLE" ] && [ "$PANE_TITLE" != "$(basename "$SHELL")" ]; then
            echo "$PANE_TITLE"
            return 0
        elif [ -n "$WINDOW_NAME" ]; then
            echo "$WINDOW_NAME"
            return 0
        fi
    fi
    return 1
}

get_git_context() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
        if [ -n "$GIT_ROOT" ]; then
            basename "$GIT_ROOT"
            return 0
        fi
    fi
    return 1
}

# Try tmux first, then git, then fallback
if get_tmux_context; then
    exit 0
elif get_git_context; then
    exit 0
else
    echo "Claude"
    exit 0
fi
```

#### Validation
- [ ] Test in tmux session with named window
- [ ] Test in tmux session with custom pane title
- [ ] Test outside tmux in git repository
- [ ] Test fallback when neither tmux nor git available
- [ ] Verify output format is clean (no extra whitespace/newlines)
- [ ] Test that script works when called from different working directories

#### TODO for Stage 1
- [ ] Create `scripts/get-notification-context.sh` with tmux detection
- [ ] Add git repository detection fallback
- [ ] Add final fallback to "Claude"
- [ ] Make script executable (`chmod +x`)
- [ ] Test in tmux with window name
- [ ] Test in tmux with pane title
- [ ] Test outside tmux in git repo
- [ ] Test fallback behavior (no tmux, no git)
- [ ] Verify script handles missing `tmux` or `git` commands gracefully

---

### Stage 2: Linux Notification Configuration

**Stage ID**: `linux-setup`
**Branch**: `feature/notification-hooks-linux-setup`
**Status**: Not Started
**Dependencies**: context-script

#### What
Create installation script that configures Claude Code notification hooks for Linux systems using notify-send.

#### Why
Users need an easy way to set up notification hooks without manually editing JSON configuration files.

#### How

**Architecture**:
Installation script that:
1. Detects if notify-send is available
2. Builds notification command using context detection script
3. Updates Claude Code settings.json with hook configuration
4. Preserves existing settings

**Implementation Details**:
- Use `command -v notify-send` to detect notification system
- Build command with proper escaping for shell substitution
- Use `jq` or Python to merge JSON configuration safely
- Add hook with matcher for user input events
- Configure notification with: project context in title, message, urgency, icon, expire time
- Add integration option to main `install.sh`

**Files to Change**:
- Create: `scripts/install-notification-hooks.sh`
- Modify: `install.sh` (add optional notification setup step)

**Code Example**:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CONFIG_DIR="${HOME}/.config/claude-code"
SETTINGS_FILE="${CLAUDE_CONFIG_DIR}/settings.json"

# Detect notify-send
if ! command -v notify-send &> /dev/null; then
    echo "❌ notify-send not found"
    echo "Install: sudo apt install libnotify-bin"
    exit 1
fi

echo "✓ Found notify-send"

# Build notification command
CONTEXT_SCRIPT="${SCRIPT_DIR}/get-notification-context.sh"
chmod +x "$CONTEXT_SCRIPT"

NOTIFICATION_CMD="notify-send \"\$(${CONTEXT_SCRIPT})\" 'Claude is waiting for your input' --urgency=normal --icon=dialog-information --expire-time=10000"

# Create config directory
mkdir -p "${CLAUDE_CONFIG_DIR}"

# Add hook configuration (using jq or Python to merge)
# ... JSON merge logic here ...

echo "✓ Notification hooks configured"
```

#### Validation
- [ ] Test on clean Linux system (Ubuntu/Debian)
- [ ] Verify notify-send is detected correctly
- [ ] Test settings.json is updated with valid JSON
- [ ] Verify existing settings are preserved
- [ ] Test notification shows correct project context in tmux
- [ ] Test notification shows git repo name outside tmux
- [ ] Verify notification auto-dismisses after 10 seconds
- [ ] Test sound plays with notification (if system configured)
- [ ] Verify installation script can be run multiple times safely (idempotent)
- [ ] Test integration with main install.sh

#### TODO for Stage 2
- [ ] Create `scripts/install-notification-hooks.sh` skeleton
- [ ] Add notify-send detection
- [ ] Implement JSON merge logic (choose jq or Python approach)
- [ ] Build notification command with context script integration
- [ ] Test command substitution escaping
- [ ] Add hook configuration to settings.json
- [ ] Add matcher for user input events
- [ ] Test on clean Ubuntu system
- [ ] Test notification appears when Claude waits for input
- [ ] Verify project context is displayed correctly
- [ ] Add optional step to main install.sh
- [ ] Test opt-in installation flow

---

### Stage 3: User Documentation and Examples

**Stage ID**: `documentation`
**Branch**: `feature/notification-hooks-docs`
**Status**: Not Started
**Dependencies**: context-script, linux-setup

#### What
Comprehensive user documentation covering setup, configuration, customization, and troubleshooting of notification hooks.

#### Why
Users need clear documentation to understand how to set up and customize notification hooks for their workflow.

#### How

**Architecture**:
Single documentation file with:
- Quick start (automatic installation)
- Manual configuration (for advanced users)
- Customization examples (different sounds, timings, icons)
- Troubleshooting section
- Integration examples

**Implementation Details**:
- Document automatic installation via install script
- Show manual configuration steps for power users
- Provide example configurations for common scenarios
- Document notification customization options
- Add troubleshooting for common issues
- Show how to disable/uninstall hooks

**Files to Change**:
- Create: `docs/notification-hooks.md`
- Modify: `README.md` (add link to notification hooks docs)
- Modify: `CHANGELOG.md` (document new feature)

**Code Example**:
```markdown
# Notification Hooks Setup

## Quick Start (Recommended)

Run the installation script:
```bash
~/.claude-dotfiles/scripts/install-notification-hooks.sh
```

Or during initial setup:
```bash
./install.sh  # Select 'y' when prompted for notifications
```

## Manual Configuration

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
            "command": "notify-send \"$(~/.claude-dotfiles/scripts/get-notification-context.sh)\" 'Claude is waiting for your input' --urgency=normal --icon=dialog-information --expire-time=10000"
          }
        ]
      }
    ]
  }
}
```

## Customization Examples

### Silent Notifications
[Example without sound]

### Custom Sound
[Example with custom sound file]

### Different Timings
[Examples with 5s, 15s, 30s expire times]

## Troubleshooting
[Common issues and solutions]
```

#### Validation
- [ ] Review documentation for clarity and completeness
- [ ] Test all example configurations
- [ ] Verify links work (internal and external)
- [ ] Test quick start instructions on fresh system
- [ ] Verify manual configuration instructions
- [ ] Test customization examples
- [ ] Ensure troubleshooting covers common issues
- [ ] Check that README links to notification docs
- [ ] Verify CHANGELOG entry is accurate

#### TODO for Stage 3
- [ ] Create `docs/notification-hooks.md` skeleton
- [ ] Write quick start section (automatic installation)
- [ ] Document manual configuration steps
- [ ] Add example configurations for common scenarios
- [ ] Document all notify-send options (urgency, icon, expire-time)
- [ ] Create troubleshooting section
- [ ] Add uninstall/disable instructions
- [ ] Update README.md with notification hooks feature
- [ ] Update CHANGELOG.md
- [ ] Test all documentation examples
- [ ] Proofread and polish

---

### Stage 4: macOS Documentation (Scoped)

**Stage ID**: `macos-docs`
**Branch**: `feature/notification-hooks-macos-docs`
**Status**: Not Started
**Dependencies**: None (can be done in parallel)

#### What
Documentation-only support for macOS notification hooks using osascript, clearly marked as scoped/untested.

#### Why
Provide guidance for macOS users while keeping implementation focused on Linux. Document future work needed for full macOS support.

#### How

**Architecture**:
Documentation section in notification hooks guide, plus GitHub issue for future implementation.

**Implementation Details**:
- Add macOS section to notification hooks documentation
- Provide example osascript command for notifications
- Clearly mark as scoped/untested
- Create GitHub issue for future macOS implementation
- Link issue from documentation

**Files to Change**:
- Modify: `docs/notification-hooks.md` (add macOS section)
- Create: GitHub issue for macOS implementation

**Code Example**:
```markdown
## macOS (Scoped - Not Implemented)

macOS users can configure similar notifications using osascript:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "waiting for input|awaiting input",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Awaiting your input\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

**Note**: This configuration is documented but not tested. macOS implementation is planned for future releases. See [issue #X](link) for details.

**Contributions Welcome**: If you're a macOS user and want to help implement full macOS support, please see [CONTRIBUTING.md](../CONTRIBUTING.md).
```

#### Validation
- [ ] Review macOS documentation for accuracy
- [ ] Clearly mark as scoped/untested
- [ ] Verify osascript example syntax is correct (basic validation)
- [ ] Create GitHub issue with detailed requirements
- [ ] Link issue from documentation
- [ ] Add note encouraging community contributions

#### TODO for Stage 4
- [ ] Add macOS section to `docs/notification-hooks.md`
- [ ] Research osascript notification syntax
- [ ] Write example osascript command
- [ ] Add clear disclaimer (scoped, not tested)
- [ ] Create GitHub issue for macOS implementation
- [ ] Define macOS implementation requirements in issue
- [ ] Link issue from documentation
- [ ] Add note about community contributions

---

## Testing Strategy

### Unit Tests
**Coverage Goal**: N/A (primarily shell scripts and configuration)

### Integration Tests
**Scenarios**:
- Installation script detects notify-send correctly
- Settings.json is updated with valid JSON
- Existing settings are preserved during update
- Script fails gracefully if notification system not found
- Context detection works in all scenarios (tmux, git, fallback)

### Manual Testing

**Context Script Testing**:
- [ ] Test in tmux with named window
- [ ] Test in tmux with custom pane title
- [ ] Test outside tmux in git repo
- [ ] Test fallback (no tmux, no git)

**Linux Installation Testing**:
- [ ] Fresh Linux install: Run install-notification-hooks.sh
- [ ] Verify notify-send is detected
- [ ] Check settings.json has correct hook configuration
- [ ] Trigger Claude waiting for input
- [ ] Verify notification appears with correct context
- [ ] Verify notification auto-dismisses after 10 seconds
- [ ] Test with existing Claude Code settings (no overwrite)
- [ ] Test with multiple Claude sessions in different tmux windows

**Documentation Testing**:
- [ ] Follow quick start guide on fresh system
- [ ] Test manual configuration instructions
- [ ] Try all customization examples
- [ ] Verify troubleshooting section is helpful

## Deployment Plan

### Pre-deployment
- [ ] Test on multiple Linux distributions (Ubuntu, Arch, Fedora)
- [ ] Update README.md with notification hooks feature
- [ ] Update CHANGELOG.md
- [ ] Create pull request with all changes

### Release
- [ ] Merge all stage branches to main
- [ ] Tag release with version bump (e.g., v1.1.0)
- [ ] Update documentation on main branch
- [ ] Announce feature in release notes

### Post-release
- [ ] Monitor GitHub issues for notification problems
- [ ] Collect feedback on notification styles
- [ ] Document common troubleshooting scenarios

### Rollback Plan
If issues detected:
1. Users can disable hooks by removing Notification section from settings.json
2. Document rollback instructions in troubleshooting section
3. Fix issues and release patch version

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| notify-send not installed on user system | High | Medium | Installation script detects and provides clear error with install instructions |
| Hook configuration breaks existing settings | Low | High | Script preserves existing settings, uses JSON merge strategy |
| Context detection script fails in edge cases | Medium | Medium | Provide graceful fallback to "Claude" if detection fails |
| Tmux environment variables not available | Low | Low | Fallback to git repository name detection |
| Notifications trigger for wrong events | Medium | High | Use matcher to filter specifically for user input prompts |
| Sound doesn't play on some systems | Medium | Low | Document that sound support varies by notification daemon |
| macOS implementation differs from docs | Medium | Low | Clearly mark macOS as scoped/untested, create follow-up issue |
| SwayNotificationCenter incompatible | Low | Medium | Use standard notify-send which works with all notification daemons |
| Notification blocks Claude execution | Low | High | Use async command execution |
| Multiple Claude sessions cause confusion | Medium | Medium | Project context in notification title helps identify which session |

## Dependencies

### Upstream Dependencies
- [ ] Claude Code notification hook system (already implemented)
- [ ] notify-send available on Linux systems (user installs)
- [ ] D-Bus notification protocol (standard on Linux)

### Downstream Impact
- Users: Will need to opt-in to notification hooks during install
- Documentation: README and CHANGELOG need updates
- Installation: install.sh gains new optional step

## Open Questions

- [ ] Should we create a test command users can run to verify their notification setup?
- [ ] What default notification sound should we use (system default vs custom)?
- [ ] Should we support different notification styles for different tmux sessions/projects?

## Success Criteria

- [ ] Linux users can run install script and get working notifications
- [ ] Documentation clearly explains setup process
- [ ] Script handles missing dependencies gracefully
- [ ] Existing Claude Code settings are preserved
- [ ] macOS approach is documented (even if not implemented)
- [ ] README updated with notification hooks feature

## Overall TODO List

High-level tracking across all stages. Stage-specific TODOs are in each stage section above.

### Pre-Implementation
- [ ] Review and approve plan
- [ ] Clarify open questions
- [ ] Set up worktrees for stages: `./scripts/plan-worktree.sh setup-all .claude/plans/2025-11-17-notification-hooks-waiting-for-input-v2.md`

### Implementation (per stage)
- [ ] Stage 1: Context Detection Script - See Stage 1 TODO above
- [ ] Stage 2: Linux Notification Configuration - See Stage 2 TODO above
- [ ] Stage 3: User Documentation and Examples - See Stage 3 TODO above
- [ ] Stage 4: macOS Documentation (Scoped) - See Stage 4 TODO above

### Integration & Testing
- [ ] Merge context-script branch
- [ ] Merge linux-setup branch (depends on context-script)
- [ ] Merge documentation branch (depends on context-script, linux-setup)
- [ ] Merge macos-docs branch (independent)
- [ ] Run full integration tests
- [ ] Test end-to-end setup on fresh Linux system

### Documentation & Deployment
- [ ] Update README.md
- [ ] Update CHANGELOG.md
- [ ] Create pull request
- [ ] Tag release
- [ ] Announce in release notes

## References

- Claude Code Hooks Guide: https://code.claude.com/docs/en/hooks-guide.md
- Claude Code Hooks Reference: https://code.claude.com/docs/en/hooks.md
- SwayNotificationCenter: https://github.com/ErikReider/SwayNotificationCenter
- freedesktop Notifications Spec: https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html
- notify-send man page: https://manpages.ubuntu.com/manpages/lunar/man1/notify-send.1.html
