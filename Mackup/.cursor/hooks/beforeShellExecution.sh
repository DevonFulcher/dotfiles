#!/usr/bin/env sh

# Cursor passes hook input JSON on stdin.
# Use *all* workspace roots (do not trust event "cwd", which may be "/").
workspace_roots="$(
  jq -r '.workspace_roots[]? // empty' 2>/dev/null
)"

[ -n "$workspace_roots" ] || exit 0

printf '%s\n' "$workspace_roots" | while IFS= read -r root; do
  [ -n "$root" ] || continue
  [ -d "$root" ] || continue
  direnv allow "$root"
done