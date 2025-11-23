---
description: Review, respond to, and resolve inline feedback in code and markdown files
---

You are helping review and manage inline feedback comments that were added using `/feedback-add`.

## When to Use

- User requests "/feedback-review"
- User wants to see all pending feedback
- User needs to respond to feedback comments
- User wants to mark feedback as resolved

## Feedback States

Feedback can be in three states:

### 1. Open (Needs Response)

```python
# FEEDBACK(@reviewer, 2025-11-23):
# This needs better error handling
# /FEEDBACK
```

### 2. Responded (Under Discussion)

```python
# FEEDBACK(@reviewer, 2025-11-23):
# This needs better error handling
# /FEEDBACK

# RESPONSE(@author, 2025-11-23):
# Good point. Planning to add try/except for FileNotFoundError
# /RESPONSE
```

### 3. Resolved (Addressed)

```python
# FEEDBACK(@reviewer, 2025-11-23):
# This needs better error handling
# /FEEDBACK

# RESPONSE(@author, 2025-11-23):
# Added comprehensive error handling
# /RESPONSE

# RESOLVED(@author, 2025-11-23):
# Implemented - added try/except for FileNotFoundError and IOError
# /RESOLVED
```

## Process

### 1. Find All Feedback

Search for feedback comments across the codebase:

```bash
# Find all feedback comments
git grep -n "FEEDBACK" | head -50

# Or use Grep tool to find in specific paths
```

Common patterns to search:

- `FEEDBACK(@` - All feedback with attribution
- `# FEEDBACK` - Python/Shell/YAML feedback
- `// FEEDBACK` - JavaScript/C/Go feedback
- `<!-- FEEDBACK` - HTML/Markdown feedback

### 2. Categorize Feedback

Group feedback by:

- **File**: Which files have feedback
- **Severity**: CRITICAL, MAJOR, MINOR, NIT
- **Status**: Open, Responded, Resolved
- **Author**: Who left the feedback

### 3. Present Summary

Show user a clear overview:

```text
# Feedback Summary

## Files with Feedback
- src/auth.py (3 items: 1 CRITICAL, 2 MAJOR)
- src/utils.js (2 items: 2 MINOR)
- docs/README.md (1 item: 1 MAJOR)

## By Status
- Open: 4
- Responded: 1
- Resolved: 1

## By Severity
- CRITICAL: 1
- MAJOR: 3
- MINOR: 2

## Details

### src/auth.py:45
**[CRITICAL]** SQL injection vulnerability
- **Reviewer**: @security-team (2025-11-23)
- **Feedback**: Never concatenate user input into SQL queries
- **Status**: ⏳ Open

### src/auth.py:78
**[MAJOR]** Missing input validation
- **Reviewer**: @alice (2025-11-23)
- **Feedback**: Should validate username format (email or alphanumeric)
- **Status**: 💬 Responded
- **Response**: @bob (2025-11-23): Will add regex validation
```

### 4. Guide Response Actions

Help user decide what to do:

**For CRITICAL/MAJOR:**

1. Prioritize these first
2. Understand the concern
3. Fix the code
4. Respond with what was done
5. Mark as resolved

**For MINOR/NIT:**

1. Batch these together
2. Decide if worth addressing now
3. Respond or resolve

### 5. Add Responses

When user wants to respond to feedback, use Edit tool:

**Before:**

```python
# FEEDBACK(@alice, 2025-11-23): This function is too long, consider splitting

def process_data(data):
    # ... 50 lines of code ...
```

**After:**

```python
# FEEDBACK(@alice, 2025-11-23): This function is too long, consider splitting
# RESPONSE(@bob, 2025-11-23): Agreed. Will extract validation and transformation into separate functions

def process_data(data):
    # ... 50 lines of code ...
```

### 6. Mark as Resolved

When feedback is addressed:

#### Option A: Code Fixed

```python
# FEEDBACK(@alice, 2025-11-23): This function is too long, consider splitting
# RESPONSE(@bob, 2025-11-23): Agreed. Will extract validation and transformation
# RESOLVED(@bob, 2025-11-23): Split into process_data(), validate_input(), and transform_data()

def process_data(data):
    validated = validate_input(data)
    transformed = transform_data(validated)
    return save_result(transformed)
```

#### Option B: Acknowledged but Won't Fix

```python
# FEEDBACK(@alice, 2025-11-23): Consider using async here
# RESPONSE(@bob, 2025-11-23): Async would add complexity without benefit for our use case
# RESOLVED(@bob, 2025-11-23): Keeping synchronous - processing time is negligible (<10ms)

def fetch_user(user_id):
    return db.query(User).get(user_id)
```

#### Option C: Question/Clarification

```python
# FEEDBACK(@alice, 2025-11-23): This might fail for edge case X
# RESPONSE(@bob, 2025-11-23): Can you provide example of edge case X? Our tests cover empty, null, and malformed inputs
```

## Response Best Practices

### Good Responses

✅ **Specific and actionable:**

```python
# RESPONSE(@bob, 2025-11-23): Added try/except for FileNotFoundError and IOError. Returns None on error with logged warning.
```

✅ **Explains decision:**

```python
# RESPONSE(@bob, 2025-11-23): Keeping synchronous - this runs once at startup, async overhead not justified
```

✅ **Commits to action:**

```python
# RESPONSE(@bob, 2025-11-23): Good catch! Will refactor in next commit. Tracking in TODO above function.
```

✅ **Asks for clarification:**

```python
# RESPONSE(@bob, 2025-11-23): Can you elaborate on the security concern? We're already validating input at API boundary.
```

### Bad Responses

❌ **Vague:**

```python
# RESPONSE(@bob, 2025-11-23): Will fix later
```

❌ **Defensive:**

```python
# RESPONSE(@bob, 2025-11-23): This works fine, there's no issue
```

❌ **Missing context:**

```python
# RESPONSE(@bob, 2025-11-23): Done
```

## Bulk Operations

### Resolve All NITs

If user wants to resolve all minor issues at once:

```bash
# Find all NIT feedback
git grep -n "FEEDBACK \[NIT\]"

# User can choose to:
# 1. Fix them all
# 2. Resolve without fixing (acknowledge)
# 3. Convert to TODO items for later
```

### Track Unresolved

Create report of what needs attention:

```text
## Unresolved Feedback Report

Generated: 2025-11-23

### High Priority (4 items)
1. src/auth.py:45 - SQL injection [CRITICAL]
2. src/api.js:123 - Rate limiting missing [MAJOR]
3. src/utils.py:67 - Memory leak [MAJOR]
4. docs/API.md:12 - Missing auth docs [MAJOR]

### Medium Priority (2 items)
5. src/helpers.js:34 - Error handling [MINOR]
6. tests/test_auth.py:89 - Test coverage [MINOR]

### Action Required
- Fix critical security issue (item 1) before deployment
- Address major items before PR
- Minor items can be separate PR

### Statistics
- Total feedback: 6
- Responded: 0
- Resolved: 0
- Average age: 2 days
```

## Interactive Review

Guide user through feedback one by one:

```text
Reviewing feedback items (1/6)

File: src/auth.py:45
Severity: [CRITICAL]
Author: @security-team
Date: 2025-11-23

Feedback:
> SQL injection vulnerability. Never concatenate user input into SQL queries.
> Use parameterized queries: cursor.execute("SELECT * FROM users WHERE username = ?", (username,))

Current code:
    query = f"SELECT * FROM users WHERE username = '{username}'"

What would you like to do?
1. Show me the code context
2. Fix this now
3. Add a response
4. Mark as resolved
5. Skip to next
6. Stop review
```

## Converting Feedback to TODOs

If feedback can't be addressed immediately, convert to TODO:

**Before:**

```python
# FEEDBACK(@alice, 2025-11-23): This needs better error handling
# RESPONSE(@bob, 2025-11-23): Agreed, will address in separate refactor
# RESOLVED(@bob, 2025-11-23): Converted to TODO for v2.0

# TODO(bob): Add comprehensive error handling (from feedback 2025-11-23)
# - Handle FileNotFoundError
# - Handle PermissionError
# - Add retry logic for network errors
def read_config(path):
    return open(path).read()
```

## Export Feedback

Create standalone feedback report:

```bash
# Generate markdown report
git grep "FEEDBACK" > feedback-report.txt

# Or create structured report
```

```markdown
# Code Review Feedback

Date: 2025-11-23
Reviewer: Multiple
Files reviewed: 12

## Critical Issues

### src/auth.py:45 - SQL Injection
**Status**: Open
**Impact**: High - Security vulnerability
**Details**: ...

## Major Issues

### src/api.js:123 - Rate Limiting
**Status**: Responded
**Impact**: Medium - DoS risk
**Details**: ...

[Continue for all feedback...]
```

## Tips

1. **Triage first**: Review all feedback before responding
2. **Group related**: Address similar feedback together
3. **Test fixes**: Verify fixes work before resolving
4. **Document decisions**: Explain why feedback accepted/rejected
5. **Track progress**: Use resolved count to show progress
6. **Clean up**: Use `/feedback-clean` when all resolved

## Examples

### Example 1: Security Fix

```python
# FEEDBACK [CRITICAL] (@security, 2025-11-20): SQL injection vulnerability
# RESPONSE(@bob, 2025-11-21): Migrated to parameterized query with cursor.execute
# RESOLVED(@bob, 2025-11-21): Fixed and tested. Added test case for SQL injection attempt.

def get_user(username):
    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
    return cursor.fetchone()
```

### Example 2: Won't Fix

```python
# FEEDBACK [MINOR] (@alice, 2025-11-20): Could use walrus operator here
# RESPONSE(@bob, 2025-11-21): Team agreed to avoid walrus for readability (see style guide section 3.4)
# RESOLVED(@bob, 2025-11-21): Won't fix - following project style guide

if len(items) > 0:
    n = len(items)
    print(f"Processing {n} items")
```

### Example 3: Needs Discussion

```python
# FEEDBACK [MAJOR] (@alice, 2025-11-20): Should this be async?
# RESPONSE(@bob, 2025-11-21): This is called from sync context in main(). Making it async would require refactoring entire call chain. Is the benefit worth it?
# RESPONSE(@alice, 2025-11-22): Fair point. Let's keep sync for now, but consider async when we refactor the pipeline in Q2.
# RESOLVED(@bob, 2025-11-22): Keeping synchronous based on discussion above.

def process_batch(items):
    for item in items:
        handle_item(item)
```

## After Review

User should:

1. Commit any fixes made
2. Use `/feedback-clean` if all feedback resolved
3. Or keep unresolved feedback for continued discussion
