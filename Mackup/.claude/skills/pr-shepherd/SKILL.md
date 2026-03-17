This skill distributes PR shepherding across multiple teammates for parallel processing.

## Step 1: Gather PR data

Run the data-gathering script to collect all open PR data in one pass:
```bash
python3 "$GIT_PROJECTS_WORKDIR/dotfiles/.claude/skills/pr-shepherd/pr-status.py"
```
This outputs one JSON object per PR (stdout, newline-delimited) containing: title, url, is_draft, mergeable, review_comments, issue_comments, review_threads (with isResolved), checks, and reviews. Ignore PRs in archived repos (the script skips them automatically).

## Step 2: Spawn teammate agents

Parse the JSON output. Group PRs by repository. For each repo (or individual PR if a repo has many), create a teammate agent and send it:
1. The PR JSON data for its assigned repo.
2. A **"Related PRs from other repos"** section containing the full PR JSON data for all PRs in *other* repos. This gives each teammate cross-repo visibility.

Spawn all teammates in parallel so repos are processed concurrently. Name each teammate after the repo it handles (e.g., `shepherd-myrepo`).

## Step 3: Instructions to send to each teammate

Each teammate receives the PR JSON for its assigned repo(s), the related PRs from other repos, and these instructions:

---

For each PR in your assigned data:

1. **Parse the PR JSON.** You have both comment sources:
   - `review_comments` — inline review comments (line-level; bot comments like cursor[bot] appear here)
   - `issue_comments` — top-level PR discussion comments
   - `review_threads` — GraphQL thread objects with `isResolved` flag

2. **Use the "Related PRs from other repos" context** to identify cross-repo relationships:
   - **Stacked PRs**: PRs in other repos that share the same branch chain or naming pattern (e.g., `feature/foo` across multiple repos).
   - **Adjacent PRs**: PRs related to the same feature, ticket, or initiative (look for shared ticket IDs, similar titles, or references in PR descriptions).
   - **Blocking dependencies**: PRs in other repos that this PR depends on (e.g., a library repo PR that must merge before a consuming repo's PR).
   Factor these into your shepherding decisions. For example:
   - Do not merge a PR if a dependency PR in another repo is still open or failing CI.
   - Note cross-repo relationships in your report so the team lead has full visibility.
   - If a review comment references work happening in another repo's PR, use that context when deciding how to respond.

3. **Determine which PRs are stuck:**
   - Merge conflicts
   - Unresolved inline review comments (including from bots like cursor[bot]) — check `pulls/comments`
   - Easily fixable CI failures

4. **Address issues and push fixes.** You must actually make the fix, not just describe it. Identifying a fixable issue without fixing it is a failure.
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

5. **Send results back** to the team lead. For each PR, report a JSON object with these fields:
   - `title`: PR title
   - `url`: PR URL
   - `repo`: repository short name
   - `ci_status`: one of "Failing", "Running", "Passing", "None"
   - `reviews_status`: comma-separated from "Waiting on reviewer", "Approved", "Unresolved comments", "Draft"
   - `actions_performed`: everything done this run (code fixes, comment replies, CI re-runs, thread resolutions). Use a dash if nothing was done.
   - `next_action`: what needs to happen next (one short sentence)
   - `cross_repo_notes`: any observed cross-repo dependencies, stacked PR relationships, or blocking issues (use a dash if none)

---

## Step 4: Collect results and produce the final report

After all teammates finish, collect their reported PR results and produce a single markdown table with ALL PRs.

Table columns: | CI | Reviews | Title | PR | Repo | Actions Performed | Next Action |

Sort rows: most actionable first — PRs with unresolved comments or merge conflicts at top, then CI Failing, then CI Running, then Waiting on reviewer, then Approved.

Use a dash in **Actions Performed** only if nothing was done this run.

**PR** column: plain URL (no markdown link syntax — link text is stripped in terminal output).

If any teammates reported cross-repo dependencies or blocking relationships, add a **Cross-Repo Notes** section below the table summarizing them.

Write the markdown table (and any action notes) to `$TMPDIR/pr-shepherd-report.md`, then open it with:
```bash
e $TMPDIR/pr-shepherd-report.md
```
