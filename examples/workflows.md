# Example Workflows

Common workflows using Claude dotfiles integration.

## Workflow 1: Planning a New Feature

### Scenario
You need to add rate limiting to your API.

### Steps

1. **Start in Claude chat:**
   ```
   /plan add rate limiting middleware to API
   ```

2. **Claude will:**
   - Ask clarifying questions if needed
   - Run `just info` to understand your repo
   - Generate implementation plan
   - Save to `.claude/plans/2025-11-15-rate-limiting.md`

3. **Review the plan:**
   ```
   /review-plan .claude/plans/2025-11-15-rate-limiting.md
   ```

4. **Claude provides feedback on:**
   - Completeness
   - Technical approach
   - Risks
   - Missing elements

5. **Implement following the plan**

## Workflow 2: Code Review Before Commit

### Scenario
You've made changes and want review before committing.

### Steps

1. **Stage your changes:**
   ```bash
   git add .
   ```

2. **Request review in Claude:**
   ```
   /review-code
   ```

3. **Claude will:**
   - Run `just lint-for-claude` (get lint output)
   - Run `just test-for-claude` (get test results)
   - Analyze your `git diff --cached`
   - Provide comprehensive review

4. **Review output includes:**
   - Summary (approve/needs changes/block)
   - Automated check results
   - Critical issues to fix
   - Suggestions for improvement
   - Positive feedback

5. **Fix issues and re-review if needed**

6. **Commit when ready:**
   ```bash
   git commit
   ```

   Pre-commit hook runs `just validate` automatically.

## Workflow 3: Generating Commit Messages

### Scenario
You want Claude to write your commit message.

### Steps

1. **Stage your changes:**
   ```bash
   git add .
   ```

2. **Option A - In Claude chat:**
   ```
   /commit
   ```

   Claude analyzes staged changes and generates message.
   Copy the message and use it:
   ```bash
   git commit -m "feat(api): add rate limiting middleware

   Implements token bucket algorithm with Redis backend.
   Configurable via RATE_LIMIT_* environment variables.

   Closes PLAT-123"
   ```

3. **Option B - Using prepare-commit-msg hook:**

   Enable the hook (one-time):
   ```bash
   chmod +x .git/hooks/prepare-commit-msg
   ```

   Then commit normally:
   ```bash
   git commit
   ```

   Your editor opens with generated message. Edit if needed and save.

## Workflow 4: Full Feature Workflow

### Scenario
Complete workflow from planning to deployment.

### Steps

1. **Create plan:**
   ```
   In Claude: /plan implement user authentication with OAuth
   ```

2. **Review plan:**
   ```
   In Claude: /review-plan .claude/plans/2025-11-15-oauth-auth.md
   ```

3. **Implement phase 1:**
   - Follow plan steps
   - Run `just validate` frequently

4. **Review phase 1:**
   ```bash
   git add .
   ```
   ```
   In Claude: /review-code
   ```

5. **Fix issues, commit phase 1:**
   ```
   In Claude: /commit
   ```
   ```bash
   git commit # (paste message or let hook generate)
   ```

6. **Repeat for phase 2, 3, etc.**

7. **Final review before PR:**
   ```
   In Claude: review all changes in this feature branch
   ```

8. **Create PR with plan linked:**
   ```markdown
   Implements user authentication with OAuth.

   See implementation plan: .claude/plans/2025-11-15-oauth-auth.md

   ## Changes
   - [x] OAuth client integration
   - [x] Token management
   - [x] User session handling

   ## Testing
   - [x] Unit tests (95% coverage)
   - [x] Integration tests
   - [x] Manual testing in staging
   ```

## Workflow 5: Quick Validation

### Scenario
Check if your code is ready to commit.

### Steps

1. **Run validation:**
   ```bash
   just validate
   ```

   This runs:
   - `just lint`
   - `just test`

2. **If validation fails:**
   - Fix lint issues: `just lint`
   - Fix test failures: `just test`
   - Ask Claude for help if needed

3. **When validation passes:**
   - Safe to commit (hook will pass)

## Workflow 6: Understanding the Codebase

### Scenario
You're new to the repo and want to understand it.

### Steps

1. **Check available commands:**
   ```bash
   just --list
   ```

2. **Get repository context:**
   ```bash
   just info
   ```

3. **Ask Claude:**
   ```
   I'm new to this repository. Based on the context, can you explain:
   - Main components
   - How to run tests
   - Deployment process
   ```

4. **Review existing plans:**
   ```
   What patterns do you see in .claude/plans/ ?
   ```

## Workflow 7: Customizing for Your Team

### Scenario
Set up repo-specific guidelines.

### Steps

1. **Edit context file:**
   ```yaml
   # .claude/context.yaml
   project:
     name: "Payment API"
     description: "Handles payment processing"

   conventions:
     commit_scopes:
       - payment
       - stripe
       - refund
       - webhook
   ```

2. **Customize commit style:**
   ```bash
   cp .claude/prompts/commit.md .claude/prompts/commit-custom.md
   # Edit to add team-specific rules
   ```

3. **Add team-specific skill:**
   ```bash
   mkdir -p .claude/skills/team
   # Create SKILL.md with your patterns
   ```

4. **Upload to Claude:**
   - Upload shared skills from `.claude/skills/shared/`
   - Upload team skills from `.claude/skills/team/`

5. **Document in README:**
   ```markdown
   ## Team Conventions
   - We use specific commit scopes (see .claude/context.yaml)
   - Upload team skills from .claude/skills/team/ to Claude
   ```

## Tips

- **Use /plan for any feature** - even small ones benefit from structure
- **Review before committing** - catch issues early
- **Let Claude write commits** - consistent style across team
- **Check `just --list` often** - discover new recipes
- **Customize prompts** - make them match your team's style
- **Keep plans** - great documentation of decisions
