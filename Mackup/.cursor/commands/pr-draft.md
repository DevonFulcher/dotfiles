Create a **PR draft doc** (title + description) in your tech docs repo so it can be reviewed/edited before the PR is opened.

## Draft location

- Tech docs repo: `$GIT_PROJECTS_WORKDIR/tech-docs/pr/pending/`

## Steps

1. Identify the repo, head branch, and base branch:
   - Repo: `git rev-parse --show-toplevel`
   - Head: `git rev-parse --abbrev-ref HEAD`
   - Base: `git-town branch` (use the “parent” / base branch)
2. Craft a PR title + thorough description (use `git diff` when needed).
3. Write the draft file into tech docs `pr/pending/` and open it for review.

## Draft file template

Create a draft file named like:

- `<repo>__<head-branch>__<yyyy-mm-ddTHHMMSSZ>.md`

with this content:

```markdown
---
repo: <repo>
base: <base branch>
head: <head branch>
createdAt: <ISO-8601 timestamp>
title: <PR title>
---

## Summary
- <what changed and why>
- <impact or behavior change>
```

## Helpful shell (optional)

```shell
set -euo pipefail

repo="$(basename "$(git rev-parse --show-toplevel)")"
head_branch="$(git rev-parse --abbrev-ref HEAD)"

# Fill this in from `git-town branch` output (the parent/base branch).
base_branch="<base branch>"

tech_docs_dir="${GIT_PROJECTS_WORKDIR:?}/tech-docs"
pending_dir="$tech_docs_dir/pr/pending"
ts="$(date -u +%Y-%m-%dT%H%M%SZ)"
draft_file="$pending_dir/${repo}__${head_branch}__${ts}.md"

mkdir -p "$pending_dir"

cat > "$draft_file" <<'EOF'
---
repo: <repo>
base: <base branch>
head: <head branch>
createdAt: <ISO-8601 timestamp>
title: <PR title>
---

## Summary
- <what changed and why>

## Test plan
- <what you ran> / not run (reason)
EOF

echo "Draft created: $draft_file"
```
