# Code Review

**Reviewer**: Claude
**Date**: [DATE]
**Commit/Branch**: [HASH/BRANCH]

## Summary

**Status**: 🟢 APPROVE | 🟡 NEEDS CHANGES | 🔴 BLOCK
**Quick Take**: [1-2 sentence summary of the changes and verdict]

## Automated Checks

### Linting

**Status**: ✅ PASS | ❌ FAIL ([count] issues)
**Details**:

```text
[lint output]
```

### Tests

**Status**: ✅ PASS | ❌ FAIL
**Coverage**: [X%] (target: [Y%])
**Details**:

```text
[test output]
```

## Changes Overview

[Brief description of what changed]

**Files Modified**: [count]
**Lines Added**: [+X]
**Lines Removed**: [-Y]

## Critical Issues 🔴

**Must be fixed before merge**

### 1. [Issue Title] (file:line)

**Problem**: [What's wrong]
**Risk**: [Why this is critical - security, correctness, performance]
**Fix**:

```go
// Current
problematicCode()

// Should be
fixedCode()
```

## Suggestions 🟡

**Nice-to-haves, improvements**

### 1. [Suggestion Title]

**Current**: [How it works now]
**Suggestion**: [How to improve]
**Benefit**: [Why it's better]
**Example**:

```python
# Suggested improvement
better_code()
```

## Questions ❓

1. [Question about intent or approach]
2. [Clarification needed]

## Positive Notes ✅

[What's done well - be specific]

- Good test coverage on edge cases
- Clear variable naming
- Proper error handling

## Security Review

- [ ] Input validation present
- [ ] No hardcoded secrets
- [ ] Authentication/authorization checked
- [ ] SQL injection prevented
- [ ] XSS prevented

## Performance Considerations

- [ ] No N+1 queries
- [ ] Resources cleaned up properly
- [ ] No obvious bottlenecks
- [ ] Caching used appropriately

## Action Items

### Required (before merge)

- [ ] Fix critical issue 1
- [ ] Fix critical issue 2

### Suggested (nice-to-have)

- [ ] Consider suggestion 1
- [ ] Address question 1

### Follow-up (future work)

- [ ] Refactor X for better maintainability
- [ ] Add integration test for Y

## Reviewer Confidence

**Overall**: High | Medium | Low
**Reasoning**: [Why this confidence level]
