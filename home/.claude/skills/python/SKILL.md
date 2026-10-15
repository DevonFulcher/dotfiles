---
name: python
description: Follow these guidelines for authoring or reviewing Python code.
---
## Imports and layout
- Prefer imports at the top of files. Don't import modules mid-file unless there is a strong, explicit reason.
- Prefer absolute imports over relative imports.
- Avoid `from __future__ import annotations`.
- Avoid putting code in `__init__.py` files.

## Functions and typing
- Always include type annotations for function inputs and outputs.
- Never add parameters that are unused by callers to a function, even if the parameters have a default value.
- Only use default arguments when there is a reason to do so.
- When adjacent parameters share the same type, use `*` to avoid callers mixing up parameter order.

Example:
```python
def build(project_id: int, *, name: str, owner: str) -> str:
  return f"{project_id}:{name}:{owner}"
```

- Prefer methods on a class to separate module-level functions that take an instance of it, especially when the function is a relatively straightforward check or mapping over that class's own attributes. The behavior then travels with the type: callers find it by autocompletion, subclasses can override it, and a new subclass can't forget it. Keep a free function for logic that spans several unrelated types or doesn't belong to any one of them.

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

## Data modeling
- Prefer Pydantic models or dataclasses to dictionaries in net-new code.
- When tightening existing code that already passes dicts around, a `TypedDict` is
  usually the right minimal step: it names the keys and types the values without
  changing call sites or runtime behavior. Prefer it to leaving `dict[str, Any]` in
  place, and to a wholesale restructure into a model when the dict is only built,
  read, and unpacked. Reach for a dataclass or Pydantic model instead once the type
  needs behavior, validation, or invariants.
- Prefer distinct types over strings, including for IDs.
- Use enums for categorical data rather than strings, when the categories carry no extra data.
- Keep data about a thing on the thing itself. When items need extra attributes (a display name, a capability, an owner), make those attributes fields of a frozen dataclass. Don't keep separate dicts or sets keyed by the item elsewhere in the module: nothing forces anyone to update them when an item is added, so they drift. Don't reach for enum tricks either, such as a custom `__new__` that packs extra arguments into members; a plain dataclass is easier to read. If callers need to iterate over every item, give the container an explicit `all()`.

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

- Prefer discriminated unions for variants with different shapes; include a literal tag field and exhaustively match on it.
- Be pedantic with modeling types.
- Avoid union-typed fields (including `| None`) when the value correlates with other fields' validity/requiredness, or when code branches on it at more than one call site. Model it as a discriminated union of classes instead, so exhaustive `match` catches new call sites when variants change.

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
- Prefer match-case statements instead of if-else.
- Avoid nested and multi-line ternary operators (single expression if-else). Use a regular if-else statement instead.
- Use `assert_never(*)` in `case _:` statements to ensure type safety.
- To narrow a discriminated union (a `Union` of dataclasses/models tagged by a `Literal` field, per the Data modeling section), use `match`/`case` on the tag rather than `isinstance` checks — it stays exhaustive-checkable with `assert_never` and reads as one decision instead of a chain of type tests.

Example:
```python
from typing import assert_never

def to_label(kind: Kind) -> str:
  match kind:
    case Kind.FOO:
      return "foo"
    case Kind.BAR:
      return "bar"
    case _:
      assert_never(kind)
```

Bad (isinstance narrowing on a tagged union):
```python
if isinstance(shape, Circle):
  return shape.radius
```

Good (match on the tag):
```python
match shape.kind:
  case ShapeKind.CIRCLE:
    return shape.radius
  case ShapeKind.SQUARE | ShapeKind.TRIANGLE:
    return None
  case _:
    assert_never(shape.kind)
```

- In an open class hierarchy you own (one that others may subclass), don't branch on a value's class, neither with `isinstance` nor with `match` and class patterns. Each such branch is a place a new subclass can be forgotten, and they pile up as the codebase grows (a status mapper here, a message mapper there, a classifier elsewhere, all keyed on the same hierarchy). Put the answer on the type instead: an abstract method or property on an `ABC` base that every subclass must implement, so a new subclass cannot be instantiated without answering.
  - Behavior that is intrinsic to the type is an abstract method (`error.retry_delay()`).
  - A concern that belongs to another layer (HTTP status, rendering, serialization, telemetry) does not go on the domain class. Put a discriminator on the type, an abstract property returning an enum (`error.kind`), and let each layer map it with an exhaustive `match` on the enum. That is matching on a value, so it stays preferred.
- `match` on classes stays right for a closed discriminated union (a fixed set of data variants such as `Ok | Error`): the type checker proves it exhaustive, and adding an operation doesn't touch every variant. It also stays right at the boundary with types you do not own (SDK, stdlib and other third-party classes): branch on them in one place to convert them into your own type, and use that type everywhere else. Separate `except` clauses for different exception types are fine, since that is the language's own dispatch.
- Don't add inheritance only to avoid a branch; where the variants share no behavior, prefer the closed union or composition.

Bad (every new subclass must be remembered in each of these chains):
```python
def http_status(error: AppError) -> int:
  match error:
    case NotFoundError():
      return 404
    case ConflictError():
      return 409
    case _:
      return 500
```

Good (the type states its kind; the web layer maps the kind exhaustively):
```python
class ErrorKind(Enum):
  NOT_FOUND = "not_found"
  CONFLICT = "conflict"

class AppError(Exception, ABC):
  @property
  @abstractmethod
  def kind(self) -> ErrorKind: ...

class NotFoundError(AppError):
  @property
  def kind(self) -> ErrorKind:
    return ErrorKind.NOT_FOUND

def http_status(error: AppError) -> int:
  match error.kind:
    case ErrorKind.NOT_FOUND:
      return 404
    case ErrorKind.CONFLICT:
      return 409
    case _:
      assert_never(error.kind)
```

- Give every loop in production code a fixed upper bound visible at the loop. Don't write `while True` (or a `while` whose only exit is a condition computed inside the body) for retries, polling or draining; iterate over a bounded `range` or a finite collection, and handle running out of attempts explicitly. Reserve an unbounded loop for a process that is meant to run until shutdown (a worker or server loop), and say so in a comment.

Bad (the bound is hidden inside the body):
```python
attempt = 0
while True:
  try:
    return call()
  except TransientError:
    if attempt >= policy.max_retries:
      raise
    attempt += 1
```

Good (the bound is in the loop header):
```python
for attempt in range(MAX_RETRIES):
  try:
    return call()
  except TransientError:
    wait(attempt)
return call()
```

## Async and concurrency
- Prefer concurrent execution over sequential calls when awaiting multiple independent async functions.

Bad (sequential):
```python
result_a = await fetch_a()
result_b = await fetch_b()
```

Good (concurrent):
```python
result_a, result_b = await asyncio.gather(fetch_a(), fetch_b())
```

- Avoid awaiting inside loops; gather coroutines and await them concurrently.

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

  Implicit truthiness on these types can silently change meaning without a type error when the schema, annotation, or upstream API evolves (e.g. a field gains `0` as a valid value, or a required field becomes optional). Truthiness on a plain `bool` or on a non-optional collection where emptiness is the question (`if items:`) is fine.

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
- Avoid unpacking a dict into call arguments (`f(**fields)`) when the argument list is
  small and known. Write the arguments out so the call site shows what is being
  passed. Exception: unpacking a `TypedDict` into a signature whose keyword
  parameters it mirrors is acceptable when tightening existing code, because mypy
  checks the keys and value types against the signature.
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
