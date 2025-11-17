# Commit Message Standards

You are generating commit messages that follow Conventional Commits format.

## When to Use
- User requests commit message (via "/commit")
- prepare-commit-msg hook is triggered
- User asks "write a commit message"

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type (required)
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only changes
- **style**: Formatting, missing semicolons, etc (no code change)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding missing tests or correcting existing
- **chore**: Maintenance (dependencies, build, tooling)
- **ci**: CI/CD changes

### Scope (optional but recommended)
Examples (customize per repository):
- **api**: API endpoints
- **auth**: Authentication/authorization
- **db**: Database
- **k8s**: Kubernetes manifests
- **ci**: CI/CD pipelines
- **helm**: Helm charts
- **cli**: Command-line interface

### Subject (required)
- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize first letter
- No period at the end
- Max 50 characters
- Complete the sentence: "If applied, this commit will..."

### Body (optional)
- Wrap at 72 characters
- Explain WHAT and WHY, not HOW
- Separate from subject with blank line
- Can have multiple paragraphs

### Footer (optional)
- Breaking changes: `BREAKING CHANGE: description`
- Issue references: `Closes #123, Fixes #456`
- Co-authors: `Co-authored-by: Name <email>`

## Process

### 1. Analyze Changes
```bash
git diff --cached
```
Understand what changed and why.

### 2. Determine Type and Scope
- What kind of change is this?
- What area of the codebase?

### 3. Write Subject
- Start with type and scope
- Complete: "If applied, this commit will [subject]"
- Keep under 50 chars

### 4. Add Body (if needed)
Body is optional but recommended for:
- Non-obvious changes
- Multiple related changes
- Context that helps reviewers
- Breaking changes

### 5. Add Footer (if applicable)
- Link to tickets/issues
- Note breaking changes
- Credit co-authors

## Examples

### Simple Feature
```
feat(api): add rate limiting middleware

Implements token bucket algorithm with Redis backend.
Configurable via RATE_LIMIT_* environment variables.
Default: 100 requests per minute per IP.

Closes PLAT-123
```

### Bug Fix
```
fix(k8s): correct probe timeout values

Liveness probe was too aggressive causing unnecessary restarts.
Increased timeout from 1s to 5s based on p99 latency metrics.
Also increased failure threshold from 3 to 5.
```

### Breaking Change
```
feat(auth)!: migrate to OAuth 2.0

BREAKING CHANGE: JWT tokens issued before this release are invalid.
Users will need to re-authenticate.

Replaces custom token auth with industry-standard OAuth 2.0.
Improves security and enables SSO integration.

Closes AUTH-45
```

### Refactor
```
refactor(db): extract query builders to separate package

No functional changes. Improves testability and reusability
of database query construction logic.
```

### Documentation
```
docs(readme): add installation instructions for Windows

Includes PowerShell and WSL setup steps.
```

## Best Practices
- One logical change per commit
- Subject tells you what, body tells you why
- Link to issues/tickets when available
- Use `!` or `BREAKING CHANGE:` for breaking changes
- Keep it professional but concise
- Don't describe how the code works (that's what code is for)

## What to Avoid
- Vague messages: "fix bug", "update code"
- Too much detail in subject: "fix the issue where..."
- Commit message explaining implementation details
- Multiple unrelated changes in one commit
