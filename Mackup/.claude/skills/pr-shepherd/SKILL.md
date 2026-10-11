---
name: pr-shepherd
description: Shepherd all of my open PRs — find the active ones that aren't mergeable, fix what's blocking them, and report status.
disable-model-invocation: true
---

Shepherd all of my open PRs.

## Step 1: Gather my active, blocked PRs

```bash
python3 "${CLAUDE_SKILL_DIR}/pr-status.py"
```

The script lists my open PRs (archived repos excluded) and outputs one JSON object:
- `active_blocked` — PRs I've committed to within the last three working days (weekends don't count) that aren't mergeable. Each entry has the full PR data plus `blocked_reasons` and `thrash`.
- `active_mergeable` and `inactive` — `{title, url}` only; these are not touched.

Each `active_blocked` entry contains: title, url, is_draft, mergeable, mergeable_state, base_ref, default_branch, review_comments, issue_comments, review_threads (each with `id`, `isResolved`, `isOutdated`, `root_author`, `root_comment_id`, `comments`), checks, reviews, `head_ref`, `blocked_reasons`, and `thrash`. Thread data comes from GitHub GraphQL: at most **50** threads and **100** comments per thread; if a PR exceeds that, treat the JSON as partial.

`thrash` lists signs that a PR keeps getting re-blocked instead of converging: repeated reviews from bots (3+) or CI failing on several different commits (3+). Empty if none.

A PR is blocked if it has merge conflicts, failing checks, unresolved review threads, or is stacked on a blocked PR (its `base_ref` is another open PR that is itself blocked). Top-level PR comments aren't tracked by the script; teammates still read `issue_comments`.

## Step 2: Spawn one teammate per blocked PR

If `active_blocked` is empty, skip to the final report. Otherwise, for each entry, create a teammate agent named `shepherd-<repo>-<number>` and send it:
1. The PR JSON data.
2. The instructions below.

Run the teammates in parallel. Work on stacked PRs bottom-up so a fix to a base branch is in place before its children are handled.

### Second pass: catch comments that arrive during the run

The PR JSON is a snapshot from the start of the run, and bot reviewers (Copilot and similar) post comments on a PR within minutes of every push, including the pushes teammates make. So when the first-pass teammates finish:
1. Re-fetch the unresolved review threads for every PR in the run (the PRs you shepherded and any PR a teammate pushed to), with `gh api graphql` on `reviewThreads` (`isResolved`, `isOutdated`, first comment's author and body) or by re-running `pr-status.py`.
2. For each PR with an unresolved thread that wasn't in its original JSON, send a teammate the fresh thread data and the Step 3 instructions, as for any blocked PR. Do not hand bot comments to the user as a next action ("read the new comments"): evaluate them, fix or answer them, and resolve them.
3. Repeat until a re-fetch finds no new unresolved bot threads, at most two extra rounds. A PR that was pushed to less than a few minutes ago may not have been re-reviewed yet, so say so in the report instead of treating it as clean.

Only unresolved **human** threads that need the user's decision are left open and reported.

## Step 3: Instructions to send to each teammate

The teammate receives the PR JSON and these instructions:

---

You are shepherding a single PR. You have been given its JSON data.

**The JSON is a snapshot and may be stale.** Before acting, and again just before you report, fetch the PR's current state with `gh` (merge state, checks, and `reviewThreads` via GraphQL). Bot reviewers such as Copilot comment within minutes of a push, including your own, so a thread may exist now that is not in the JSON.

1. **Parse the PR JSON.** You have both comment sources:
   - `review_comments` — inline review comments (line-level; bot comments appear here)
   - `issue_comments` — top-level PR discussion comments
   - `review_threads` — per-thread `id` (for resolve mutation), `isResolved`, `isOutdated`, `root_author`, `root_comment_id`, and `comments` (REST comment ids and `user` logins)

2. **Determine what is blocking the PR:**
   - Merge conflicts
   - Unresolved inline review comments (including from bots) — check `pulls/comments`
   - Unresolved PR comments
   - CI failures
   - Thrash (`thrash` is non-empty): the PR keeps getting re-blocked. Fix what is blocking it now, but don't assume more patching will converge — flag it in your result.
   - Being stacked on a blocked branch (nothing to fix on this PR itself; this does not stop it from being reviewed, so don't report waiting on the base PR)

3. **Be cautious about changing the PR's branch.** Only push to the PR's own branch for **critical** issues:
   - Merge conflicts
   - CI failures caused by the PR that block merging (broken build, failing tests, lint errors)
   - Bugs, security problems, or data-loss risks identified in review

   For everything else (non-critical review feedback, nits, refactors, improvements), **append the fix on top of the stack** as a follow-up branch using `toolbelt git append` (see `toolbelt git --help`) and open it as a stacked PR. It is better to stack than edit. When in doubt, stack.

4. **Make the fixes.** You must actually make the fix (on the PR branch for critical issues, on an appended branch otherwise), not just describe it. Identifying a fixable issue without fixing it is a failure.
   - **Before making any code changes**, review the PR's commit history (`git log origin/main...HEAD --oneline`) to understand what decisions have already been made. Do not revert or undo previously committed changes.
   - **Before pushing**, run the repo's full check suite (e.g. `task check` — look in the repo's CLAUDE.md for the exact command). Do not push without passing checks.
   - For CI failures that are likely transient, re-run jobs.
   - For CI failures caused by code issues: find the repo under `$GIT_PROJECTS_WORKDIR`, use `toolbelt git` to work in a worktree for the PR branch, make the fix, run linters/tests, and push (to the PR branch if critical, otherwise to an appended branch).
   - For test failures: investigate whether they were introduced by the PR (`git diff origin/main...HEAD`). If pre-existing, note it but do not attempt a fix. If introduced by the PR, fix it.
   - **After pushing any code fix to the PR's branch**, review the PR description and update it if the changes materially affect scope or content (add/adjust the # What section or notes). For appended branches, write the new PR's description to cover the fix.

5. **Handle review threads.** Every comment you post must identify itself as AI, e.g. start with "🤖 AI-generated on behalf of Devon:".
   - For unresolved review comments (human or bot): evaluate whether the concern is valid. If a fix is warranted, apply it per step 3 and reply on the thread saying where the fix is (the pushed commit, or the stacked PR).
   - **Bot comments (Copilot and similar) are your work, not the user's.** Never report one as "read the comment" or "address the feedback" in `next_action`. Read the code the comment points at, decide whether it is valid, then fix it (a real bug found in review is a critical fix on the PR branch), reply and resolve it, or reply with why it is invalid and resolve it.
   - **Outdated AI threads:** For a thread where `isOutdated` is true and `root_author` is a bot (github-copilot[bot], copilot-pull-request-reviewer[bot], and similar), **post a thread reply saying the comment is outdated** (the diff it refers to has since changed), then resolve the thread.
   - **Do not reply to substantive human review comments** (non-nit feedback, design concerns, architecture questions, requests for explanation). Leave those open for the user to respond to. Only reply to: bot comments and human nit-level comments (typos, minor style, formatting).
   - **Only resolve a thread if one of the following is true:**
     - A code fix addressing the concern has been pushed (to the PR branch or an appended branch) and the reply links to it, OR
     - The concern is clearly invalid/not applicable and your reply explains why, OR
     - It is an **outdated AI thread** — resolve after the outdated reply
     - Do NOT resolve threads with vague "will fix later" or "acknowledged" replies — leave them open
   - When replying to PR review comments, use the review comment reply endpoint (NOT the issue comments endpoint):
     ```bash
     # Reply to a specific review comment (COMMENT_ID = numeric id from review_comments[].id or root_comment_id)
     gh api repos/OWNER/REPO/pulls/comments/COMMENT_ID/replies -f body="Your reply"

     # Resolve the review thread: threadId MUST be review_threads[].id (PullRequestReviewThread node id, e.g. PRRT_kwDO...)
     # Do NOT pass a review comment node_id (PRRC_...) — resolveReviewThread requires the thread id.
     gh api graphql -f query='mutation($threadId: ID!) { resolveReviewThread(input: { threadId: $threadId }) { thread { isResolved } } }' -f threadId='ID_FROM_review_threads'
     ```
     WRONG: `gh api repos/OWNER/REPO/issues/NUMBER/comments` (this posts a top-level PR comment, not a thread reply)

6. **Send results back** to the team lead. Report a JSON object with these fields:
   - `title`: PR title
   - `url`: PR URL
   - `repo`: repository short name
   - `ci_status`: one of "Failing", "Running", "Passing", "None"
   - `reviews_status`: comma-separated from "Waiting on reviewer", "Approved", "Unresolved comments", "Draft"
   - `actions_performed`: everything done this run (code fixes and which branch they went to, comment replies, CI re-runs, thread resolutions). Use a dash if nothing was done.
   - `thrash`: the `thrash` signals from the PR JSON plus your read of the cause (e.g. a bot re-raising the same concern, a flaky test). Use a dash if none.
   - `next_action`: what needs to happen next (one short sentence). Stacked PRs can be reviewed before their base merges, so never make waiting on a base PR the next action; only mention merge order if it matters.

---

## Step 4: Collect results and produce the final report

After all teammates finish, collect their results and print a short markdown report **directly in the response**. Do not write the report to any file.

Include:
- A table with one row per shepherded PR, columns: | CI | Reviews | Title | PR | Repo | Thrash | Actions Performed | Next Action |. The Thrash cell holds the PR's thrash signals and likely cause, or a dash if none.
- The stack tree for each repo that had a shepherded PR: run `toolbelt git tree` (alias `tt g tree`) from that repo's checkout under `$GIT_PROJECTS_WORKDIR` and print its output, headed by the repo name. Run it after all teammates finish so PRs they stacked appear. Piped output waits for every status lookup and prints once.
- A line listing active PRs that were already mergeable, and a line listing inactive PRs skipped.
- A **Details** section with any notable findings or explanations.

**PR** column: plain URL (no markdown link syntax — link text is stripped in terminal output).
