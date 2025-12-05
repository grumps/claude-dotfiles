# Claude Code Hook Requirements

## The Problem

Claude Code hooks have specific requirements that differ from standard Unix tool conventions:

| Aspect | Standard Tools | Claude Code Hooks |
|--------|---------------|-------------------|
| **Success exit code** | 0 | 0 (allow action) |
| **Failure exit code** | 1 | **2** (block action) |
| **Output stream** | stdout | **stderr** |

### Why This Matters

When you run tools like `just fmt`, `just lint`, or `just test` directly in hooks:

1. **Exit codes don't block**: When formatters/linters/tests fail, they exit with code 1, but Claude Code needs exit code 2 to block the action
2. **Output is invisible**: Tools output to stdout, but Claude Code only shows stderr to the user

**Result**: Hook failures are silent - Claude doesn't block the action or show you what went wrong.

## The Solution: claude-hook-wrapper.sh

We provide a wrapper script that adapts standard tools to Claude's requirements:

```bash
#!/usr/bin/env bash
# Wrapper for Claude Code hooks
# - Redirects all output to stderr (for visibility)
# - Transforms exit code 1 → 2 (to block actions)
# - Passes exit code 0 through (allows actions)
```

### Usage in Hooks

**Before (broken)**:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "just fmt lint test"
      }]
    }]
  }
}
```

**After (working)**:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "/path/to/claude-dotfiles/scripts/claude-hook-wrapper.sh just fmt lint test"
      }]
    }]
  }
}
```

### Automatic Installation

The `install.sh` script automatically configures hooks with the wrapper:

```bash
# Local install
./install.sh

# Global install
./install.sh --global
```

Both will set up hooks with the correct path to `claude-hook-wrapper.sh`.

## How the Wrapper Works

```bash
# 1. Run the command and capture all output
output=$("$@" 2>&1)
exit_code=$?

# 2. Redirect output to stderr (so Claude sees it)
echo "$output" >&2

# 3. Transform exit codes for Claude
if [ $exit_code -eq 0 ]; then
  exit 0  # Success: allow action
else
  exit 2  # Failure: block action
fi
```

## Testing the Wrapper

```bash
# Test success case (should exit 0)
./scripts/claude-hook-wrapper.sh echo "test"
echo "Exit: $?"  # Should show: Exit: 0

# Test failure case (should exit 2, output on stderr)
./scripts/claude-hook-wrapper.sh false
echo "Exit: $?"  # Should show: Exit: 2

# Test with just commands
./scripts/claude-hook-wrapper.sh just fmt
# - Shows output on stderr (visible in Claude)
# - Exits 2 if formatting fails (blocks the action)
# - Exits 0 if formatting succeeds (allows the action)
```

## Tools That Need Wrapping

Any tool you use in Claude Code hooks should be wrapped:

- **Formatters**: `prettier`, `black`, `gofmt`, `rustfmt`, `shfmt`, etc.
- **Linters**: `eslint`, `ruff`, `golangci-lint`, `shellcheck`, etc.
- **Test runners**: `pytest`, `go test`, `jest`, `cargo test`, etc.
- **Just recipes**: Any `just` command that might fail

## Direct Tool Calls (No Wrapper Needed)

Some operations don't need the wrapper because they're informational only:

```json
{
  "hooks": {
    "Notification": [{
      "hooks": [{
        "type": "command",
        "command": "notify-send 'Claude' 'Action completed'"
      }]
    }]
  }
}
```

Notification hooks don't need to block actions or show output, so they can call tools directly.

## Troubleshooting

### Hook isn't blocking on failures

**Symptom**: Tests fail but Claude doesn't block the action

**Cause**: Hook command is calling the tool directly (without wrapper)

**Fix**: Update your settings.json to use the wrapper:

```bash
# Find your settings file
cat ~/.claude/settings.json  # Global
cat .claude/settings.json    # Local

# Update the command to use the wrapper
```

### Can't see hook output

**Symptom**: Hook runs but you don't see any output

**Cause**: Tool is outputting to stdout instead of stderr

**Fix**: Use the wrapper - it redirects stdout → stderr

### Wrapper not found

**Symptom**: `no such file or directory: /path/to/claude-hook-wrapper.sh`

**Cause**: The path in settings.json doesn't match where the dotfiles are installed

**Fix**: Update settings.json with the correct path, or re-run install.sh

## Reference

- Claude Code hooks documentation: (coming soon)
- Exit code conventions: `man sysexits`
- Standard streams: `man stdout`
