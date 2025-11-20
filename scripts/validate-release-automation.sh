#!/usr/bin/env bash
# Validation script for release automation
# Tests what can be validated without installing git-cliff and gh CLI

set -euo pipefail

echo "🔍 Validating Release Automation Setup"
echo "======================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Helper functions
pass() {
  echo -e "${GREEN}✅ PASS${NC}: $1"
}

fail() {
  echo -e "${RED}❌ FAIL${NC}: $1"
  ((ERRORS++))
}

warn() {
  echo -e "${YELLOW}⚠️  WARN${NC}: $1"
  ((WARNINGS++))
}

info() {
  echo -e "ℹ️  INFO: $1"
}

# Test 1: Check required files exist
echo "Test 1: Checking required files..."
if [[ -f "justfiles/ci.just" ]]; then
  pass "justfiles/ci.just exists"
else
  fail "justfiles/ci.just not found"
fi

if [[ -f "cliff.toml" ]]; then
  pass "cliff.toml exists"
else
  fail "cliff.toml not found"
fi

if [[ -f ".github/workflows/release.yml" ]]; then
  pass ".github/workflows/release.yml exists"
else
  fail ".github/workflows/release.yml not found"
fi

if [[ -f "docs/release-automation-testing.md" ]]; then
  pass "docs/release-automation-testing.md exists"
else
  warn "docs/release-automation-testing.md not found (documentation)"
fi

echo ""

# Test 2: Check justfile imports ci.just
echo "Test 2: Checking justfile configuration..."
if [[ -f "justfile" ]]; then
  if grep -q "import.*ci.just" justfile; then
    pass "justfile imports ci.just"
  else
    fail "justfile does not import ci.just"
  fi
else
  fail "justfile not found"
fi

echo ""

# Test 3: Check release recipes exist in ci.just
echo "Test 3: Checking release recipes in ci.just..."
REQUIRED_RECIPES=("changelog" "release-notes" "github-release" "release")

for recipe in "${REQUIRED_RECIPES[@]}"; do
  if grep -q "^${recipe}.*:" justfiles/ci.just; then
    pass "Recipe '${recipe}' found"
  else
    fail "Recipe '${recipe}' not found"
  fi
done

echo ""

# Test 4: Validate cliff.toml structure
echo "Test 4: Validating cliff.toml configuration..."
if grep -q "\[changelog\]" cliff.toml; then
  pass "cliff.toml has [changelog] section"
else
  fail "cliff.toml missing [changelog] section"
fi

if grep -q "\[git\]" cliff.toml; then
  pass "cliff.toml has [git] section"
else
  fail "cliff.toml missing [git] section"
fi

if grep -q "conventional_commits = true" cliff.toml; then
  pass "cliff.toml enables conventional commits"
else
  fail "cliff.toml does not enable conventional commits"
fi

# Check for conventional commit parsers
COMMIT_TYPES=("feat" "fix" "docs" "chore" "refactor" "test")
for type in "${COMMIT_TYPES[@]}"; do
  if grep -q "\"^${type}\"" cliff.toml; then
    pass "cliff.toml parses '${type}' commits"
  else
    warn "cliff.toml may not parse '${type}' commits"
  fi
done

echo ""

# Test 5: Validate GitHub Actions workflow
echo "Test 5: Validating GitHub Actions workflow..."
if grep -q "push:" .github/workflows/release.yml; then
  pass "Workflow has push trigger"
else
  fail "Workflow missing push trigger"
fi

if grep -q "tags:" .github/workflows/release.yml; then
  pass "Workflow triggers on tags"
else
  fail "Workflow does not trigger on tags"
fi

if grep -q "git-cliff" .github/workflows/release.yml; then
  pass "Workflow installs git-cliff"
else
  fail "Workflow does not install git-cliff"
fi

if grep -q "just.*release" .github/workflows/release.yml; then
  pass "Workflow uses just recipes"
else
  fail "Workflow does not use just recipes"
fi

if grep -q "GITHUB_TOKEN" .github/workflows/release.yml; then
  pass "Workflow uses GITHUB_TOKEN"
else
  fail "Workflow missing GITHUB_TOKEN"
fi

echo ""

# Test 6: Check tag format validation in recipes
echo "Test 6: Checking tag format validation..."
if grep -q 'v\[0-9\]' justfiles/ci.just; then
  pass "Tag format validation regex found"
else
  fail "Tag format validation not found"
fi

if grep -q "Invalid tag format" justfiles/ci.just; then
  pass "Tag format error message found"
else
  warn "Tag format error message not found"
fi

echo ""

# Test 7: Check release assets configuration
echo "Test 7: Checking release assets..."
if [[ -f "install.sh" ]]; then
  pass "install.sh exists (will be attached to release)"
else
  fail "install.sh not found"
fi

if [[ -f "uninstall.sh" ]]; then
  pass "uninstall.sh exists (will be attached to release)"
else
  fail "uninstall.sh not found"
fi

if grep -q "install.sh uninstall.sh" justfiles/ci.just; then
  pass "Release recipe attaches install.sh and uninstall.sh"
else
  warn "Release recipe may not attach install scripts"
fi

echo ""

# Test 8: Check tool dependencies (warnings only)
echo "Test 8: Checking tool dependencies (informational)..."
if command -v git-cliff &>/dev/null; then
  pass "git-cliff is installed ($(git-cliff --version 2>&1 | head -1))"
else
  warn "git-cliff not installed (required for local testing)"
  info "Install: https://git-cliff.org/docs/installation"
fi

if command -v gh &>/dev/null; then
  pass "gh CLI is installed ($(gh --version 2>&1 | head -1))"
else
  warn "gh CLI not installed (required for github-release recipe)"
  info "Install: https://cli.github.com/"
fi

if command -v just &>/dev/null; then
  pass "just is installed ($(just --version 2>&1))"
else
  warn "just not installed (required to run recipes)"
  info "Install: https://just.systems/"
fi

echo ""

# Test 9: Check documentation
echo "Test 9: Checking documentation..."
if [[ -f "docs/release-automation-testing.md" ]]; then
  if grep -q "Local Testing Workflows" docs/release-automation-testing.md; then
    pass "Testing documentation has local workflows section"
  else
    warn "Testing documentation may be incomplete"
  fi

  if grep -q "Argo-Compatible" docs/release-automation-testing.md; then
    pass "Documentation mentions Argo compatibility"
  else
    warn "Documentation does not mention Argo compatibility"
  fi
fi

echo ""

# Summary
echo "======================================="
echo "Validation Summary"
echo "======================================="

if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}✅ All critical checks passed!${NC}"
else
  echo -e "${RED}❌ $ERRORS error(s) found${NC}"
fi

if [[ $WARNINGS -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found${NC}"
fi

echo ""

if [[ $ERRORS -eq 0 ]]; then
  echo "Next steps:"
  echo "1. Install required tools (git-cliff, gh, just)"
  echo "2. Run: just changelog"
  echo "3. Run: just release-notes v0.0.1-test"
  echo "4. See docs/release-automation-testing.md for full testing guide"
  echo ""
  echo -e "${GREEN}Release automation is ready for testing!${NC}"
  exit 0
else
  echo "Please fix the errors above before proceeding."
  exit 1
fi
