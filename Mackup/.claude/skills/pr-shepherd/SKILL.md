1. Review the PRs I have open. Ignore PRs in archived repos.
2. For each PR, fetch BOTH comment sources — inline review comments and issue-level comments:
  ```bash
  # Inline review comments (line-level, bot comments like cursor[bot] appear here)
  gh api repos/OWNER/REPO/pulls/NUMBER/comments --jq '.[] | {id, node_id, user: .user.login, body: .body[:200]}'

  # Issue-level comments (top-level PR discussion)
  gh api repos/OWNER/REPO/issues/NUMBER/comments --jq '.[] | {id, user: .user.login, body: .body[:200]}'
  ```

3. Determine which of these PRs are a bit stuck:
  - Merge conflicts
  - Unresolved inline review comments (including from bots like cursor[bot]) — check `pulls/comments`
  - Easily fixable CI failures

4. Address these issues and push up fixes:
  - Fix merge conflicts.
  - Always run linters, type checkers, formatters, and unit tests before pushing up changes.
  - For CI failures that are likely transient, re-run jobs.
  - For unresolved review comments (human or bot): evaluate whether the concern is valid, fix code if warranted (avoid scope creep), reply to the thread indicating the reply is from AI, and resolve the discussion.
  - When replying to PR review comments, use the review comment reply endpoint (NOT the issue comments endpoint):
    ```bash
    # Reply to a specific review comment thread
    gh api repos/OWNER/REPO/pulls/comments/COMMENT_ID/replies -f body="Your reply"

    # Resolve the review thread (use the node_id from the comment)
    gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "NODE_ID"}) { thread { isResolved } } }'
    ```
    WRONG: `gh api repos/OWNER/REPO/issues/NUMBER/comments` (this posts a top-level PR comment, not a thread reply)
4. Provide a single markdown table with ALL PRs. Use separate columns for each status dimension — multiple can be true simultaneously:

  Table columns: | CI | Reviews | Blockers | PR | Repo | Fix Applied | Action |

  **CI** column (pick one):
  - Failing
  - Running (just pushed or re-ran)
  - Passing
  - None

  **Reviews** column (comma-separate multiple values as needed):
  - Waiting on reviewer
  - Approved
  - Unresolved comments
  - Draft

  **Blockers** column (comma-separate multiple values as needed, or "—" if none):
  - Merge conflict
  - Blocked on PR #number
  - Needs my action
  - On hold

  **PR**: `[#number title](link)`
  **Repo**: repository short name
  **Fix Applied**: brief description of what was done this run, or "—" if nothing
  **Action**: what needs to happen next (one short sentence)

  Sort rows: most actionable first — PRs with "Needs my action" or "Merge conflict" blockers at top, then CI Failing, then CI Running, then Waiting on reviewer, then Approved.
