Create or update `AGENTS.md` so AI coding agents can work effectively in this repo.

This command should sync the docs based on **(a)** the current repo state + **git diff**, and **(b)** any relevant constraints or decisions from the **conversation history**.

## Goals
- Prioritize **correctness** over brevity (accurate and verifiable from repo sources; not exhaustive or speculative)
- Keep instructions **concrete and runnable**
- Prefer **links** to existing docs over duplicating long content
- Support **nested** `AGENTS.md` files for subdirectories that have distinct workflows
- Include implementation details when needed for correctness; omit unnecessary detail

## Inputs to Use

### Existing repository state
Use the current repo state to bootstrap or validate `AGENTS.md` content:
- Existing `AGENTS.md` files (root and any nested)
- Closest `README.md` / `CONTRIBUTING.md`
- Package manifests and task runners (e.g., `package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `justfile`, `Taskfile.yml`)
- CI/CD configs (e.g., `.github/*`)
- Scripts directories and entrypoints referenced by docs (e.g., `scripts/`, `bin/`)

### Git diff
Collect changes from *both* working tree and index:
- `git diff --name-only`
- `git diff --name-only --cached`

If the repo has an upstream main branch, also consider what differs from it:
- `git merge-base HEAD origin/main` (or `origin/master`) then `git diff --name-only <merge_base>..HEAD`

### Conversation history
Extract any **explicit** preferences, constraints, or workflow decisions stated by the user (e.g., preferred tooling, formatting rules, safety constraints). Only include things that are:
- Stable project guidance (not one-off debugging steps)
- Likely to help future agent work

## Decide Where to Write `AGENTS.md`

### Root vs nested
- Not every directory needs `AGENTS.md`. If the directory is tiny, or has no meaningful workflow/tooling to encode, skip it.
- Ensure there is a **root** `AGENTS.md` at repo root.
- Create **nested** `AGENTS.md` for any sufficiently large or important part of the program.
  - Heuristics: separate language/tooling (e.g., `frontend/` vs `backend/`), its own build/test/lint entrypoints, a standalone package/module/subproject, or a directory with many files/subfolders.

### Directory selection from diff
- Group changed files by directory (and parent directories).
- Target directories that have concentrated changes or that introduce new tooling/config.

## What to Put in Each `AGENTS.md`

### Suggested structure
- **Overview**
  - What this part of the repo is for, in 2–5 bullets
- **Directory map**
  - A small bullet list of key folders/files and what they contain
- **Entrypoints & common flows**
  - Primary CLI command(s), server start command(s), and where “main” lives
  - For common commands/entrypoints, describe “when you run X, Y happens”
- **Architecture**
  - Key components/modules and their responsibilities (a small inventory/table is great)
  - Boundaries/interfaces between components
  - High-level data/control flow
  - Runtime/deployment topology when relevant (processes/services, external dependencies, where it runs)
  - Call out a few **key decision points** (caching, short-circuits, feature flags, environment-driven behavior)
  - Mermaid diagrams are welcome when it clarifies the flow
  - A short table of core libraries/tools and what they’re for
- **Interfaces, contracts, and compatibility**
  - What this directory integrates with (upstream/downstream components)
  - Contracts/interfaces (APIs, CLIs, schemas, file formats) and where they live
  - Compatibility/versioning constraints and what must be updated together
- **Configuration**
  - Config sources and precedence. For example:
    - CLI flags
    - env vars
    - config files
    - headers
    - constants
    - defaults
- **Infra & release context**
  - Environments (dev/stage/prod naming) and what changes between them
  - CI/CD entrypoints and where deploy/release config lives (high-level pointers)
- **Error handling and observability**
  - Where logs/metrics/traces go, error taxonomy/categories (if any), redaction expectations
  - Secret-handling expectations (what must never be committed/logged) and where secrets should come from

### Strong defaults / best practices
- Prefer **specificity** over generic advice
- Avoid duplicating repo-wide guidance across many `AGENTS.md` files:
  - Keep shared guidance in the nearest applicable `AGENTS.md` (often the root)
  - Have nested files link to it and describe only local deltas/exceptions
- Keep infra remarks practical and non-invasive:
  - Prefer “where it runs / how it ships / what can break prod” over long IaC walkthroughs
- Don’t include secrets, tokens, private URLs, or machine-specific paths
- If something is uncertain, say so and link to the authoritative source in-repo

## Update Strategy (Don’t Clobber Existing Content)
- If `AGENTS.md` exists:
  - Preserve useful, still-correct content
  - Remove outdated instructions only when you can prove they’re wrong
  - Keep the file structured; avoid sprawling append-only notes
- If creating a new `AGENTS.md`:
  - Start with the suggested structure above
  - Add only what you can ground in the repo + diff + conversation

## Procedure
1. Identify repo root and candidate directories from diff.
2. For each target directory, read:
   - Existing `AGENTS.md` if present
   - Closest `README.md`, `CONTRIBUTING.md`, `Makefile`, package manifests, and scripts referenced by the diff
3. Draft updates using the template structure above.
4. Keep each `AGENTS.md` concise:
   - Prefer ~150–300 lines unless the directory truly needs more
5. Output: apply edits directly, producing clean diffs.
