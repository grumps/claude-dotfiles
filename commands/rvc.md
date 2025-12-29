---
description: Review staged code changes with automated checks
argument-hint: (no arguments)
---

# Review Code (rvc)

> Quick command: `/gdf:rvc` or `/rvc`
>
> Conducts thorough code review of staged changes with automated checks.

## Quick Reference

- **Usage**: `/rvc`
- **Prerequisites**: Changes must be staged (`git add`)
- **Output**: Code review with security, performance, and style checks

## Error Handling

- **No staged changes**: Shows error message and usage instructions
- **Linters fail**: Reports failures and continues with review
- **Not in git repository**: Shows error about git requirement

## Code Review

You are conducting thorough code reviews with focus on correctness, style, and maintainability.

## Workflow

### 1. Run Automated Checks

```bash
just lint 2>&1 || true
just test 2>&1 || true
```

Capture linter output and test results (non-fatal, used for analysis).

### 2. Get Staged Changes

```bash
git diff --cached
```

Review what's being committed.

### 3. Apply Review Standards

Reference the reviewing skill for checklist, language-specific checks, and best practices:

@../skills/reviewing/SKILL.md

### 4. Conduct Review

Analyze the code using the checklist:

- **Critical issues** - Must fix before merge (security, correctness)
- **Suggestions** - Nice-to-haves (style, optimization)
- **Positive notes** - What's done well

### 5. Generate Review

Use the template from:

@../prompts/review-code.md

Include:

- Summary with status (APPROVE/NEEDS CHANGES/BLOCK)
- Automated check results
- Critical issues with file:line references
- Suggestions for improvement
- Positive notes
- Action items

## Review Principles

- Be specific with file/line references
- Provide code examples for fixes
- Explain WHY something is an issue
- Distinguish critical vs. nice-to-have
- Start with positives when possible

See `skills/reviewing/SKILL.md` for detailed checklist and language-specific guidelines.
