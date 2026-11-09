---
name: python
description: Follow these guidelines for authoring or reviewing Python code.
---
## Scope
- These rules apply to code you write or touch. Don't rewrite untouched code to match them.
- Examples below use bare functions for brevity; in real code they usually belong on a class (see Functions and typing).

## Imports and layout
- Prefer imports at the top of files. Don't import modules mid-file unless there is a strong, explicit reason.
- Prefer absolute imports over relative imports.
- Avoid `from __future__ import annotations`.
- Avoid putting code in `__init__.py` files.

## Functions and typing
- Prefer cohesive classes to standalone module-level functions, and a method on the class that owns the data to a separate function that takes an instance of it.
- Use static methods sparingly for cohesive operations that genuinely need no instance or class state.

Bad (a check on a class's own data lives elsewhere):
```python
def is_expired(token: Token, now: datetime) -> bool:
  return token.expires_at <= now
```

Good (the class owns it):
```python
@dataclass(frozen=True)
class Token:
  expires_at: datetime

  def is_expired(self, now: datetime) -> bool:
    return self.expires_at <= now
```

- Always include type annotations for function inputs and outputs.
- Prefix methods with `_` when their only callers are within their own class or in tests. Tests do not make a method public. Preserve names required by inherited or framework contracts, including Python special methods.
- Never add parameters that no caller uses, even with a default value. Use default arguments only when there is a reason to.
- When adjacent parameters share the same type, use `*` to avoid callers mixing up parameter order.

Example:
```python
def build(project_id: int, *, name: str, owner: str) -> str:
  return f"{project_id}:{name}:{owner}"
```

- Inline a function whose body is a single expression: write the expression at its call sites instead of naming it. Keep it only when it is a method on the class that owns the data it reads, or its name and signature are required by an inherited or framework contract. When the same expression is needed in several places in one function, bind it to a local variable once.

Bad (a one-expression helper):
```python
def _is_adult(age: int) -> bool:
  return age >= 18

if _is_adult(age):
  ...
```

Good:
```python
if age >= 18:
  ...
```

## Data modeling
- Prefer Pydantic models or dataclasses to dictionaries in net-new code.
- When tightening existing code that already passes dicts around, a `TypedDict` is usually the right minimal step: it names the keys and types the values without changing call sites or runtime behavior.

Bad:
```python
def load(row: dict[str, Any]) -> User: ...
```

Good:
```python
class UserRow(TypedDict):
  id: int
  name: str

def load(row: UserRow) -> User: ...
```

- Prefer immutable value and configuration objects when their meaning stays fixed through a workflow.
- Keep property getters read-only and free of observable side effects: no mutation, I/O, feature-flag reads, or logging. Use explicit methods for those operations.

Bad:
```python
@property
def total(self) -> int:
  logger.info("reading total")
  return self._total
```

- Avoid classes that merely copy the same fields to label successive workflow stages. Use a separate type when it enforces a distinct invariant or representation. Do not reconstruct an unchanged value just to attach policy; reconstruction is appropriate for a value whose meaning has changed.

Bad (the stages share every field):
```python
@dataclass(frozen=True)
class RawOrder:
  id: OrderId
  total: Decimal

@dataclass(frozen=True)
class ValidatedOrder:
  id: OrderId
  total: Decimal
```

Good: one `Order`, and a second type only when it enforces something the first does not.

- Prefer distinct types over strings, including for IDs.
- Use enums for categorical data rather than strings, when the categories carry no extra data.
- Keep data about a thing on the thing itself. When items need extra attributes (a display name, a capability, an owner), make those attributes fields of a frozen dataclass. Don't keep separate dicts or sets keyed by the item elsewhere in the module. Don't reach for enum tricks either, such as a custom `__new__` that packs extra arguments into members; a plain dataclass is easier to read.

Bad (attribute kept in a separate set):
```python
class Plan(Enum):
  FREE = "free"
  PRO = "pro"

PAID_PLANS = frozenset({Plan.PRO})
```

Good (attribute is a field on each item):
```python
@dataclass(frozen=True)
class Plan:
  key: str
  paid: bool

class Plans:
  FREE = Plan("free", paid=False)
  PRO = Plan("pro", paid=True)
```

- Prefer discriminated unions for variants with different shapes: include a literal tag field and exhaustively match on it. Avoid union-typed fields (including `| None`) when the value correlates with other fields' validity or requiredness, or when code branches on it at more than one call site; a discriminated union lets exhaustive `match` catch new call sites when variants change.

Bad (correlated union fields — invalid states representable):
```python
@dataclass
class Response:
  status: Literal["ok", "error"]
  data: dict | None
  error: str | None
```

Good (discriminated union of classes):
```python
@dataclass
class Ok:
  status: Literal["ok"]
  data: dict

@dataclass
class Error:
  status: Literal["error"]
  error: str

Response = Ok | Error
```

## Control flow
- Prefer match-case over if-else chains for enums, tags and structural patterns. Use a plain `if` for a simple condition.
- Avoid nested and multi-line ternary operators (single expression if-else). Use a regular if-else statement instead.
- Use `assert_never(*)` in `case _:` statements to ensure type safety.
- To narrow a discriminated union (a `Union` of dataclasses/models tagged by a `Literal` field, per the Data modeling section), use `match`/`case` on the tag rather than `isinstance` checks — it stays exhaustive-checkable with `assert_never` and reads as one decision instead of a chain of type tests.

Bad (isinstance narrowing on a tagged union):
```python
if isinstance(shape, Circle):
  return shape.radius
```

Good (match on the tag):
```python
from typing import assert_never

match shape.kind:
  case ShapeKind.CIRCLE:
    return shape.radius
  case ShapeKind.SQUARE | ShapeKind.TRIANGLE:
    return None
  case _:
    assert_never(shape.kind)
```

- In an open class hierarchy you own (one that others may subclass), don't branch on a value's class with `isinstance` or `match` class patterns: each branch is a place a new subclass can be forgotten. Put the answer on the type instead: an abstract method or property on an `ABC` base, so a subclass that does not answer cannot be instantiated.

Bad (behavior intrinsic to the type lives in a chain outside it; a new subclass silently gets the default):
```python
def retry_delay(error: AppError) -> float:
  if isinstance(error, RateLimitedError):
    return error.retry_after
  if isinstance(error, TimeoutError_):
    return 1.0
  return 0.0
```

Good (an abstract method on the base; a subclass that does not answer cannot be instantiated):
```python
class AppError(Exception, ABC):
  @abstractmethod
  def retry_delay(self) -> float: ...

class RateLimitedError(AppError):
  def __init__(self, retry_after: float) -> None:
    self.retry_after = retry_after

  def retry_delay(self) -> float:
    return self.retry_after

class NotFoundError(AppError):
  def retry_delay(self) -> float:
    return 0.0  # retrying cannot help
```

- Give every loop in production code a fixed upper bound visible at the loop. Don't write `while True` (or a `while` whose only exit is a condition computed inside the body) for polling or draining; iterate over a bounded `range` or a finite collection, and handle running out of attempts explicitly. Retry with tenacity, not a hand-written loop. Reserve an unbounded loop for a process that is meant to run until shutdown (a worker or server loop), and say so in a comment.

Bad (the bound is hidden inside the body):
```python
while True:
  page = fetch(cursor)
  items.extend(page.items)
  if page.next_cursor is None:
    break
  cursor = page.next_cursor
```

Good (the bound is in the loop header):
```python
for _ in range(MAX_PAGES):
  page = fetch(cursor)
  items.extend(page.items)
  if page.next_cursor is None:
    return items
  cursor = page.next_cursor
return PageLimitExceeded(MAX_PAGES)
```

## Error handling
- Prefer errors as values to errors as exceptions. When failure is an expected outcome (not found, invalid input, rate limited), return a result that includes the failure, usually a discriminated union (`Found | NotFound`), instead of raising. The caller has to handle each case, and exhaustive `match` catches new failure variants.
- Reserve exceptions for bugs and unrecoverable conditions (a violated invariant, a programmer error), and let them propagate. At a boundary with code that raises (stdlib, SDKs, httpx), catch once and convert to a value; don't let those exception types spread through your code.

Bad (the caller can't see from the signature that it may fail):
```python
def find_user(user_id: UserId) -> User:
  user = db.get(user_id)
  if user is None:
    raise UserNotFoundError(user_id)
  return user
```

Good (the failure is part of the return type):
```python
@dataclass(frozen=True)
class Found:
  status: Literal["found"]
  user: User

@dataclass(frozen=True)
class NotFound:
  status: Literal["not_found"]
  user_id: UserId

def find_user(user_id: UserId) -> Found | NotFound:
  user = db.get(user_id)
  if user is None:
    return NotFound("not_found", user_id)
  return Found("found", user)

result = find_user(user_id)
match result.status:
  case "found":
    return result.user
  case "not_found":
    return None
  case _:
    assert_never(result.status)
```

## Async and concurrency
- Prefer concurrent execution over sequential awaits of independent async calls, including calls in a loop: gather the coroutines (`asyncio.gather(fetch_a(), fetch_b())` for a fixed few).

Bad (sequential in loop):
```python
results = []
for item in items:
    results.append(await fetch(item))
```

Good (concurrent):
```python
results = await asyncio.gather(*[fetch(item) for item in items])
```

## Libraries
- The preferred libraries are:
  - FastAPI for APIs
  - Typer for CLI parsing
  - Pydantic for data parsing and modeling
  - httpx for http client
  - pytest for testing
  - hypothesis for property based testing
  - tenacity for retries
- Prefer `pathlib` over `str` and `os` for path and filesystem operations.

## Patterns to avoid
- Do not rely on truthy/falsy resolution to distinguish a sentinel from a valid value. The two cases this rule covers:
  - Any union with `None` (e.g. `T | None`): compare with `is` / `is not None`, never `if x:`.
  - Any value where a falsy literal (`0`, `0.0`, `""`, `b""`, `[]`, `{}`, `False`) is a legal, meaningful value: compare to that literal explicitly.

  Truthiness on a plain `bool` or on a non-optional collection where emptiness is the question (`if items:`) is fine.

Bad (truthy check on `int | None`—conflates `0` with absent):
```python
def label(count: int | None) -> str:
  if count:
    return f"n={count}"
  return "none"
```

Good (explicit `None` check):
```python
def label(count: int | None) -> str:
  if count is not None:
    return f"n={count}"
  return "none"
```

- Avoid `getattr` and `hasattr`. Prefer explicit attributes or protocol/ABC interfaces (methods on a class hierarchy).
- Avoid `args` and `kwargs` parameters. Use specific types.
- Avoid unpacking a dict into call arguments (`f(**fields)`) when the argument list is small and known. Write the arguments out so the call site shows what is being passed. Exception: unpacking a `TypedDict` into a signature whose keyword parameters it mirrors is acceptable when tightening existing code, because the type checker checks the keys and value types against the signature.

Bad:
```python
create_user(**fields)
```

Good:
```python
create_user(name=name, owner=owner)
```

- Avoid parameter-driven branching for core behavior selection. Prefer explicit composition.

Bad (core behavior selection by flag):
```python
def do_thing(with_another_thing: bool):
  doing_the_thing()
  if with_another_thing:
    another_thing()
```

Good (explicit composition):
```python
do_thing()
another_thing()
```
