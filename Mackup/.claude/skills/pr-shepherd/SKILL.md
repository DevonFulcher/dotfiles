1. Run the data-gathering script to collect all open PR data in one pass:
  ```bash
  python3 "$(dirname "$0")/pr-status.py"
  ```
  This outputs one JSON object per PR (stdout, newline-delimited) containing: title, url, is_draft, mergeable, review_comments, issue_comments, review_threads (with isResolved), checks, and reviews. Ignore PRs in archived repos (the script skips them automatically).

2. Parse the JSON output. For each PR you now have BOTH comment sources:
  - `review_comments` — inline review comments (line-level; bot comments like cursor[bot] appear here)
  - `issue_comments` — top-level PR discussion comments
  - `review_threads` — GraphQL thread objects with `isResolved` flag

3. Determine which of these PRs are a bit stuck:
  - Merge conflicts
  - Unresolved inline review comments (including from bots like cursor[bot]) — check `pulls/comments`
  - Easily fixable CI failures

4. Address these issues and push up fixes. **You must actually make the fix, not just describe it.** Identifying a fixable issue without fixing it is a failure.
  - Fix merge conflicts.
  - **Before making any code changes**, review the PR's commit history (`git log origin/main...HEAD --oneline`) to understand what decisions have already been made. Do not revert or undo previously committed changes.
  - **Before pushing**, run the repo's full check suite (e.g. `task check` — look in the repo's CLAUDE.md for the exact command). Do not push without passing checks.
  - For CI failures that are likely transient, re-run jobs.
  - For CI failures caused by code issues (unused imports, lint errors, formatting): find the repo under `$GIT_PROJECTS_WORKDIR`, check out the PR branch, make the fix, run linters/tests, and push. Do not skip this step.
  - For test failures: investigate whether they were introduced by the PR (`git diff origin/main...HEAD`). If pre-existing, note it but do not attempt a fix. If introduced by the PR, fix it.
  - For unresolved review comments (human or bot): evaluate whether the concern is valid, fix code if warranted (avoid scope creep), and reply to the thread indicating the reply is from AI.
  - **All unresolved comment threads must receive a reply** before being resolved — never resolve silently.
  - **Do not reply to substantive human review comments** (non-nit feedback, design concerns, architecture questions, requests for explanation). Leave those open for the user to respond to. Only reply to: bot comments (cursor[bot], Copilot, etc.) and human nit-level comments (typos, minor style, formatting).
  - **After pushing any code fix**, review the PR description and update it if the changes materially affect scope or content (add/adjust the # What section or notes).
  - **Only resolve a thread if one of the following is true:**
    - You pushed a code fix addressing the concern, OR
    - The concern is clearly invalid/not applicable and your reply explains why
    - Do NOT resolve threads with vague "will fix later" or "acknowledged" replies — leave them open
  - When replying to PR review comments, use the review comment reply endpoint (NOT the issue comments endpoint):
    ```bash
    # Reply to a specific review comment thread
    gh api repos/OWNER/REPO/pulls/comments/COMMENT_ID/replies -f body="Your reply"

    # Resolve the review thread (use the node_id from the comment)
    gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "NODE_ID"}) { thread { isResolved } } }'
    ```
    WRONG: `gh api repos/OWNER/REPO/issues/NUMBER/comments` (this posts a top-level PR comment, not a thread reply)
4. Provide a single markdown table with ALL PRs. Use separate columns for each status dimension — multiple can be true simultaneously:

  Table columns: | CI | Reviews | Title | PR | Repo | Actions Performed | Next Action |

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

  **Title**: PR title as plain text
  **PR**: plain URL (no markdown link syntax — link text is stripped in terminal output)
  **Repo**: repository short name
  **Actions Performed**: everything done this run — code fixes, comment replies, CI re-runs, thread resolutions, etc. Use "—" if nothing was done.
  **Next Action**: what needs to happen next (one short sentence)

  Sort rows: most actionable first — PRs with unresolved comments or merge conflicts at top, then CI Failing, then CI Running, then Waiting on reviewer, then Approved.

  Use "—" in **Actions Performed** only if nothing was done this run.

5. Write the markdown table (and any action notes) to `$TMPDIR/pr-shepherd-report.md`, then open it with:
  ```bash
  e $TMPDIR/pr-shepherd-report.md
  ```
