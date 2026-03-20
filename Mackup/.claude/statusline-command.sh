#!/bin/sh
# Claude Code status line — mirrors Starship prompt layout
input=$(cat)

# Extract fields from JSON input
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Time
time_str=$(date +%I:%M%p)

# Directory: truncate to last 3 components with .../ prefix if longer
dir_display=$(echo "$cwd" | awk -F/ '{
  n=NF; parts="";
  if (n <= 3) { print $0 }
  else { printf ".../%s/%s/%s", $(n-2), $(n-1), $n }
}')

# Git branch (skip optional locks)
git_branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Git status summary (condensed)
git_status_summary=""
if [ -n "$git_branch" ]; then
  modified=$(git -C "$cwd" -c core.hooksPath=/dev/null status --porcelain 2>/dev/null | grep -c '^.M\|^M' || true)
  staged=$(git -C "$cwd" -c core.hooksPath=/dev/null status --porcelain 2>/dev/null | grep -c '^[MADRCU]' || true)
  untracked=$(git -C "$cwd" -c core.hooksPath=/dev/null status --porcelain 2>/dev/null | grep -c '^??' || true)
  parts=""
  [ "$staged" -gt 0 ] 2>/dev/null && parts="${parts}staged-"
  [ "$modified" -gt 0 ] 2>/dev/null && parts="${parts}modified-"
  [ "$untracked" -gt 0 ] 2>/dev/null && parts="${parts}untracked-"
  [ -n "$parts" ] && git_status_summary="($parts)"
fi

# Context usage
ctx_str=""
if [ -n "$used_pct" ]; then
  ctx_str=$(printf "ctx:%.0f%%" "$used_pct")
fi

# Build the status line
line=""

# Time
line="[$time_str]"

# Directory
[ -n "$dir_display" ] && line="$line $dir_display"

# Git branch + status
if [ -n "$git_branch" ]; then
  line="$line $git_branch"
  [ -n "$git_status_summary" ] && line="$line $git_status_summary"
fi

# Model
[ -n "$model" ] && line="$line | $model"

# Context
[ -n "$ctx_str" ] && line="$line $ctx_str"

printf "%s" "$line"
