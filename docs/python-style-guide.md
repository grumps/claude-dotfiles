# Python Code Style Guide

This document defines Python coding standards for projects using Claude dotfiles. All Python code should follow these guidelines for consistency and maintainability.

## Philosophy

- **Readability over cleverness** - Code is read more often than written
- **Explicit over implicit** - Be clear about intent and data flow
- **Simple over complex** - Prefer for loops over comprehensions, named functions over lambdas
- **Functions over classes** - Use module-level functions unless you need state or data modeling
- **Fail fast** - Catch errors early, raise exceptions for unexpected conditions
- **Consistency** - Follow existing patterns in the codebase

### Core Principles

1. **No lambdas** - Always use named functions or explicit loops
2. **Limited comprehensions** - Only for simple cases; prefer readable for loops
3. **Pragmatic classes** - Use `@dataclass` for data, classes for state/inheritance only
4. **Avoid decorators like `@staticmethod`** - Use module functions instead
5. **Type everything** - All functions must have complete type hints
6. **Describe everything** - All public functions need docstrings

---

## Line Length & Formatting

- **Maximum line length:** 100 characters
- **Formatter:** Use `ruff format` (configured in `pyproject.toml`)
- **String quotes:** Single quotes (`'`) preferred
  - Use double quotes only for strings containing single quotes
  - Triple-quoted strings for docstrings and multi-line text

```python
# ✅ Good
message = 'Processing payment'
query = "SELECT * FROM payments WHERE client = 'John'"
description = '''
    Multi-line description
    goes here
'''

# ❌ Avoid
message = "Processing payment"  # Unnecessary double quotes
```

---

## Imports

- **Organization:** Automatic via `ruff` (isort-compatible)
- **Expected order:**
  1. Standard library imports
  2. Third-party imports
  3. Local/application imports
- **Style:** One import per line for `from` imports when multiple items

```python
# ✅ Good (ruff will organize automatically)
import json
import shutil
from pathlib import Path
from decimal import Decimal

import pytest
import duckdb

from src.myapp.schema import initialize_database
from tests.helpers import setup_scenario

# ❌ Avoid
from pathlib import Path
import json  # Wrong order
from src.myapp.schema import *  # Wildcard imports
```

---

## Type Hints

- **Required:** All functions must have type hints for parameters and return values
- **Use modern syntax:** `list[str]` over `List[str]` (Python 3.9+)
- **Be specific:** Use appropriate types (e.g., `Decimal` for money, `Path` for file paths)

```python
# ✅ Good
def calculate_total(
    items: list[dict[str, int]],
    discount: Decimal
) -> Decimal:
    '''Calculate total with discount applied.'''
    subtotal = sum(item['price'] for item in items)
    return subtotal * (1 - discount)

def process_files(
    input_path: str | Path,
    file_ids: list[str]
) -> dict[str, bool]:
    '''Process files and return success status by ID.'''
    ...

# ❌ Avoid
def calculate_total(items, discount):  # Missing type hints
    ...

def process_files(input_path, file_ids):  # Missing type hints
    return {}  # Missing return type hint
```

---

## Code Organization

- **Prefer functions over classes** - Use module-level functions when no state is needed
- **Classes for specific purposes:**
  - Data modeling (use `@dataclass`)
  - Stateful operations (maintains state across calls)
  - Clear inheritance relationships (is-a relationships only)
- **Avoid utility classes** - Use module-level functions instead of classes with only static methods

```python
# ✅ Good - module-level functions
def calculate_tax(amount: Decimal, rate: Decimal) -> Decimal:
    '''Calculate tax from amount and rate.'''
    return amount * rate

def get_tax_rate(state: str) -> Decimal:
    '''Get tax rate for given state.'''
    rates = {'CA': Decimal('0.0725'), 'NY': Decimal('0.08')}
    return rates.get(state, Decimal('0.0'))

# ❌ Avoid - unnecessary class wrapper
class TaxCalculator:  # No state, no reason for class
    @staticmethod
    def calculate(amount: Decimal, rate: Decimal) -> Decimal:
        return amount * rate
```

**When to use classes:**

```python
# ✅ Good - data modeling with dataclass
from dataclasses import dataclass
from decimal import Decimal

@dataclass
class Invoice:
    '''Represents an invoice with line items.'''
    customer: str
    items: list[str]
    subtotal: Decimal
    tax: Decimal
    total: Decimal

# ✅ Good - stateful operation
class DatabaseConnection:
    '''Manages database connection lifecycle.'''

    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = None

    def connect(self) -> None:
        '''Establish database connection.'''
        self.conn = duckdb.connect(self.db_path)

    def close(self) -> None:
        '''Close database connection.'''
        if self.conn:
            self.conn.close()
```

---

## Naming Conventions

- **Variables/Functions:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE` at module level
- **Classes:** `PascalCase`
- **Private/Internal:** Prefix with `_single_underscore`

**Prefer descriptive names over brevity:**

```python
# ✅ Good
calculate_tax_for_invoice()
total_processed_amount
STRIPE_PROCESSING_FEE_PERCENTAGE

# ❌ Avoid
calc_tax()           # Abbreviation unclear
tot_proc_amt         # Hard to parse
STRIPE_FEE_PCT       # Abbreviate words sparingly
```

**Exception:** Single-letter variables OK in limited scope:

```python
# ✅ OK for loops/comprehensions
for i in range(10):
    ...

payments = {k: v for k, v in data.items() if v > 0}

# ❌ Avoid in broader scope
def process(x, y, z):  # What are these?
    ...
```

---

## Loops, Comprehensions & Lambdas

- **Avoid lambdas** - Use named functions or explicit loops instead
- **Limit list comprehensions** - Use only for simple transformations
- **Prefer explicit for loops** - Readability over brevity

```python
# ✅ Good - explicit for loop
active_items = []
for item in all_items:
    if item.status == 'active' and item.amount > 0:
        active_items.append(item)

# ✅ Good - simple comprehension (acceptable)
item_ids = [i.id for i in items]

# ✅ Good - named function
def is_active_item(item: Item) -> bool:
    '''Check if item is active and has positive amount.'''
    return item.status == 'active' and item.amount > 0

active_items = [i for i in all_items if is_active_item(i)]

# ❌ Avoid - lambda
sorted_items = sorted(items, key=lambda i: i.amount)

# ✅ Better - named function
def get_item_amount(item: Item) -> Decimal:
    '''Extract item amount for sorting.'''
    return item.amount

sorted_items = sorted(items, key=get_item_amount)

# ❌ Avoid - complex comprehension
result = {k: sum(v.amount for v in vals if v.status == 'active')
          for k, vals in data.items() if any(v.status == 'active' for v in vals)}

# ✅ Better - explicit loop
result = {}
for key, items in data.items():
    active_items = [i for i in items if i.status == 'active']
    if active_items:
        total = sum(i.amount for i in active_items)
        result[key] = total
```

---

## Function Length

- **Target:** ≤100 lines per function
- **Guideline:** If function is hard to follow or does multiple unrelated things, split it
- **Extract logic:** Create helper functions for complex operations

```python
# ✅ Good - focused, under 100 lines
def process_invoice(
    customer: str,
    items: list[Item],
    db_path: str
) -> dict[str, Decimal]:
    '''Process invoice and return totals.'''
    conn = duckdb.connect(db_path)

    subtotal = _calculate_subtotal(items)
    tax = _calculate_tax(subtotal, customer)

    return {
        'subtotal': subtotal,
        'tax': tax,
        'total': subtotal + tax
    }

def _calculate_subtotal(items: list[Item]) -> Decimal:
    '''Calculate subtotal from items (extracted helper).'''
    return sum(item.price * item.quantity for item in items)

def _calculate_tax(amount: Decimal, customer: str) -> Decimal:
    '''Calculate tax based on customer location (extracted helper).'''
    ...
```

---

## Docstrings

- **Style:** Google/NumPy style docstrings
- **Required for:** All public functions, classes, and modules
- **Include:** Args, Returns, Raises (when applicable)

```python
def calculate_average(values: list[float], min_count: int = 1) -> float:
    '''Calculate average of values with minimum count validation.

    Computes the arithmetic mean of the provided values. Raises an
    error if fewer than min_count values are provided.

    Args:
        values: List of numeric values to average
        min_count: Minimum number of values required (default: 1)

    Returns:
        The arithmetic mean as a float

    Raises:
        ValueError: If values list has fewer than min_count items
        ZeroDivisionError: If values list is empty

    Example:
        >>> calculate_average([10, 20, 30])
        20.0
        >>> calculate_average([5], min_count=2)
        ValueError: Need at least 2 values
    '''
    if len(values) < min_count:
        raise ValueError(f'Need at least {min_count} values')

    return sum(values) / len(values)
```

---

## Comments

- **When to comment:**
  - Document complex logic that isn't immediately obvious
  - Explain business rules and domain-specific calculations
  - Note important constraints or edge cases
  - Reference external documentation or decisions

- **Don't comment:**
  - What the code does (if code is clear)
  - Obvious operations
  - Commented-out code (delete it, use git history)

```python
# ✅ Good - explains WHY and business context
# Use 7-day window for lookups because charges can be delayed
# See FIXES.md Issue #7 - some charges delayed 27 days
lookup_window_days = 7

# Calculate average using CALENDAR days, not business days
# This matches the tier boundaries defined in agreements
average = (count * 7) / calendar_days

# ❌ Avoid - comments what code already shows
# Loop through items
for item in items:
    # Add to total
    total += item
```

---

## Class Features (Use Sparingly)

- **`@staticmethod`** - Use only when truly needed (rare - usually just use module function)
- **`@classmethod`** - Use for alternative constructors or factory methods
- **`@abstractmethod`** - Use only when building clear inheritance hierarchies (rare)
- **Inheritance** - Use only for clear "is-a" relationships, favor composition

```python
# ✅ Good - classmethod for alternative constructor
@dataclass
class DateRange:
    start: str
    end: str

    @classmethod
    def from_datetime(cls, start: datetime, end: datetime) -> 'DateRange':
        '''Create DateRange from datetime objects.'''
        return cls(
            start=start.strftime('%Y-%m-%d'),
            end=end.strftime('%Y-%m-%d')
        )

# ❌ Avoid - unnecessary staticmethod (use module function instead)
class MathUtils:
    @staticmethod
    def add(a: int, b: int) -> int:
        return a + b

# ✅ Better - module-level function
def add(a: int, b: int) -> int:
    '''Add two numbers.'''
    return a + b

# ❌ Avoid - abstract base class for simple case
from abc import ABC, abstractmethod

class Processor(ABC):
    @abstractmethod
    def process(self, data: dict) -> bool:
        pass

# ✅ Better - just use Protocol for type hints if needed
from typing import Protocol

class Processor(Protocol):
    def process(self, data: dict) -> bool:
        '''Process data and return success status.'''
        ...
```

---

## Error Handling

- **Philosophy:** Fail fast with exceptions
- **Don't catch exceptions** unless you can handle them meaningfully
- **Be specific:** Raise specific exception types (`ValueError`, `FileNotFoundError`, etc.)
- **Validate early:** Check inputs at function boundaries

```python
# ✅ Good
def save_report(data: dict, output_path: str) -> None:
    '''Save report to file.

    Raises:
        ValueError: If data is empty
        FileNotFoundError: If output directory doesn't exist
        PermissionError: If cannot write to output path
    '''
    if not data:
        raise ValueError('Cannot save empty report')

    output = Path(output_path)
    if not output.parent.exists():
        raise FileNotFoundError(f'Directory does not exist: {output.parent}')

    # Proceed with saving...

# ❌ Avoid
def save_report(data, output_path):
    try:
        # Do everything in try block
        ...
    except Exception as e:
        print(f'Error: {e}')  # Swallow exception
        return None
```

---

## Constants & Configuration

### Module-Level Constants

- **Use SCREAMING_SNAKE_CASE** for true constants
- **Define at top of module** after imports
- **Group related constants** with blank lines

```python
# ✅ Good
import json
from decimal import Decimal
from pathlib import Path

# Processing thresholds
MIN_PROCESSING_AMOUNT = Decimal('1.00')
MAX_PROCESSING_AMOUNT = Decimal('10000.00')
BATCH_SIZE = 100

# API configuration
API_BASE_URL = 'https://api.example.com'
API_TIMEOUT_SECONDS = 30
API_RETRY_COUNT = 3

# File paths
DEFAULT_DATA_DIR = Path('data')
DEFAULT_OUTPUT_DIR = Path('output')
```

---

## Testing Style

### Test Naming

- **Use descriptive names** that explain the scenario and expected behavior
- **Format:** `test_<action>_<scenario>_<expected_result>`

```python
# ✅ Good
def test_calculate_total_with_discount_returns_reduced_amount():
    ...

def test_process_invoice_with_invalid_items_raises_value_error():
    ...

def test_save_report_with_empty_data_raises_value_error():
    ...

# ❌ Avoid
def test_total():
    ...

def test_case_1():
    ...
```

### Test Structure

- **Use Arrange-Act-Assert pattern** with clear sections
- **Use fixtures** over setUp methods (pytest style)
- **Keep tests focused** - verify one behavior per test

```python
# ✅ Good
def test_calculate_total_with_multiple_items(sample_items):
    '''Test total calculation with multiple items at different prices.'''
    # Arrange
    items = [
        {'name': 'Item A', 'price': 10, 'quantity': 2},
        {'name': 'Item B', 'price': 15, 'quantity': 1}
    ]
    expected_total = Decimal('35.00')

    # Act
    result = calculate_total(items)

    # Assert
    assert result == expected_total, \
        f'Expected {expected_total}, got {result}'
```

### Test Fixtures

- **Use pytest fixtures** defined in `conftest.py`
- **Scope appropriately:** function scope for most, module/session for expensive setup
- **Name clearly:** `sample_db`, `test_data`, `temp_file`

```python
# In tests/conftest.py
@pytest.fixture
def sample_db(tmp_path):
    '''Create a sample database for testing.'''
    db_path = tmp_path / 'test.db'
    conn = create_connection(str(db_path))
    initialize_schema(conn)
    conn.close()
    return str(db_path)

# In tests/test_module.py
def test_query_data(sample_db):  # Fixture injected automatically
    result = query_database(sample_db, 'SELECT * FROM items')
    assert len(result) == 0
```

---

## Tool Configuration

### Ruff (Linter & Formatter)

Configure in `pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.format]
quote-style = "single"
indent-style = "space"

[tool.ruff.lint]
select = ["E", "F", "I"]  # pycodestyle errors, pyflakes, isort
ignore = []
```

### Running Checks

```bash
# Format code
just py-fmt

# Lint code
just py-lint

# Type check
just py-typecheck

# Run tests
just py-test

# Run all checks
just py-check
```

---

## Code Review Checklist

Before submitting code, verify:

- [ ] All functions have type hints
- [ ] All public functions have docstrings (Google/NumPy style)
- [ ] Line length ≤100 characters
- [ ] No lambdas - use named functions or explicit loops
- [ ] List comprehensions only for simple cases - prefer for loops
- [ ] Classes used only for data modeling, state, or clear inheritance
- [ ] No `@staticmethod` - use module functions instead
- [ ] `@classmethod`, `@abstractmethod` used sparingly and appropriately
- [ ] Error handling raises specific exceptions
- [ ] Tests follow Arrange-Act-Assert pattern
- [ ] Test names are descriptive
- [ ] No abbreviations in variable/function names (unless common)
- [ ] Complex logic has explanatory comments
- [ ] `just py-lint` passes
- [ ] All tests pass (`just py-test`)

---

## When in Doubt

1. **Check existing code** - follow patterns already in the codebase
2. **Run the tools** - `ruff` will catch most style issues
3. **Ask questions** - unclear requirements should be clarified
4. **Prioritize readability** - if choice between clever and clear, choose clear

---

**Last Updated:** 2025-11-16
**Maintained by:** Project maintainers
