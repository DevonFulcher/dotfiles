## Focus

- Keep code changes focused on the task at hand. Do long update pre-existing code unnecessarily without instructions from the user.
- Make updates minimal. Changing code can have many downstream unintended consequences. So, make only the changes that are necessary.

## Style

- Prefer composition over inheritance.
- Avoid overly broad or ambiguous file and directory names like `utils` or `types`.
- For greenfield code, prefer simple code over graceful degradation. Let errors propagate rather than preemptively handling failure modes you haven't actually encountered.
