---
name: beads-tasks
description: Display beads (bd) issues for the current project — a quick status summary plus a table of open/ready work, sorted by priority.
---

## Steps

1. **Confirm a workspace exists** in the current directory: `bd where`. If none is found, tell the user this directory has no beads database rather than guessing at another one — don't run `bd init` unless they ask for it.
2. **Get the summary**: `bd status` (counts by state, ready-to-work count).
3. **Get the issues**: `bd list --json` (default filter already excludes closed issues). If the user asked specifically for "ready" work, add `--ready` instead.
4. **Render a table**, sorted by priority (P0 highest → P4 lowest), then status:

   | ID | Pri | Status | Title |
   |---|---|---|---|
   | mylang-bey | P2 | open | Remote call delegation panics instead of erroring... |

   Truncate long titles rather than wrapping. Use the JSON `dependency_count`/`dependent_count` only if the user asks about blockers — don't add extra columns by default.
5. **Close with the one-line summary** from step 2 (e.g. "8 total, 6 open, 0 in progress, 2 closed, 6 ready to work").

## Notes

- This is read-only — never create, update, or close issues unless the user explicitly asks.
- Beads workspaces are per-project (`.beads/` under the repo root), so run this from — or point `-C`/`--directory` at — the project the user means, not assuming it's the current dotfiles repo.
