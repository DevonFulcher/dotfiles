---
name: pr-shepherd
description: Shepherd a single PR — fix merge conflicts, address review comments, re-run CI, and report status.
argument-hint: <pr-url>
disable-model-invocation: true
---

Shepherd the PR at `$ARGUMENTS`.

## Step 1: Gather PR data

Run the data-gathering script for this specific PR:
```bash
python3 "${CLAUDE_SKILL_DIR}/pr-status.py" "$ARGUMENTS"
```
This outputs one JSON object containing: title, url, is_draft, mergeable, review_comments, issue_comments, review_threads (each with `id`, `isResolved`, `isOutdated`, `root_author`, `root_comment_id`, `comments`), checks, and reviews. Thread data comes from GitHub GraphQL: at most **50** threads and **100** comments per thread; if a PR exceeds that, treat the JSON as partial.

## Step 2: Spawn a teammate agent

Create a single teammate agent and send it:
1. The PR JSON data.
2. The instructions below.

Name the teammate `shepherd-pr`.

## Step 3: Instructions to send to the teammate

The teammate receives the PR JSON and these instructions:

---

You are shepherding a single PR. You have been given its JSON data.

1. **Parse the PR JSON.** You have both comment sources:
   - `review_comments` — inline review comments (line-level; bot comments like cursor[bot] appear here)
   - `issue_comments` — top-level PR discussion comments
   - `review_threads` — per-thread `id` (for resolve mutation), `isResolved`, `isOutdated`, `root_author`, `root_comment_id`, and `comments` (REST comment ids and `user` logins)

2. **Determine if the PR is stuck:**
   - Merge conflicts
   - Unresolved inline review comments (including from bots like cursor[bot]) — check `pulls/comments`
   - Easily fixable CI failures

3. **Address issues and push fixes.** You must actually make the fix, not just describe it. Identifying a fixable issue without fixing it is a failure.
   - Fix merge conflicts.
   - **Before making any code changes**, review the PR's commit history (`git log origin/main...HEAD --oneline`) to understand what decisions have already been made. Do not revert or undo previously committed changes.
   - **Before pushing**, run the repo's full check suite (e.g. `task check` — look in the repo's CLAUDE.md for the exact command). Do not push without passing checks.
   - For CI failures that are likely transient, re-run jobs.
   - For CI failures caused by code issues (unused imports, lint errors, formatting): find the repo under `$GIT_PROJECTS_WORKDIR`, check out the PR branch, make the fix, run linters/tests, and push. Do not skip this step.
   - For test failures: investigate whether they were introduced by the PR (`git diff origin/main...HEAD`). If pre-existing, note it but do not attempt a fix. If introduced by the PR, fix it.
   - For unresolved review comments (human or bot): evaluate whether the concern is valid, fix code if warranted (avoid scope creep), and reply to the thread indicating the reply is from AI — **except** for outdated AI threads (see below).
   - **Outdated AI threads:** For a thread where `isOutdated` is true and `root_author` is a bot (cursor[bot], github-copilot[bot], copilot-pull-request-reviewer[bot], and similar), **resolve the thread with no reply and no new PR comment.** The diff context is stale; do not argue with or explain away outdated bot feedback.
   - **Non-outdated threads:** Unresolved threads that you resolve after handling must have a thread reply first (see exceptions above). Do not resolve silently unless the thread is an outdated AI thread as defined above.
   - **Do not reply to substantive human review comments** (non-nit feedback, design concerns, architecture questions, requests for explanation). Leave those open for the user to respond to. Only reply to: bot comments (cursor[bot], Copilot, etc.) and human nit-level comments (typos, minor style, formatting). Silent resolve without a reply is only for **outdated** threads whose **root** comment is from a bot (`isOutdated` + bot `root_author`); do not use silent resolve for human-rooted threads.
   - **After pushing any code fix**, review the PR description and update it if the changes materially affect scope or content (add/adjust the # What section or notes).
   - **Only resolve a thread if one of the following is true:**
     - You pushed a code fix addressing the concern, OR
     - The concern is clearly invalid/not applicable and your reply explains why, OR
     - It is an **outdated AI thread** (see above): `isOutdated` true and bot `root_author` — resolve with no reply
     - Do NOT resolve threads with vague "will fix later" or "acknowledged" replies — leave them open (outdated-AI exception still applies)
   - When replying to PR review comments, use the review comment reply endpoint (NOT the issue comments endpoint):
     ```bash
     # Reply to a specific review comment (COMMENT_ID = numeric id from review_comments[].id or root_comment_id)
     gh api repos/OWNER/REPO/pulls/comments/COMMENT_ID/replies -f body="Your reply"

     # Resolve the review thread: threadId MUST be review_threads[].id (PullRequestReviewThread node id, e.g. PRRT_kwDO...)
     # Do NOT pass a review comment node_id (PRRC_...) — resolveReviewThread requires the thread id.
     gh api graphql -f query='mutation($threadId: ID!) { resolveReviewThread(input: { threadId: $threadId }) { thread { isResolved } } }' -f threadId='ID_FROM_review_threads'
     ```
     WRONG: `gh api repos/OWNER/REPO/issues/NUMBER/comments` (this posts a top-level PR comment, not a thread reply)

4. **Send results back** to the team lead. Report a JSON object with these fields:
   - `title`: PR title
   - `url`: PR URL
   - `repo`: repository short name
   - `ci_status`: one of "Failing", "Running", "Passing", "None"
   - `reviews_status`: comma-separated from "Waiting on reviewer", "Approved", "Unresolved comments", "Draft"
   - `actions_performed`: everything done this run (code fixes, comment replies, CI re-runs, thread resolutions). Use a dash if nothing was done.
   - `next_action`: what needs to happen next (one short sentence)

---

## Step 4: Collect result and produce the final report

After the teammate finishes, collect its reported PR result and produce a short markdown report.

Include:
- A one-row table with columns: | CI | Reviews | Title | PR | Repo | Actions Performed | Next Action |
- A **Details** section with any notable findings or explanations.

**PR** column: plain URL (no markdown link syntax — link text is stripped in terminal output).

Write the markdown report to `$TMPDIR/pr-shepherd-report.md`, then open it with:
```bash
e $TMPDIR/pr-shepherd-report.md
```
