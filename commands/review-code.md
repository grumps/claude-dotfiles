---
description: Review staged code changes with automated checks
---

You are conducting thorough code reviews with focus on correctness, style, and maintainability.

## Pre-Review Automated Checks

### 1. Run Linters
```bash
just lint 2>&1 || true
```
Analyze linter output for style and quality issues (errors are captured, not fatal).

### 2. Run Tests
```bash
just test 2>&1 || true
```
Check if tests pass and review coverage (errors are captured, not fatal).

### 3. Get Changes
```bash
git diff --cached
```
Review staged changes.

## Review Checklist

### Correctness
- Logic errors or bugs
- Edge cases handled
- Error handling appropriate
- Null/nil checks where needed
- Race conditions (for concurrent code)

### Code Quality
- Follows linter rules (already checked)
- Clear variable/function names
- Appropriate comments (why, not what)
- No commented-out code
- No debug statements left in

### Testing
- Adequate test coverage
- Tests actually test the right things
- Edge cases covered
- Error cases tested

### Performance
- Obvious inefficiencies (N+1 queries, unnecessary loops)
- Resource leaks (files, connections not closed)
- Excessive memory allocation

### Security
- Input validation
- SQL injection prevention
- XSS prevention
- Authentication/authorization checks
- Secrets not hardcoded

### Maintainability
- Code is readable
- Functions are focused (single responsibility)
- Complexity is reasonable
- Dependencies are justified

## Language-Specific Checks

### Go
- Proper error handling (don't ignore errors)
- Context passed to functions that need it
- Defer for cleanup (close files/connections)
- Use of sync primitives is correct
- No goroutine leaks

### Python
- Type hints present
- Exception handling appropriate
- With statements for resources
- List/dict comprehensions used appropriately
- Async/await used correctly if applicable

### Kubernetes Manifests
- Resource limits defined
- Liveness/readiness probes configured
- Labels follow conventions
- RBAC is least-privilege
- Secrets not in plain text

## Output Format

Use the template from `.claude/prompts/review-code.md`:

```
# Code Review

## Summary
**Status**: [APPROVE ✅ / NEEDS CHANGES ⚠️ / BLOCK ❌]
**Quick take**: [1-2 sentence summary]

## Automated Checks
- **Lint**: [PASS/FAIL with count of issues]
- **Tests**: [PASS/FAIL with coverage %]

## Critical Issues (must fix before merge)
1. **[Issue title]** (file:line)
   - Problem: [What's wrong]
   - Risk: [Why it matters]
   - Fix: [How to fix, code example]

## Suggestions (nice-to-haves)
1. **[Suggestion title]**
   - Current: [What it does now]
   - Suggestion: [How to improve]
   - Benefit: [Why it's better]

## Positive Notes
[What's done well - be specific and encouraging]

## Action Items
- [ ] Fix critical issue 1
- [ ] Fix critical issue 2
- [ ] Consider suggestion 1
```

## Best Practices
- Start with positives when possible
- Be specific with file/line references
- Provide code examples for fixes
- Explain WHY something is an issue
- Distinguish between critical vs. nice-to-have
- Consider the context (is this a quick fix or new feature?)
