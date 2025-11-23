---
description: Start inline feedback workflow with checkpoint commit
---

You are helping set up an inline feedback workflow for code review without requiring remote VCS or PR systems.

## When to Use

- User requests "/feedback-add" to start a feedback session
- User wants to create a checkpoint before adding manual feedback
- Need to identify which files to review

**Note**: This command creates a checkpoint commit. Users add feedback comments manually using their editor (see editor snippets below).

## What This Command Does

1. **Creates checkpoint commit** - So you can easily revert all feedback later
2. **Shows changed files** - Identifies what needs review
3. **Displays feedback format** - Quick reference for manual addition

This command does NOT add feedback for you - you add it manually in your editor.

## Feedback Format

Use block-style comments with opening/closing tags for easy manual addition:

### For Code Files

Use language-appropriate comment syntax with `FEEDBACK` block:

**Python/Shell/Ruby/YAML:**

```python
# FEEDBACK(@reviewer, 2025-11-23):
# Your multi-line feedback here
# without needing to repeat metadata
# /FEEDBACK
```

**JavaScript/TypeScript/C/C++/Go/Java/Rust:**

```javascript
// FEEDBACK(@reviewer, 2025-11-23):
// Your multi-line feedback here
// without needing to repeat metadata
// /FEEDBACK
```

**CSS (block comment):**

```css
/* FEEDBACK(@reviewer, 2025-11-23):
   Your feedback here
   /FEEDBACK */
```

**HTML:**

```html
<!-- FEEDBACK(@reviewer, 2025-11-23):
Your feedback here
/FEEDBACK -->
```

### For Markdown Files

Use HTML comments to avoid rendering:

```markdown
<!-- FEEDBACK(@reviewer, 2025-11-23):
Your multi-line feedback here
/FEEDBACK -->
```

### Simplified Format (Optional)

If you're the only reviewer, you can omit metadata:

```python
# FEEDBACK:
# Your feedback here
# /FEEDBACK
```

### Metadata Format

Include in opening tag only:

- `@username` (optional - omit if you're the only reviewer)
- Date in `YYYY-MM-DD` format (optional - useful for tracking)
- Clear, actionable feedback between opening and closing tags

## Process

### 1. Create Checkpoint Commit

Before adding feedback, create a checkpoint:

```bash
git add -A
git commit -m "checkpoint: before code review feedback"
```

This allows easy revert of all feedback later:

```bash
git reset --soft HEAD~1  # Undo checkpoint, keep feedback
git reset --hard HEAD~1  # Undo checkpoint, remove feedback
```

### 2. Identify Files to Review

Show user what files have changed:

```bash
git diff --name-only HEAD~1  # Files changed since last commit
git status --short            # Current changes
git diff main... --name-only  # All files in feature branch
```

### 3. Display Format Reference

Show user the feedback format for quick copy/paste:

```text
# For Python/Shell/Ruby:
# FEEDBACK(@yourname, 2025-11-23):
# Your feedback here
# /FEEDBACK

# For JavaScript/C/Go:
// FEEDBACK(@yourname, 2025-11-23):
// Your feedback here
// /FEEDBACK

# For Markdown/HTML:
<!-- FEEDBACK(@yourname, 2025-11-23):
Your feedback here
/FEEDBACK -->
```

### 4. User Adds Feedback Manually

User opens files in their editor and adds feedback blocks:

**Placement Rules:**

- Place feedback IMMEDIATELY BEFORE the line/block being reviewed
- Add blank line after `/FEEDBACK` for readability
- Never break code syntax

**Example - Python:**

```python
def calculate_total(items):
    # FEEDBACK(@alice, 2025-11-23):
    # This function doesn't handle empty lists.
    # Should return 0 or raise ValueError for empty input.
    # /FEEDBACK

    total = 0
    for item in items:
        # FEEDBACK(@alice, 2025-11-23):
        # Missing validation - item might not have 'price' attribute.
        # Consider: hasattr(item, 'price') or try/except.
        # /FEEDBACK

        total += item.price
    return total
```

**Example - Markdown:**

```markdown
## Installation

<!-- FEEDBACK(@bob, 2025-11-23):
This section is missing prerequisites.
Should mention:
- Required Python version (3.8+)
- System dependencies (libpq-dev for PostgreSQL)
/FEEDBACK -->

Run the following command:
```

### 5. Optional: Commit Feedback

After adding feedback manually:

```bash
git add -A
git commit -m "review: add code review feedback"
```

This keeps feedback separate from the checkpoint commit.

## Best Practices

### Feedback Quality

- **Be specific**: Reference exact lines, variables, or logic
- **Be constructive**: Suggest improvements, not just criticism
- **Be actionable**: Reader should know what to do
- **Provide context**: Explain why it matters

**Good:**

```python
# FEEDBACK(@alice, 2025-11-23): The query here causes N+1 problem
# FEEDBACK: Consider using select_related() to fetch related objects in single query
# FEEDBACK: See Django docs: https://docs.djangoproject.com/en/stable/ref/models/querysets/#select-related
```

**Bad:**

```python
# FEEDBACK(@alice, 2025-11-23): This is slow
```

### Severity Levels

Use prefixes to indicate priority:

```python
# FEEDBACK [CRITICAL] (@alice, 2025-11-23): SQL injection vulnerability here
# FEEDBACK [MAJOR] (@alice, 2025-11-23): Memory leak - file handle not closed
# FEEDBACK [MINOR] (@alice, 2025-11-23): Consider more descriptive variable name
# FEEDBACK [NIT] (@alice, 2025-11-23): Extra whitespace
```

### Scope

- **One concern per feedback block**: Don't bundle unrelated issues
- **Keep it focused**: Long feedback might need separate discussion
- **Link to resources**: Include relevant docs, style guides, examples

## Examples

### Example 1: Security Issue

```python
def login(username, password):
    # FEEDBACK [CRITICAL] (@security-team, 2025-11-23): SQL injection vulnerability
    # FEEDBACK: Never concatenate user input into SQL queries
    # FEEDBACK: Use parameterized queries: cursor.execute("SELECT * FROM users WHERE username = ?", (username,))

    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    cursor.execute(query)
```

### Example 2: Performance

```javascript
// FEEDBACK [MAJOR] (@perf-team, 2025-11-23): Inefficient - recalculates on every render
// FEEDBACK: Move this expensive computation to useMemo hook
// FEEDBACK: const filtered = useMemo(() => items.filter(...), [items, filterCriteria])

function MyComponent({ items }) {
    const filtered = items.filter(item => expensiveOperation(item));
    return <div>{filtered.map(...)}</div>;
}
```

### Example 3: Documentation

```markdown
## API Endpoints

<!-- FEEDBACK [MAJOR] (@docs-team, 2025-11-23): Missing authentication requirements -->
<!-- FEEDBACK: Add section explaining auth tokens, where to get them, and how to include in requests -->
<!-- FEEDBACK: Example: "All endpoints require Bearer token in Authorization header" -->

### GET /api/users
```

### Example 4: Code Style

```go
// FEEDBACK [MINOR] (@go-team, 2025-11-23): Not following Go naming conventions
// FEEDBACK: Acronyms should be uppercase: use 'userID' not 'userId'
// FEEDBACK: See: https://go.dev/doc/effective_go#mixed-caps

func GetUserById(userId string) (*User, error) {
```

## Tips

1. **Batch feedback**: Review entire file/section before adding comments
2. **Use line ranges**: For large blocks, indicate start/end
3. **Reference standards**: Link to style guides, RFCs, documentation
4. **Suggest alternatives**: Show what good code looks like
5. **Positive feedback**: Note what's done well too

## Adding Feedback to Multiple Files

When reviewing multiple files:

```bash
# Show files changed
git diff --cached --name-only

# Read each file
# Add feedback to each
# Confirm all changes
```

Summarize across all files:

- Total files reviewed: X
- Total feedback items: Y
- Critical: N, Major: N, Minor: N
- Main themes: [security, performance, style]

## Avoid

- ❌ Breaking syntax with poorly placed comments
- ❌ Vague feedback without specifics
- ❌ Personal attacks or unconstructive criticism
- ❌ Feedback on auto-generated code
- ❌ Nitpicking style when linters exist

## After Adding Feedback

Guide user to:

1. Use `/feedback-review` to see all feedback
2. Respond to or resolve feedback items
3. Use `/feedback-clean` when done to remove all feedback
