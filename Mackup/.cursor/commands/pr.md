1. Run unit tests via `toolbelt unit` and ensure they pass.
2. Run `git-town branch` to know the base branch.
3. Ensure you are on a branch (not `main`/`master`). If you are on `main`/`master`, create and switch to a new branch with a sensible name prefixed with `devon/` (snake-case is preferred):

```shell
branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  git switch -c "devon/<short-description>"
fi
```

4. Ensure all changes are committed (working tree must be clean):

```shell
git status --porcelain
```

If there is any output, run the commit process:
1. Run `git status` to understand the current state.
2. Use `git diff` (and open files only as needed) to understand the change(s).
  - Do **not** run `git log` unless explicitly requested.
3. Determine a concise, plain commit message (no prefixes like `docs(...)`) focused on **why** the change was made.
4. Run `git save --message "<message>" --yes` which will add all changes, commit, and push.

5. Craft a thorough title & description. Use `git diff` when necessary. Create a PR using `gh`:

```shell
gh pr create --title "<pr title>" --body "<description>" --base "<base branch>"
```

6. Open the PR with `open <url>`.