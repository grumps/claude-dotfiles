# Python-specific recipes

# Run Python linters
py-lint:
  ruff check .

# Run Python formatter
py-fmt:
  ruff format .

# Run Python tests
py-test:
  pytest -v

# Run Python tests with coverage
py-test-coverage:
  pytest -v --cov --cov-report=html
  @echo "Coverage report: htmlcov/index.html"

# Type checking with mypy
py-typecheck:
  mypy .

# Run all Python checks
py-check: py-lint py-typecheck py-test
