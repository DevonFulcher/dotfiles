1. Run `git status` to understand the current state.
2. Use the `git status` output to identify the relevant changed files, then read **only what’s needed** to draft an accurate commit message (not necessarily every changed file).
  - Do **not** run `git diff` unless explicitly requested.
  - Do **not** run `git log` unless explicitly requested.
3. Determine a concise, high-signal commit message focused on **why** the change was made.
4. Stage, commit, and push with the custom git command: `git save --message "<message>" --yes`
