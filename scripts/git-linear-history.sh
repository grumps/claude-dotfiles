#!/bin/bash
# Git Linear History Workflow
# This script helps maintain a clean, linear git history by:
# 1. Rebasing and squashing commits on the feature branch
# 2. Pulling the latest main branch
# 3. Rebasing the feature branch onto main
# 4. Force pushing changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  error "Not in a git repository"
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  error "Could not determine current branch"
fi

# Check if we're on main/master
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  error "Cannot run this script on main/master branch. Please checkout your feature branch."
fi

info "Current branch: $CURRENT_BRANCH"

# Determine main branch name
MAIN_BRANCH=""
if git show-ref --verify --quiet refs/heads/main; then
  MAIN_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
  MAIN_BRANCH="master"
else
  error "Could not find main or master branch"
fi

info "Main branch: $MAIN_BRANCH"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  warning "You have uncommitted changes. Please commit or stash them first."
  git status --short
  exit 1
fi

# Step 1: Interactive rebase to squash commits
echo ""
info "Step 1: Rebase and squash commits on feature branch"
echo ""

# Find the merge base with main
MERGE_BASE=$(git merge-base HEAD origin/$MAIN_BRANCH 2>/dev/null || git merge-base HEAD $MAIN_BRANCH)
COMMIT_COUNT=$(git rev-list --count $MERGE_BASE..HEAD)

if [ "$COMMIT_COUNT" -eq 0 ]; then
  warning "No commits to rebase. Branch is up to date with $MAIN_BRANCH."
  exit 0
elif [ "$COMMIT_COUNT" -eq 1 ]; then
  info "Only 1 commit on this branch. Skipping interactive rebase."
else
  info "Found $COMMIT_COUNT commits since branching from $MAIN_BRANCH"
  echo ""
  echo "Current commits (most recent first):"
  git log --oneline $MERGE_BASE..HEAD
  echo ""

  warning "Opening interactive rebase. Remember:"
  echo "  - Keep (pick) the first commit"
  echo "  - Squash subsequent commits into logical units"
  echo "  - Prefer a single commit unless you have discrete working changes"
  echo ""
  read -p "Press Enter to start interactive rebase (or Ctrl+C to cancel)..."

  # Start interactive rebase
  if ! git rebase -i "$MERGE_BASE"; then
    error "Interactive rebase failed. Please resolve conflicts and run 'git rebase --continue'"
  fi

  success "Commits squashed successfully"
fi

# Step 2: Fetch and pull latest main
echo ""
info "Step 2: Fetching latest $MAIN_BRANCH branch"
echo ""

if ! git fetch origin "$MAIN_BRANCH"; then
  error "Failed to fetch $MAIN_BRANCH from origin"
fi

success "Fetched latest $MAIN_BRANCH"

# Step 3: Rebase onto main
echo ""
info "Step 3: Rebasing $CURRENT_BRANCH onto $MAIN_BRANCH"
echo ""

# Check if main has new commits
BEHIND_COUNT=$(git rev-list --count HEAD..origin/$MAIN_BRANCH)
if [ "$BEHIND_COUNT" -eq 0 ]; then
  info "Already up to date with origin/$MAIN_BRANCH"
else
  info "Rebasing $BEHIND_COUNT commits from origin/$MAIN_BRANCH"

  if ! git rebase origin/"$MAIN_BRANCH"; then
    echo ""
    error "Rebase failed. Please resolve conflicts and run:
  git add .
  git rebase --continue

Then run this script again or manually push with:
  git push origin $CURRENT_BRANCH --force-with-lease"
  fi

  success "Rebased onto origin/$MAIN_BRANCH"
fi

# Step 4: Force push
echo ""
info "Step 4: Pushing changes to origin"
echo ""

# Check if remote branch exists
if git ls-remote --exit-code --heads origin "$CURRENT_BRANCH" >/dev/null 2>&1; then
  warning "This will force push to origin/$CURRENT_BRANCH"
  echo "Current local commits:"
  git log origin/"$MAIN_BRANCH"..HEAD --oneline
  echo ""
  read -p "Continue with force push? (y/N): " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    warning "Force push cancelled. You can manually push later with:"
    echo "  git push origin $CURRENT_BRANCH --force-with-lease"
    exit 0
  fi

  if ! git push origin "$CURRENT_BRANCH" --force-with-lease; then
    error "Force push failed"
  fi
else
  # First push to this branch
  if ! git push -u origin "$CURRENT_BRANCH"; then
    error "Push failed"
  fi
fi

success "Pushed to origin/$CURRENT_BRANCH"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
success "Linear history workflow completed!"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
info "Summary:"
echo "  Branch: $CURRENT_BRANCH"
echo "  Commits: $(git rev-list --count origin/$MAIN_BRANCH..HEAD)"
echo ""
echo "Final commits:"
git log origin/"$MAIN_BRANCH"..HEAD --oneline
echo ""
info "Next steps:"
echo "  1. Create a pull request: gh pr create"
echo "  2. Or continue working on your branch"
