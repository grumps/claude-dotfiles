# GitHub PR Feedback System

```json metadata
{
  "plan_id": "2025-11-23-github-pr-feedback-system",
  "status": "draft",
  "stages": [
    {
      "id": "stage-1",
      "name": "Core PR Comment Fetcher",
      "branch": "feature/pr-feedback-stage-1",
      "worktree_path": "../worktrees/pr-feedback/stage-1",
      "status": "not-started",
      "depends_on": []
    },
    {
      "id": "stage-2",
      "name": "Comment Response Engine",
      "branch": "feature/pr-feedback-stage-2",
      "worktree_path": "../worktrees/pr-feedback/stage-2",
      "status": "not-started",
      "depends_on": ["stage-1"]
    },
    {
      "id": "stage-3",
      "name": "Conversation State Tracker",
      "branch": "feature/pr-feedback-stage-3",
      "worktree_path": "../worktrees/pr-feedback/stage-3",
      "status": "not-started",
      "depends_on": ["stage-1"]
    },
    {
      "id": "stage-4",
      "name": "Just Recipe Integration",
      "branch": "feature/pr-feedback-stage-4",
      "worktree_path": "../worktrees/pr-feedback/stage-4",
      "status": "not-started",
      "depends_on": ["stage-1", "stage-2", "stage-3"]
    },
    {
      "id": "stage-5",
      "name": "Claude Command Interface",
      "branch": "feature/pr-feedback-stage-5",
      "worktree_path": "../worktrees/pr-feedback/stage-5",
      "status": "not-started",
      "depends_on": ["stage-4"]
    }
  ]
}
```

## Overview

Build a GitHub PR feedback system that allows Claude Code to intelligently gather, track, and respond to PR review comments. The system uses the GitHub API via `gh` CLI to fetch comments, maintains conversation state to avoid duplicate responses, and only responds to comments that need clarification or express disagreement.

## Requirements

### Functional Requirements

- **F1**: Fetch all review comments from a GitHub PR
- **F2**: Track comment metadata (file, line, code context, reviewer, timestamp)
- **F3**: Maintain conversation state to identify which comments have been addressed
- **F4**: Filter comments to only show those needing response (disagreements, clarifications)
- **F5**: Post responses back to specific comment threads
- **F6**: Integrate with Just recipes for CLI workflows
- **F7**: Provide Claude slash command for interactive PR feedback sessions

### Non-Functional Requirements

- **NF1**: Use `gh` CLI for all GitHub API interactions (consistency with existing release automation)
- **NF2**: Follow Python style guide (type hints, docstrings, functions over classes)
- **NF3**: Store conversation state locally (JSON file in `.claude/pr-state/`)
- **NF4**: Exit codes follow CI/CD contract (0 = success, non-zero = failure)
- **NF5**: Support both PR numbers and PR URLs as input
- **NF6**: Work in any CI environment (GitHub Actions, local, future Argo)

## Technical Approach

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code                              │
│                  /pr-feedback command                        │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│              Just Recipe Layer                              │
│   pr-fetch, pr-respond, pr-status, pr-sync                  │
└───────┬───────────────────────────────┬─────────────────────┘
        │                               │
        ▼                               ▼
┌──────────────────┐          ┌──────────────────────┐
│  Python Scripts  │          │  State Manager       │
│  gh-pr-fetch.py  │◄────────►│  .claude/pr-state/   │
│  gh-pr-respond.py│          │  {pr-number}.json    │
└────────┬─────────┘          └──────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│                    GitHub API (via gh CLI)                   │
│  gh pr view, gh api, gh pr comment                           │
└──────────────────────────────────────────────────────────────┘
```

### Technologies

- **Python 3.9+**: Core scripting language (stdlib only, no external deps)
- **gh CLI**: GitHub API interactions
- **Just**: Task orchestration
- **JSON**: State persistence format

### Patterns

- **Command Pattern**: Each Just recipe is a discrete operation
- **Repository Pattern**: State manager abstracts comment storage
- **Strategy Pattern**: Different response strategies (disagree, clarify, acknowledge)

## Implementation Stages

### Stage 1: Core PR Comment Fetcher

**Stage ID**: `stage-1`
**Branch**: `feature/pr-feedback-stage-1`
**Status**: Not Started
**Dependencies**: None

#### What

Build a Python script that fetches all review comments from a GitHub PR using `gh` CLI, parses them, and outputs structured JSON with comment metadata, file context, and code snippets.

#### Why

This is the foundation - we need to reliably fetch and structure PR comments before we can analyze or respond to them. Using `gh` CLI ensures consistency with existing tooling and works in any environment.

#### How

**Architecture**: Standalone Python script that wraps `gh` CLI commands

**Implementation Details**:
- Use `gh pr view <number> --json reviews,comments` for review comments
- Use `gh api` for additional comment thread details
- Parse diff context to identify code being discussed
- Output JSON with schema:
  ```json
  {
    "pr_number": 123,
    "pr_url": "https://github.com/org/repo/pull/123",
    "comments": [
      {
        "id": "comment-123",
        "author": "reviewer-name",
        "created_at": "2025-11-23T10:00:00Z",
        "body": "Comment text",
        "path": "src/main.py",
        "line": 42,
        "code_snippet": "def foo():",
        "thread_id": "thread-456",
        "is_resolved": false,
        "reply_count": 2
      }
    ]
  }
  ```

**Files to Create**:
- `scripts/gh-pr-fetch.py` - Main fetcher script
- `scripts/lib/gh_api.py` - gh CLI wrapper functions
- `scripts/lib/pr_parser.py` - Comment parsing logic

**Code Example**:
```python
def fetch_pr_comments(pr_identifier: str) -> dict[str, Any]:
    """Fetch all review comments from a GitHub PR.

    Args:
        pr_identifier: PR number (e.g., "123") or URL

    Returns:
        Structured comment data with metadata and context

    Raises:
        subprocess.CalledProcessError: If gh CLI command fails
        ValueError: If PR identifier is invalid
    """
    # Normalize PR identifier
    pr_number = parse_pr_identifier(pr_identifier)

    # Fetch PR data
    result = subprocess.run(
        ["gh", "pr", "view", pr_number, "--json", "reviews,comments"],
        capture_output=True,
        text=True,
        check=True,
    )

    # Parse and structure
    pr_data = json.loads(result.stdout)
    return structure_comments(pr_data)
```

#### Validation

- [ ] Run `uv run scripts/gh-pr-fetch.py <PR-NUMBER>` with real PR
- [ ] Verify JSON output contains all comment fields
- [ ] Test with PR that has inline comments, review comments, and general comments
- [ ] Test with resolved vs unresolved threads
- [ ] Verify code snippets are correctly extracted
- [ ] Run `just lint-python` to ensure code quality

#### TODO for Stage 1

- [ ] Create `scripts/gh-pr-fetch.py` with argparse CLI
- [ ] Implement `fetch_pr_comments()` function
- [ ] Implement `parse_pr_identifier()` to handle numbers and URLs
- [ ] Implement `structure_comments()` to transform gh output
- [ ] Add error handling for network failures, invalid PRs
- [ ] Add `--output` flag to save JSON to file
- [ ] Add type hints for all functions
- [ ] Write docstrings (Google style) for all public functions
- [ ] Test with multiple PR scenarios

### Stage 2: Comment Response Engine

**Stage ID**: `stage-2`
**Branch**: `feature/pr-feedback-stage-2`
**Status**: Not Started
**Dependencies**: stage-1

#### What

Build a Python script that posts responses to specific PR comment threads using `gh` CLI, with support for replying to specific comments, editing existing responses, and resolving threads.

#### Why

Fetching comments is only half the conversation - we need to respond intelligently. This engine handles the mechanics of posting replies while maintaining thread context.

#### How

**Architecture**: Python script that wraps `gh api` for comment creation/editing

**Implementation Details**:
- Use `gh api` to post replies to specific comment threads
- Support markdown formatting in responses
- Track posted responses to enable editing vs new comments
- Optionally resolve threads after responding
- Validate response text before posting

**Files to Create**:
- `scripts/gh-pr-respond.py` - Response posting script
- `scripts/lib/response_formatter.py` - Markdown formatting helpers

**Files to Modify**:
- `scripts/lib/gh_api.py` - Add response posting functions

**Code Example**:
```python
def post_comment_reply(
    pr_number: str,
    comment_id: str,
    response_text: str,
    resolve_thread: bool = False,
) -> str:
    """Post a reply to a PR review comment thread.

    Args:
        pr_number: PR number
        comment_id: ID of the comment to reply to
        response_text: Markdown-formatted response text
        resolve_thread: Whether to resolve the thread after posting

    Returns:
        ID of the posted comment

    Raises:
        subprocess.CalledProcessError: If posting fails
        ValueError: If response_text is empty
    """
    if not response_text.strip():
        raise ValueError("Response text cannot be empty")

    # Post reply via gh api
    result = subprocess.run(
        [
            "gh", "api",
            f"/repos/{{owner}}/{{repo}}/pulls/{pr_number}/comments/{comment_id}/replies",
            "-f", f"body={response_text}",
            "--method", "POST",
        ],
        capture_output=True,
        text=True,
        check=True,
    )

    posted_comment = json.loads(result.stdout)

    if resolve_thread:
        resolve_comment_thread(comment_id)

    return posted_comment["id"]
```

#### Validation

- [ ] Run `uv run scripts/gh-pr-respond.py --pr <NUMBER> --comment-id <ID> --text "Test"`
- [ ] Verify comment appears in PR thread
- [ ] Test thread resolution
- [ ] Test editing existing comments
- [ ] Test markdown formatting preservation
- [ ] Run `just lint-python`

#### TODO for Stage 2

- [ ] Create `scripts/gh-pr-respond.py` with CLI
- [ ] Implement `post_comment_reply()` function
- [ ] Implement `edit_comment_reply()` for updating responses
- [ ] Implement `resolve_comment_thread()` function
- [ ] Add `format_response_markdown()` helper
- [ ] Add dry-run mode (`--dry-run` flag)
- [ ] Add confirmation prompt for destructive operations
- [ ] Write comprehensive docstrings
- [ ] Add error handling for API rate limits

### Stage 3: Conversation State Tracker

**Stage ID**: `stage-3`
**Branch**: `feature/pr-feedback-stage-3`
**Status**: Not Started
**Dependencies**: stage-1

#### What

Build a state management system that tracks which comments have been addressed, stores conversation history, and identifies comments needing response based on configurable criteria (disagreement keywords, clarification requests).

#### Why

We can't respond to every comment - that's spammy and inefficient. The state tracker maintains conversation memory and filters for comments that actually need Claude's attention.

#### How

**Architecture**: JSON-based state storage in `.claude/pr-state/{pr-number}.json`

**Implementation Details**:
- Store state file per PR in `.claude/pr-state/`
- Track comment IDs, response IDs, timestamps, resolution status
- Implement filtering logic:
  - Disagreement detection: "I disagree", "I don't think", "this won't work"
  - Clarification detection: "can you explain", "why", "how does"
  - Skip resolved threads
  - Skip comments we've already responded to
- Provide diff functionality to show new comments since last sync

**Files to Create**:
- `scripts/gh-pr-state.py` - State management script
- `scripts/lib/state_manager.py` - State persistence logic
- `scripts/lib/comment_filter.py` - Filtering strategies

**State Schema**:
```json
{
  "pr_number": 123,
  "last_sync": "2025-11-23T10:00:00Z",
  "comments": {
    "comment-123": {
      "first_seen": "2025-11-23T10:00:00Z",
      "needs_response": true,
      "response_reason": "disagreement",
      "our_responses": ["response-456"],
      "resolved": false,
      "last_updated": "2025-11-23T10:30:00Z"
    }
  }
}
```

**Code Example**:
```python
def filter_comments_needing_response(
    comments: list[dict[str, Any]],
    state: PRState,
) -> list[dict[str, Any]]:
    """Filter comments to those needing response.

    Args:
        comments: List of comment dictionaries from fetcher
        state: Current PR state

    Returns:
        Filtered list of comments needing response
    """
    needs_response = []

    for comment in comments:
        # Skip if already responded
        if comment["id"] in state.comments and state.comments[comment["id"]].our_responses:
            continue

        # Skip if resolved
        if comment.get("is_resolved"):
            continue

        # Check for disagreement patterns
        if is_disagreement(comment["body"]):
            comment["response_reason"] = "disagreement"
            needs_response.append(comment)
            continue

        # Check for clarification requests
        if is_clarification_request(comment["body"]):
            comment["response_reason"] = "clarification"
            needs_response.append(comment)
            continue

    return needs_response
```

#### Validation

- [ ] Create test PR state files
- [ ] Run filter with various comment patterns
- [ ] Verify disagreement detection catches common phrases
- [ ] Verify clarification detection works
- [ ] Test state persistence across multiple syncs
- [ ] Verify `--new-only` flag shows only new comments
- [ ] Run `just lint-python`

#### TODO for Stage 3

- [ ] Create `scripts/gh-pr-state.py` CLI
- [ ] Implement `PRState` dataclass for type safety
- [ ] Implement `load_state()` and `save_state()` functions
- [ ] Implement `is_disagreement()` pattern matcher
- [ ] Implement `is_clarification_request()` pattern matcher
- [ ] Add `sync_state()` to update from latest PR comments
- [ ] Add `--new-only` flag to show comments since last sync
- [ ] Create `.gitignore` entry for `.claude/pr-state/`
- [ ] Write unit tests for filter logic
- [ ] Document filter patterns in docstrings

### Stage 4: Just Recipe Integration

**Stage ID**: `stage-4`
**Branch**: `feature/pr-feedback-stage-4`
**Status**: Not Started
**Dependencies**: stage-1, stage-2, stage-3

#### What

Create Just recipes that wrap the Python scripts, providing a consistent CLI interface for PR feedback operations (`pr-fetch`, `pr-respond`, `pr-status`, `pr-sync`).

#### Why

Just recipes provide the standardized interface that Claude Code expects, ensuring the PR feedback system works like other repository operations (lint, test, etc.).

#### How

**Architecture**: New justfile `justfiles/pr-feedback.just` imported into main justfile

**Implementation Details**:
- `pr-fetch`: Fetch and display comments needing response
- `pr-respond`: Post a response to a specific comment
- `pr-status`: Show current PR conversation state
- `pr-sync`: Update state from latest PR comments
- All recipes use `uv run` for Python script execution
- Recipes accept PR numbers or URLs
- Output formatted for human reading and Claude parsing

**Files to Create**:
- `justfiles/pr-feedback.just` - PR feedback recipes

**Files to Modify**:
- `justfile` - Add `import? '~/.claude-dotfiles/justfiles/pr-feedback.just'`

**Code Example**:
```just
# Fetch PR comments that need response
pr-fetch PR:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔍 Fetching PR comments for {{PR}}..."

  # Fetch comments
  COMMENTS=$(uv run scripts/gh-pr-fetch.py {{PR}})

  # Load state
  STATE_FILE=".claude/pr-state/{{PR}}.json"
  mkdir -p .claude/pr-state

  # Filter for comments needing response
  uv run scripts/gh-pr-state.py {{PR}} --filter

  echo "✅ Fetched comments needing response"

# Post a response to a PR comment
pr-respond PR COMMENT_ID TEXT:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "💬 Posting response to comment {{COMMENT_ID}} on PR {{PR}}..."

  uv run scripts/gh-pr-respond.py \
    --pr {{PR}} \
    --comment-id {{COMMENT_ID}} \
    --text "{{TEXT}}"

  # Update state
  uv run scripts/gh-pr-state.py {{PR}} --sync

  echo "✅ Response posted"

# Show PR conversation status
pr-status PR:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "📊 PR {{PR}} Status"
  echo "==================="

  uv run scripts/gh-pr-state.py {{PR}} --status

# Sync state with latest PR comments
pr-sync PR:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "🔄 Syncing PR {{PR}} state..."

  uv run scripts/gh-pr-fetch.py {{PR}} --output .claude/pr-state/{{PR}}-latest.json
  uv run scripts/gh-pr-state.py {{PR}} --sync

  echo "✅ State synced"
```

#### Validation

- [ ] Run `just pr-fetch <NUMBER>` with real PR
- [ ] Run `just pr-status <NUMBER>` and verify output
- [ ] Run `just pr-sync <NUMBER>` and verify state updates
- [ ] Test `just pr-respond` with test comment
- [ ] Verify recipes work with both PR numbers and URLs
- [ ] Run `just --list` and verify new recipes appear

#### TODO for Stage 4

- [ ] Create `justfiles/pr-feedback.just`
- [ ] Implement `pr-fetch` recipe
- [ ] Implement `pr-respond` recipe with proper escaping
- [ ] Implement `pr-status` recipe with formatted output
- [ ] Implement `pr-sync` recipe
- [ ] Add helper recipe `pr-help` for usage documentation
- [ ] Update main `justfile` to import pr-feedback recipes
- [ ] Test all recipes with real PRs
- [ ] Document recipes in comments

### Stage 5: Claude Command Interface

**Stage ID**: `stage-5`
**Branch**: `feature/pr-feedback-stage-5`
**Status**: Not Started
**Dependencies**: stage-4

#### What

Create a `/pr-feedback` slash command for Claude Code that provides an interactive PR feedback session, guiding Claude through fetching comments, analyzing what needs response, and posting replies.

#### Why

The slash command provides the user-facing interface that makes the PR feedback system easy to use. Claude can orchestrate the entire workflow interactively.

#### How

**Architecture**: Markdown slash command that prompts Claude with structured workflow

**Implementation Details**:
- Command prompts for PR number/URL
- Runs `just pr-sync` to get latest state
- Runs `just pr-fetch` to show comments needing response
- Displays comments with context for Claude to analyze
- Prompts Claude to draft responses for disagreements/clarifications
- Uses `just pr-respond` to post approved responses
- Updates state after each response

**Files to Create**:
- `commands/pr-feedback.md` - Slash command definition
- `prompts/pr-feedback.md` - Response drafting template

**Command Structure**:
```markdown
---
description: Interactive PR feedback session - fetch, analyze, and respond to review comments
---

You are helping manage GitHub PR review feedback.

## Process

1. **Get PR identifier**
   - Ask user for PR number or URL if not provided
   - Validate PR exists: `gh pr view <PR>`

2. **Sync latest state**
   - Run: `just pr-sync <PR>`
   - This fetches latest comments and updates tracking

3. **Fetch comments needing response**
   - Run: `just pr-fetch <PR>`
   - Display comments with context to user

4. **Analyze and draft responses**
   For each comment:
   - **Disagreement**: Explain rationale, provide evidence, suggest compromise
   - **Clarification**: Provide clear explanation with examples
   - Draft response following template in `.claude/prompts/pr-feedback.md`

5. **Post responses**
   - Show draft to user for approval
   - Run: `just pr-respond <PR> <COMMENT_ID> "<RESPONSE>"`
   - Confirm posting success

6. **Show updated status**
   - Run: `just pr-status <PR>`
   - Summarize what was addressed

## Best Practices

- Be concise but thorough in responses
- Use code examples when clarifying
- Link to documentation when relevant
- Thank reviewers for feedback
- Suggest next steps when resolving disagreements
```

**Response Template** (`prompts/pr-feedback.md`):
```markdown
## Response to PR Review Comment

**Comment Context**:
```
[original comment text]
```

**Code Referenced**:
```[language]
[code snippet]
```

**Response Type**: [Disagreement / Clarification / Acknowledgment]

**Response**:

[Your response here - be professional, clear, and constructive]

**Suggested Action**:
- [ ] [What should happen next]
```

#### Validation

- [ ] Run `/pr-feedback` in Claude Code session
- [ ] Verify Claude prompts for PR number
- [ ] Verify Claude runs `just pr-sync`
- [ ] Verify Claude displays comments
- [ ] Test response drafting flow
- [ ] Verify responses post correctly
- [ ] Test with PR containing multiple comment types

#### TODO for Stage 5

- [ ] Create `commands/pr-feedback.md` slash command
- [ ] Create `prompts/pr-feedback.md` template
- [ ] Add example PR feedback session to `examples/workflows.md`
- [ ] Test command with real PR in Claude Code
- [ ] Refine prompts based on Claude's behavior
- [ ] Add error handling guidance to command
- [ ] Document in README.md

## Testing Strategy

### Unit Testing

**Python Scripts**:
- Test `parse_pr_identifier()` with various formats
- Test `is_disagreement()` and `is_clarification_request()` with comment samples
- Test state serialization/deserialization
- Test comment filtering logic

**Approach**: Use Python stdlib `unittest`, run with `python -m unittest discover`

### Integration Testing

**Just Recipes**:
- Test `pr-fetch` with real PRs (public repos)
- Test `pr-sync` updates state correctly
- Test `pr-respond` posts to test PR
- Test error handling when PR doesn't exist

**Approach**: Manual testing with documented test PRs

### Manual Testing

**Claude Command**:
- Run `/pr-feedback` with test PR
- Verify entire workflow end-to-end
- Test with different comment scenarios:
  - Only disagreements
  - Only clarifications
  - Mix of both
  - Already resolved threads
  - No comments needing response

**Approach**: Create test scenarios document with expected outcomes

### CI/CD Testing

**Linting**:
- All Python scripts must pass `just lint-python`
- All shell scripts in recipes must pass `just lint-shell`

**Validation**:
- Add `scripts/validate-pr-feedback.sh` similar to `validate-release-automation.sh`
- Check required files exist
- Check gh CLI is available
- Check recipes are defined

## Deployment Plan

### Pre-Deployment

1. Ensure `gh` CLI is installed and authenticated
2. Create test PR in personal repo for validation
3. Run `just lint-python` on all new scripts
4. Test all Just recipes manually

### Development Deployment

1. Merge Stage 1 → test `pr-fetch` functionality
2. Merge Stage 2 → test `pr-respond` functionality
3. Merge Stage 3 → test state tracking
4. Merge Stage 4 → test Just integration
5. Merge Stage 5 → test Claude command

### Production Deployment

1. Merge feature branch to main
2. Run `install.sh` to update global symlinks
3. Test `/pr-feedback` command in real project
4. Update README.md with PR feedback documentation
5. Create example workflow documentation

### Rollback Plan

- Each stage is independently testable
- Can disable stages by not importing justfiles
- Can remove slash command by deleting `commands/pr-feedback.md`
- State files are local only - safe to delete

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **GitHub API rate limits** | Medium | High | Use `gh` CLI caching, add retry logic with exponential backoff |
| **Comment parsing fails on complex diffs** | Medium | Medium | Extensive testing with various PR types, fallback to raw comment display |
| **State file conflicts in team settings** | Low | Medium | Document that state is local-only, add `.claude/pr-state/` to `.gitignore` |
| **Inappropriate automated responses** | Medium | High | Require user approval before posting, add dry-run mode, clear templates |
| **gh CLI not authenticated** | High | High | Check authentication in recipes, provide clear error message with setup instructions |
| **Overwhelming number of comments** | Low | Medium | Add `--limit` flag to fetch top N comments, prioritize by response reason |

## Dependencies

### Upstream Dependencies

- **gh CLI** (v2.0+): Required for GitHub API access
- **Python** (3.9+): Script runtime
- **uv**: Python script runner
- **Just**: Task orchestration
- **Git**: Repository context

### Downstream Impact

- **README.md**: Add PR feedback documentation
- **CONTRIBUTING.md**: Add PR review workflow guidance
- **examples/workflows.md**: Add PR feedback examples
- **.gitignore**: Add `.claude/pr-state/`

### Environment Variables

- `GITHUB_TOKEN`: Required for `gh` CLI (automatically used by `gh`)
- `GH_TOKEN`: Alternative token variable

## Success Criteria

- [ ] Can fetch all comments from a PR with `just pr-fetch <PR>`
- [ ] Can post response to specific comment with `just pr-respond <PR> <ID> "<TEXT>"`
- [ ] Can view PR conversation status with `just pr-status <PR>`
- [ ] State correctly tracks which comments have been addressed
- [ ] Filtering correctly identifies disagreements and clarification requests
- [ ] `/pr-feedback` command guides Claude through full workflow
- [ ] All Python scripts pass `just lint-python`
- [ ] Documentation is complete and accurate
- [ ] Works in local development and CI environments
- [ ] Real PR feedback session successfully completes end-to-end

## Overall TODO List

### Stage 1: Core PR Comment Fetcher
- [ ] Create Python scripts for fetching PR comments
- [ ] Implement gh CLI integration
- [ ] Test with real PRs

### Stage 2: Comment Response Engine
- [ ] Create response posting script
- [ ] Implement comment editing
- [ ] Add dry-run mode

### Stage 3: Conversation State Tracker
- [ ] Implement state management
- [ ] Create filtering logic
- [ ] Test filter patterns

### Stage 4: Just Recipe Integration
- [ ] Create pr-feedback.just recipes
- [ ] Test all recipes
- [ ] Update main justfile

### Stage 5: Claude Command Interface
- [ ] Create slash command
- [ ] Create response templates
- [ ] Test full workflow

### Documentation & Testing
- [ ] Write validation script
- [ ] Update README.md
- [ ] Create example workflows
- [ ] Add CONTRIBUTING guidance
