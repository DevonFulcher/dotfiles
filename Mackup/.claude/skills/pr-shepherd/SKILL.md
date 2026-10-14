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

3. **Choose where the fix goes by the PR's state.** Push to the PR's own branch for **critical** issues, whatever the PR's state:
   - Merge conflicts
   - CI failures caused by the PR that block merging (broken build, failing tests, lint errors)
   - Bugs, security problems, or data-loss risks identified in review

   For everything else (non-critical review feedback, nits, refactors, improvements):
   - **Draft PR** (`is_draft`): no reviewers to disturb, so fix it in place on the PR's branch, then re-merge any child branches onto its new tip.
   - **Ready PR that is not approved yet**: commit the fix to the branch only if it is minimal enough not to disrupt a human review in progress (a typo, a rename, a one-line change). Otherwise stack it.
   - **Approved PR**: always stack it, however small.

   To stack, **append the fix on top of the stack** as a follow-up branch using `toolbelt git append` (see `toolbelt git --help`) and open it as a stacked PR. When in doubt, stack.

4. **Make the fixes.** You must actually make the fix (on the PR branch for critical issues, on an appended branch otherwise), not just describe it. Identifying a fixable issue without fixing it is a failure.
   - **Before making any code changes**, review the PR's commit history (`git log origin/main...HEAD --oneline`) to understand what decisions have already been made. Do not revert or undo previously committed changes.
   - **Use `toolbelt`, never plain `git`, for branches, worktrees, commits and pushes.** `toolbelt git append` creates a branch and its worktree; `toolbelt git save -m "<message>"` commits and pushes, and syncs the stack so the PR's children get the change. Plain `git` is only for reading (status, log, diff) and for resolving a conflict toolbelt stopped on (edit the files, `git add`, then re-run `toolbelt git sync`). If toolbelt cannot do what you need, stop and say so in `next_action` for the user instead of working around it with plain `git`.
   - **Before pushing**, run the repo's full check suite (e.g. `task check` — look in the repo's CLAUDE.md for the exact command). Do not push without passing checks.
   - A transient CI failure is very likely a flake that needs fixing, not just retrying. Re-run the job (following the repo's CLAUDE.md rules on how to rerun) so the PR can move, and also work through **Flaky CI** below, whether or not the rerun passes. A rerun that passes proves the flake exists; it doesn't fix it.
   - For CI failures caused by code issues: find the repo under `$GIT_PROJECTS_WORKDIR`, use `toolbelt git` to work in a worktree for the PR branch, make the fix, run linters/tests, and commit and push with `toolbelt git save -m "<message>"` (to the PR branch if critical, otherwise to an appended branch).
   - For test failures: investigate whether they were introduced by the PR (`git diff origin/main...HEAD`). If pre-existing, note it but do not attempt a fix. If introduced by the PR, fix it.
   - **After pushing any code fix to the PR's branch**, review the PR description and update it if the changes materially affect scope or content (add/adjust the # What section or notes). For appended branches, write the new PR's description to cover the fix.

   **Flaky CI.** Treat any failure that is not caused by the PR's diff as a flake until shown otherwise: "transient", "infrastructure" and "network" are descriptions of a flake, not reasons to skip it. Compare with `main` and other recent runs of the same workflow. Do not just rerun and move on:
   1. **Find the failing test or step and the reason it fails** from the log (the assertion, the timeout, the HTTP error), and check how often it fails across recent runs on other branches.
   2. **Look for existing work first**: search open PRs and branches for the same test or error (`gh pr list --search`). If someone is already fixing it, link that PR in your result and don't duplicate it.
   3. **Decide who owns the cause.**
      - Our code or tests: the flake is in the test (a timing or ordering assumption, an assertion on nondeterministic output) or in the source under test.
      - Another team's system: a shared service, platform tooling or an external dependency (for example a warm-environment manager, a package or image registry, a GitHub Actions or runner problem, a third-party API). Find the owning team from CODEOWNERS, the repo's docs, `git log`/`git blame` of the relevant config, or the service's README, and name the team and the evidence in your result. Don't try to fix another team's system.
   4. **If it is ours, fix it.** Make the smallest change that removes the nondeterminism. Prefer fixing the test over changing source, and change source only when the source is genuinely at fault. A test that asserts a third party's behavior (such as a provider's cache) should stop depending on it. Put the fix on a **new branch off the default branch**, not on the blocked PR's branch, so it can merge on its own: use `toolbelt git append` from a clean checkout of the default branch (it commits uncommitted changes onto the current branch first, so make sure there are none). Run the repo's full check suite, open it as a **draft** PR, and say in the description which runs flaked, and link them.
   5. **If it isn't clear whether it is ours**, say what you checked and what is missing instead of guessing.
   6. **Report it** in the `flake` field below.

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
   - `flake`: for a flaky CI failure, the failing test or step, the cause, who owns it (this repo or the named team, with evidence), and the link to the fix PR or the existing PR that fixes it. Use a dash if there was no flake.
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
