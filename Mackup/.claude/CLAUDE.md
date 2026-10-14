## Focus

- Keep code changes focused on the task at hand. Do not update pre-existing code unnecessarily without instructions from the user.
- Make updates minimal. Changing code can have many downstream unintended consequences. So, make only the changes that are necessary.
- Always follow the principle of Chesterton's Fence: before changing or removing code, understand why it exists.

## Style

- Avoid overly broad or ambiguous file and directory names like `utils` or `types`.
- Use terms directly from the data (field and column names) in labels, titles and docs rather than renaming them.
- For greenfield code, prefer simple code over graceful degradation. Let errors propagate rather than preemptively handling failure modes you haven't actually encountered.
- Comments and docstrings describe what the code does now and why. Don't narrate how it was worked out ("confirmed against…", "as of this writing", "not yet verified") or cite docs, tickets or threads the reader can't open. Put that context in the PR description instead.

## Git

- Only open PRs in draft mode unless the user says otherwise.
- Verify a change end to end before opening a PR for review: run it on real data or in the real tool (render, open generated links, exercise the code path), not just unit tests and validators. State in the PR what was verified and how.
- A PR with any visual or UI change (dashboards, charts, web pages, app screens, rendered output) includes screenshots of the result in its description: the changed parts, and the states a reviewer needs.
- Always use the `toolbelt` CLI for git work on branches, worktrees and stacks, never plain `git` for it (see `toolbelt git --help`): `toolbelt git append` creates a stacked branch and its worktree, `toolbelt git save -m "<message>"` commits and pushes (and syncs the stack: it merges the parent into its children and restacks them), `toolbelt git sync` only resumes after a sync stopped on a conflict, and `toolbelt git merge <pr>` lands a PR. Plain `git` is for reading (status, log, diff) and for resolving a conflict toolbelt stopped on (edit the files, `git add`). If toolbelt cannot do what you need (it errors, or the case is not supported), stop and tell me what failed and why, instead of working around it with plain `git`.
- Create the stacked branch with `toolbelt git append` before you start editing, not after. `append` commits any uncommitted changes onto the current branch as a checkpoint before it forks, so changes made first end up on the wrong branch and in its PR.
- If the work has no Jira ticket, create one before running `toolbelt git append` (it requires `--task`) and pass its key. Don't stop to ask for a key. Personal repos such as toolbelt and dotfiles don't need a ticket.
- Where a fix for PR feedback goes depends on the PR's state:
  - Critical issues (merge conflicts, CI failures the PR caused, bugs, security or data-loss risks) go on the PR's own branch, whatever its state.
  - A draft has no reviewers to disturb: fix everything in place instead of stacking, then re-merge any child branches onto its new tip.
  - A ready PR that is not approved yet: commit a non-critical fix to the branch only if it is minimal enough not to disrupt a human review; otherwise stack it.
  - An approved PR: always stack a non-critical fix on a follow-up branch (`toolbelt git append`), however small. Reply on the thread, link the follow-up, and resolve it.
- The exception is PR feedback that only asks for documentation or comment changes: update the PR itself, even if it is approved, rather than stacking a follow-up.
- `toolbelt git sync` (which `toolbelt git save` also runs) merges each parent into its children. When a parent has landed, or has been rewritten (restacked, amended or squashed), it instead replays the child's own commits onto it with `git rebase --onto` and force-pushes. On a conflict it stops with "Merge conflict while syncing", "Rebase conflict restacking" or "Rebase conflict replaying" and leaves that worktree mid-merge or mid-rebase. Resolving it is part of the task, even when it is in a child branch you did not edit: resolve it in that worktree, `git add`, and re-run `toolbelt git sync` (it continues a rebase in progress). Don't `git merge --abort` or `git rebase --abort` to get out of it, because that leaves the child's PR conflicting.
- Keep a refactor of related functionality in one PR so a reviewer sees the whole design working, rather than spreading it across several PRs. Don't land scaffolding in one PR that a later PR deletes. Split a stack only along independent seams (a pure move, a separate behavior change), not along the steps of one refactor.

## Communication

- When a message has several bullets or questions, answer each one in order, as a bullet-for-bullet reply: restate the bullet, then respond under it. Put details inside the matching bullet.
- When you ask me a question or for a decision, make it self-contained: don't assume I've read the whole transcript or remember earlier context. For each one, say what it is about in a sentence, what is at stake (what happens under each answer), the options, your recommendation, and what you already checked or couldn't check, with links to the PR or ticket involved. Look up what you can yourself before asking. A few well-specified questions beat a long terse list.

- When posting anywhere others read (GitHub comments and reviews, Slack, Jira, Notion comments), always identify yourself as AI, e.g. start with "🤖 AI-generated on behalf of Devon:".
- When referring to a PR (or issue) in chat, write a markdown link whose text is the number and whose target is the full URL: `[#1692](https://github.com/dbt-labs/ai-codegen-api/pull/1692)`. The app renders it as `dbt-labs/ai-codegen-api#1692`. Never a bare `#123` and never the plain text `org/repo#123` (it doesn't render). Add a short description of what the PR does the first time. Never use an invented label such as "PR A" or "PR 2": the reader can't look those up.
- Always include a link for every relevant resource you mention or rely on, not just PRs: Jira tickets, Slack threads, Notion pages, CI runs, docs. When tying work to a ticket or thread, link the PR to it and the ticket back to the PR, so each can be found from the other.
- Every PR that belongs to a Jira ticket gets the ticket key in its title and a link to the ticket in its body, and the PR is added to the ticket as a remote link (not only pasted in a comment). If a PR has no ticket, say so rather than leaving it out silently. Do this when creating the PR.
- Keep the Jira status in step with the PR: draft PR or no PR yet is "In Progress", open non-draft PR is "In Review" (if the project has that status; if not, say so instead of leaving it "In Progress"), merged is "Done".
- If a step needs the user to run a command or do something themselves (an SSO login, a reinstall, approving a permission, anything outside your reach), stop right away and say exactly what you need, instead of working around it or carrying on with the rest. Resume once they confirm.
- Exception: after changing the `toolbelt` CLI, reinstall it yourself, editable so `toolbelt ui` can find the web sources (`uv tool install --editable --reinstall /Users/devonfulcher/git/toolbelt`) and confirm the installed copy has the change. No need to ask.
