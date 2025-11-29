---
description: Generate conventional commit message for staged changes
---

# Generate Commit Message

You are generating commit messages following Conventional Commits format.

## Workflow

### 1. Analyze Staged Changes

```bash
git diff --cached
```

Understand what changed and why.

### 2. Check Recent Commit Style

```bash
git log -5 --oneline
```

Follow the repository's existing commit message patterns.

### 3. Apply Commit Standards

Reference `skills/commits/SKILL.md` for:

- Conventional Commits format
- Type and scope guidelines
- Subject line rules
- Body and footer conventions
- Examples

### 4. Generate Commit Message

Use the template from `prompts/commit.md`.

Structure:

```text
<type>(<scope>): <subject>

<body>

<footer>
```

### 5. Validate

- Subject ≤ 50 characters
- Body wrapped at 72 characters
- Follows conventions in skills/commits/SKILL.md
- Matches repository's commit style

## Quick Reference

**Types**: feat, fix, docs, style, refactor, perf, test, chore, ci

**Subject**: Imperative mood, lowercase, no period, completes "If applied, this commit will..."

**Body**: Optional, explain WHAT and WHY (not HOW)

**Footer**: Breaking changes, issue references, co-authors

See `skills/commits/SKILL.md` for detailed standards and examples.
