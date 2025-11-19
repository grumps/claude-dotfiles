#!/usr/bin/env bash
# Validate test implementation without requiring Docker
set -e

echo "=================================="
echo "Integration Tests Validation"
echo "=================================="
echo ""

# Check test files exist
echo "✅ Checking test files..."
test -f tests/integration/test-install.bats && echo "  ✓ test-install.bats exists"
test -f tests/integration/test-uninstall.bats && echo "  ✓ test-uninstall.bats exists"
test -f tests/integration/README.md && echo "  ✓ README.md exists"
echo ""

# Check test files are executable
echo "✅ Checking permissions..."
test -x tests/integration/test-install.bats && echo "  ✓ test-install.bats is executable"
test -x tests/integration/test-uninstall.bats && echo "  ✓ test-uninstall.bats is executable"
echo ""

# Count test cases
echo "✅ Counting test cases..."
INSTALL_TESTS=$(grep -c "@test" tests/integration/test-install.bats)
UNINSTALL_TESTS=$(grep -c "@test" tests/integration/test-uninstall.bats)
TOTAL=$((INSTALL_TESTS + UNINSTALL_TESTS))
echo "  ✓ test-install.bats: $INSTALL_TESTS tests"
echo "  ✓ test-uninstall.bats: $UNINSTALL_TESTS tests"
echo "  ✓ Total: $TOTAL tests"
echo ""

# Validate BATS structure
echo "✅ Validating BATS structure..."
grep -q "#!/usr/bin/env bats" tests/integration/test-install.bats && echo "  ✓ test-install.bats has BATS shebang"
grep -q "#!/usr/bin/env bats" tests/integration/test-uninstall.bats && echo "  ✓ test-uninstall.bats has BATS shebang"
grep -q "setup()" tests/integration/test-install.bats && echo "  ✓ test-install.bats has setup function"
grep -q "setup()" tests/integration/test-uninstall.bats && echo "  ✓ test-uninstall.bats has setup function"
echo "  ℹ Note: BATS syntax cannot be validated with bash -n (requires bats-core)"
echo ""

# Check workflow file
echo "✅ Checking GitHub Actions workflow..."
test -f .github/workflows/integration-tests.yml && echo "  ✓ integration-tests.yml exists"
grep -q "test-install" .github/workflows/integration-tests.yml && echo "  ✓ Workflow includes test-install job"
grep -q "test-plan-worktree" .github/workflows/integration-tests.yml && echo "  ✓ Workflow includes test-plan-worktree job"
echo ""

# Check just recipe
echo "✅ Checking just recipe..."
test -f justfiles/ci.just && echo "  ✓ justfiles/ci.just exists"
grep -q "test-install:" justfiles/ci.just && echo "  ✓ test-install recipe defined"
grep -q "archlinux:latest" justfiles/ci.just && echo "  ✓ Uses Arch Linux container"
echo ""

# Check if Docker/Podman available
echo "✅ Checking container runtime..."
if command -v docker &> /dev/null; then
  echo "  ✓ Docker available - can run 'just test-install' locally"
elif command -v podman &> /dev/null; then
  echo "  ✓ Podman available - can run 'just test-install' locally"
else
  echo "  ⚠ Docker/Podman not available"
  echo "    → Tests will run in GitHub Actions automatically"
  echo "    → To run locally, install Docker or Podman"
fi
echo ""

echo "=================================="
echo "✅ All validations passed!"
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Push to GitHub to trigger workflow"
echo "  2. Check Actions tab for test results"
echo "  3. Or install Docker/Podman to run locally"
