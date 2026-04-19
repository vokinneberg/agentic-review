---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Coding Style

## Standards

- Follow **PEP 8** conventions
- Use **type annotations** on all function signatures

## Functional Style First

Prefer **functions over classes**. Reach for OOP only when state management or polymorphism genuinely warrants it.

### Prefer pure functions

```python
# Good
def calculate_fee(price: float, rate: float) -> float:
    return price * rate

# Avoid — unnecessary class wrapper
class FeeCalculator:
    def calculate(self, price: float, rate: float) -> float:
        return price * rate
```

### Use module-level functions, not static methods

```python
# Good — plain functions in a module
def parse_record(raw: dict[str, Any]) -> Record: ...
def validate_record(record: Record) -> bool: ...

# Avoid — static methods with no state
class RecordUtils:
    @staticmethod
    def parse(raw: dict[str, Any]) -> Record: ...
```

### Compose with higher-order functions

```python
from collections.abc import Callable, Iterable
from typing import TypeVar

T = TypeVar("T")
U = TypeVar("U")

def pipe(*fns: Callable) -> Callable:
    """Left-to-right function composition."""
    from functools import reduce
    return reduce(lambda f, g: lambda x: g(f(x)), fns)

# Usage
process = pipe(parse_record, validate_record, enrich_record)
result = process(raw_data)
```

### Prefer `map` / `filter` / `functools` over imperative loops

```python
from functools import reduce

totals = list(map(lambda r: r.price * r.qty, records))
valid  = list(filter(lambda r: r.price > 0, records))
total  = reduce(lambda acc, r: acc + r.price, records, 0.0)
```

### Use list/dict/generator comprehensions

```python
# Good
prices = [r.price for r in records if r.active]
index  = {r.symbol: r for r in records}
stream = (parse(line) for line in file)  # lazy

# Avoid — manual append loops
prices = []
for r in records:
    if r.active:
        prices.append(r.price)
```

## Immutability

Prefer immutable data structures. Use `NamedTuple` for lightweight value objects; use frozen `dataclass` only when field defaults or methods are needed.

```python
from typing import NamedTuple

class Record(NamedTuple):
    symbol: str
    price: float
    volume: int

from dataclasses import dataclass

@dataclass(frozen=True)
class FeedConfig:
    source: str
    interval_seconds: int = 60
```

Avoid mutating arguments inside functions — return new values instead:

```python
# Good
def with_price(record: Record, price: float) -> Record:
    return record._replace(price=price)

# Avoid
def update_price(record: Record, price: float) -> None:
    record.price = price  # mutation
```

## Classes — When to Use Them

Use a class only when you need to:

- Encapsulate **mutable state** that evolves over time (e.g., a connection pool, a stateful parser)
- Implement a **protocol / interface** required by a framework
- Group **configuration + behaviour** that genuinely belong together (e.g., a `DataSource` with `connect`/`fetch`/`close`)

When you do write a class, keep it small and focused. Prefer composition over inheritance.

## Type Annotations

Annotate every function signature. Use the built-in generics (`list`, `dict`, `tuple`) over `typing.List` etc. (Python 3.9+).

```python
def fetch_records(symbols: list[str], limit: int = 100) -> list[Record]:
    ...

def group_by_symbol(records: list[Record]) -> dict[str, list[Record]]:
    ...
```

Use `TypeAlias` for complex repeated types:

```python
from typing import TypeAlias

SymbolMap: TypeAlias = dict[str, list[Record]]
```

## Error Handling

Return errors as values where practical; avoid raising exceptions for expected failure paths.

```python
from typing import Union

def parse_price(raw: str) -> float | None:
    try:
        return float(raw)
    except ValueError:
        return None
```

For richer error information use a `Result`-style pattern:

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E")

@dataclass(frozen=True)
class Ok(Generic[T]):
    value: T

@dataclass(frozen=True)
class Err(Generic[E]):
    error: E

Result = Ok[T] | Err[E]
```

## Formatting

- **black** for code formatting
- **isort** for import sorting
- **ruff** for linting
