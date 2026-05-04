---
name: testing
description: Instructions for writing tests.
---

## Prefer dependency injection over mocks

Avoid mocks and patching functions. Prefer dependency injection and fakes.

**Avoid** (patch the import site; brittle, asserts on call shape):

```python
from unittest.mock import patch, MagicMock

@patch("myapp.service.smtplib.SMTP")
def test_send_welcome_email(mock_smtp):
    mock_server = MagicMock()
    mock_smtp.return_value = mock_server
    send_welcome_email("a@b.com")
    mock_server.sendmail.assert_called_once()
```

**Prefer** (inject a port; test with a small fake, no `patch`):

```python
from typing import Protocol

class EmailSender(Protocol):
    def send_welcome(self, to: str) -> None: ...

def send_welcome_email(user_email: str, sender: EmailSender) -> None:
    sender.send_welcome(user_email)

# test
class FakeEmailSender:
    def __init__(self) -> None:
        self.sent: list[str] = []
    def send_welcome(self, to: str) -> None:
        self.sent.append(to)

def test_send_welcome_email() -> None:
    fake = FakeEmailSender()
    send_welcome_email("a@b.com", sender=fake)
    assert fake.sent == ["a@b.com"]
```

## Update tests, not source, when tests fail

To resolve test failures, type errors, and lint errors in tests, prefer updating the test rather than the source code. The source reflects the intended new behavior; the test encodes the old contract and is usually what's stale. Exception: if the failure reveals a genuine bug in the source (wrong output, regression, broken invariant), fix the source.
