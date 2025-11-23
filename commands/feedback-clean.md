---
description: Strip all inline feedback comments from code and markdown files
---

You are helping remove inline feedback comments from files after the review process is complete.

## When to Use

- User requests "/feedback-clean"
- All feedback has been resolved
- Ready to commit final changes
- Need to clean up before deployment or PR

## Safety First

### Pre-Clean Checks

Before removing any feedback, verify:

1. **Check for unresolved feedback:**

```bash
git grep -n "FEEDBACK" | grep -v "RESOLVED"
```

1. **Count feedback items:**

```bash
echo "Total feedback: $(git grep -c 'FEEDBACK' | wc -l)"
echo "Resolved: $(git grep -c 'RESOLVED' | wc -l)"
```

1. **Warn if unresolved exists:**

If unresolved feedback found, ask user:

```text
⚠️  Warning: Found 3 unresolved feedback items:
  - src/auth.py:45 [CRITICAL] - SQL injection
  - src/api.js:123 [MAJOR] - Rate limiting
  - docs/API.md:12 [MINOR] - Documentation

Options:
1. Review unresolved items first (/feedback-review)
2. Clean only resolved feedback
3. Clean all feedback (⚠️  will lose unresolved items)
4. Cancel cleaning
```

## Cleaning Strategies

### Strategy 1: Remove Only Resolved (Recommended)

Remove feedback that's been marked RESOLVED:

```python
# FEEDBACK(@alice, 2025-11-20): Add error handling
# RESPONSE(@bob, 2025-11-21): Added try/except
# RESOLVED(@bob, 2025-11-21): Implemented

# ↓ AFTER CLEANING ↓
# (all three lines removed)
```

**Keep unresolved:**

```python
# FEEDBACK(@alice, 2025-11-20): This still needs work
# RESPONSE(@bob, 2025-11-21): Working on it

# ↓ AFTER CLEANING ↓
# FEEDBACK(@alice, 2025-11-20): This still needs work
# RESPONSE(@bob, 2025-11-21): Working on it
```

### Strategy 2: Remove All Feedback

Remove all FEEDBACK, RESPONSE, and RESOLVED comments:

```python
# FEEDBACK(@alice, 2025-11-20): Add error handling
# RESPONSE(@bob, 2025-11-21): Added try/except
# Some other comment
# RESOLVED(@bob, 2025-11-21): Implemented

# ↓ AFTER CLEANING ↓
# Some other comment
```

### Strategy 3: Convert to Archive

Save feedback to separate file before removing:

```bash
# Extract all feedback to archive
git grep "FEEDBACK" > .claude/feedback-archive-2025-11-23.txt
```

Then clean from source files.

## Process

### 1. Identify Files with Feedback

```bash
# List all files containing feedback
git grep -l "FEEDBACK"
```

Example output:

```text
src/auth.py
src/api.js
src/utils.py
docs/README.md
tests/test_auth.py
```

### 2. Preview Changes

For each file, show user what will be removed:

```text
Preview: src/auth.py

Will remove 3 feedback blocks (6 lines):
  - Line 45-47: [CRITICAL] SQL injection (RESOLVED)
  - Line 78-79: [MAJOR] Input validation (RESOLVED)
  - Line 123: [NIT] Whitespace (RESOLVED)
```

### 3. Create Backup (Optional)

Before cleaning, offer backup:

```bash
# Create backup branch
git checkout -b backup-before-feedback-clean

# Or backup specific files
cp src/auth.py src/auth.py.backup
```

### 4. Clean Files

Use Edit tool to remove feedback blocks:

**Detect patterns:**

- Single-line feedback: `# FEEDBACK(...): ...`
- Multi-line feedback blocks (consecutive feedback lines)
- Resolved blocks (FEEDBACK + RESPONSE + RESOLVED)

**Removal rules:**

- Remove entire feedback block (all consecutive FEEDBACK/RESPONSE/RESOLVED lines)
- Preserve blank lines before/after feedback (for code readability)
- Don't remove non-feedback comments
- Maintain file indentation

**Example Edit:**

Before:

```python
def authenticate(username, password):
    # FEEDBACK(@alice, 2025-11-20): SQL injection risk
    # RESPONSE(@bob, 2025-11-21): Migrated to parameterized query
    # RESOLVED(@bob, 2025-11-21): Fixed

    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
```

After:

```python
def authenticate(username, password):
    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
```

### 5. Verify Syntax

After cleaning, verify code still works:

```bash
# Run linters
just lint 2>&1 || true

# Run tests
just test 2>&1 || true

# Check syntax for Python
python -m py_compile src/**/*.py

# Check syntax for JavaScript
npx eslint src/**/*.js --quiet
```

### 6. Report Results

Show summary:

```text
✅ Feedback cleaning complete

Files processed: 5
Total feedback blocks removed: 12
Lines removed: 28

Details:
  - src/auth.py: 3 blocks (6 lines)
  - src/api.js: 4 blocks (9 lines)
  - src/utils.py: 2 blocks (5 lines)
  - docs/README.md: 2 blocks (6 lines)
  - tests/test_auth.py: 1 block (2 lines)

Unresolved feedback remaining: 0

Next steps:
  1. Review changes: git diff
  2. Run tests: just test
  3. Commit: git commit -am "Clean up code review feedback"
```

## Pattern Matching

### Patterns to Match

Match all variations of feedback comments:

**Python/Shell/Ruby/YAML:**

```regex
^\s*#\s*FEEDBACK.*$
^\s*#\s*RESPONSE.*$
^\s*#\s*RESOLVED.*$
```

**JavaScript/TypeScript/C/C++/Go/Java:**

```regex
^\s*//\s*FEEDBACK.*$
^\s*//\s*RESPONSE.*$
^\s*//\s*RESOLVED.*$
```

**CSS/C block comments:**

```regex
^\s*/\*\s*FEEDBACK.*?\*/\s*$
^\s*/\*\s*RESPONSE.*?\*/\s*$
^\s*/\*\s*RESOLVED.*?\*/\s*$
```

**HTML/Markdown:**

```regex
^\s*<!--\s*FEEDBACK.*?-->\s*$
^\s*<!--\s*RESPONSE.*?-->\s*$
^\s*<!--\s*RESOLVED.*?-->\s*$
```

### Block Detection

Identify feedback blocks (consecutive feedback lines):

```python
# FEEDBACK(@alice, 2025-11-20): This is line 1 of feedback
# FEEDBACK: This is line 2 of feedback
# RESPONSE(@bob, 2025-11-21): Response here
# RESPONSE: More response
# RESOLVED(@bob, 2025-11-21): Resolution

# ↑ This is ONE block (5 lines) - remove all together
```

## Advanced Options

### Selective Cleaning

Clean by criteria:

**1. By severity:**

```bash
# Remove only NITs
git grep -l "FEEDBACK \[NIT\]"
```

**2. By age:**

```bash
# Remove feedback older than 30 days
git grep "FEEDBACK" | grep -E "2025-(09|10)-"
```

**3. By author:**

```bash
# Remove feedback from specific reviewer
git grep "FEEDBACK(@alice"
```

**4. By file pattern:**

```bash
# Clean only test files
git grep -l "FEEDBACK" -- "test_*.py"
```

### Archive Before Cleaning

Create structured archive:

```markdown
# Feedback Archive - 2025-11-23

This document contains all feedback that was removed from the codebase after resolution.

## src/auth.py

### Line 45 (CRITICAL) - SQL Injection
**Reviewer**: @security-team
**Date**: 2025-11-20
**Feedback**: SQL injection vulnerability. Use parameterized queries.
**Response**: @bob (2025-11-21): Migrated to cursor.execute with parameters
**Resolution**: Fixed in commit abc123. Added test for SQL injection attempts.
**Resolved**: 2025-11-21

### Line 78 (MAJOR) - Input Validation
**Reviewer**: @alice
**Date**: 2025-11-20
**Feedback**: Missing username format validation
**Response**: @bob (2025-11-21): Added regex validation for email/alphanumeric
**Resolution**: Implemented with comprehensive test coverage
**Resolved**: 2025-11-21

## src/api.js

### Line 123 (MAJOR) - Rate Limiting
...
```

### Partial Cleaning

Clean specific files only:

```bash
# User specifies files
/feedback-clean src/auth.py src/api.js

# Clean everything except specific files
/feedback-clean --except docs/
```

## Edge Cases

### 1. Feedback in Strings

Don't remove feedback text in string literals:

```python
# FEEDBACK(@alice, 2025-11-20): This should be removed

error_msg = "FEEDBACK: User not found"  # This should NOT be removed
```

**Solution:** Only match comment syntax, not string contents.

### 2. Nested Comments

Handle feedback in block comments:

```javascript
/*
 * FEEDBACK(@alice, 2025-11-20): This function needs docs
 * RESPONSE(@bob, 2025-11-21): Adding JSDoc
 * RESOLVED(@bob, 2025-11-21): Added
 */
function myFunc() {}
```

**Solution:** Match and remove entire block comment.

### 3. Mixed Feedback Blocks

Block with both resolved and unresolved:

```python
# FEEDBACK(@alice, 2025-11-20): Issue A
# RESPONSE(@bob, 2025-11-21): Fixed A
# RESOLVED(@bob, 2025-11-21): Done

# FEEDBACK(@alice, 2025-11-22): Issue B
# Still unresolved
```

**Solution:** Treat as two separate blocks. Remove first, keep second.

### 4. Indented Feedback

Preserve indentation context:

```python
def outer():
    def inner():
        # FEEDBACK(@alice, 2025-11-20): Nested too deep
        # RESOLVED(@bob, 2025-11-21): Refactored to flat structure

        pass
```

**Solution:** Match feedback at any indentation level, remove entire line including indentation.

## Validation After Cleaning

### 1. Syntax Check

Ensure code still valid:

```bash
# Python
python -m compileall .

# JavaScript
npm run lint

# Go
go build ./...
```

### 2. Test Suite

Run full test suite:

```bash
just test
```

### 3. Git Diff Review

Show user what changed:

```bash
git diff
```

### 4. Line Count Verification

Confirm expected line reduction:

```bash
# Before cleaning
wc -l src/auth.py  # 150 lines

# After cleaning
wc -l src/auth.py  # 144 lines (-6 as expected)
```

## Interactive Mode

Guide user through cleaning process:

```text
Feedback Cleaning Tool

Found 5 files with feedback (12 total items)

Status:
  ✅ Resolved: 9 items
  ⏳ Unresolved: 3 items

What would you like to do?
1. Clean all resolved feedback (recommended)
2. Review unresolved items first
3. Clean everything (⚠️  will lose unresolved)
4. Archive feedback before cleaning
5. Clean specific files only
6. Cancel

Your choice: 1

Cleaning resolved feedback...

✅ src/auth.py (3 blocks removed)
✅ src/api.js (4 blocks removed)
✅ src/utils.py (2 blocks removed)

Complete! 9 feedback blocks removed.
3 unresolved items remain in:
  - docs/README.md (2 items)
  - tests/test_auth.py (1 item)

Next: Review changes with 'git diff'
```

## Best Practices

1. **Always archive first**: Save feedback history before removing
2. **Verify tests pass**: Ensure cleaning didn't break syntax
3. **Review diffs**: Check that only feedback was removed
4. **Clean incrementally**: Resolve and clean in batches
5. **Use git**: Commit before cleaning for easy rollback
6. **Document decisions**: Keep resolved items in archive

## Tips

- Run `/feedback-review` before `/feedback-clean`
- Create backup branch before bulk cleaning
- Archive feedback for future reference
- Clean regularly, don't let feedback accumulate
- Use `git diff` to verify only comments removed
- Test after cleaning to catch syntax errors

## After Cleaning

User should:

1. Review changes: `git diff`
2. Run tests: `just test`
3. Commit changes: `git commit -am "Clean up resolved code review feedback"`
4. Archive feedback if needed
5. Continue development with clean codebase
