1. Run `git status` to understand the current state.
2. Use the `git status` output to identify the relevant changed files, then read those files directly.
  - Do **not** run `git diff` unless explicitly requested.
3. Determine a concise, high-signal commit message focused on **why** the change was made.
4. Stage, commit, and push with the custom git command: `git save --message "<message>" --yes`
5. Do **not** run a final `git status` after the commit unless there's an error to diagnose.
