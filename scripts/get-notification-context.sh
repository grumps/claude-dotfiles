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
