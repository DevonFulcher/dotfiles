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
- Use the `toolbelt` CLI for stacked branches and worktrees. See `toolbelt git --help`.
- Create the stacked branch with `toolbelt git append` before you start editing, not after. `append` commits any uncommitted changes onto the current branch as a checkpoint before it forks, so changes made first end up on the wrong branch and in its PR.
- When addressing PR feedback on a PR that is ready for review or approved, only edit the PR's own branch for critical issues. Otherwise reply on the thread, resolve it, and stack any fix on a follow-up branch (`toolbelt git append`). It is better to stack than edit.
- The exception is PR feedback that only asks for documentation or comment changes: update the PR itself, even if it is approved, rather than stacking a follow-up.
- A PR that is still a draft has no reviewers to disturb: fix feedback on it in place instead of stacking, then re-merge any child branches onto its new tip.
- Keep a refactor of related functionality in one PR so a reviewer sees the whole design working, rather than spreading it across several PRs. Don't land scaffolding in one PR that a later PR deletes. Split a stack only along independent seams (a pure move, a separate behavior change), not along the steps of one refactor.

## Communication

- When a message has several bullets or questions, answer each one in order, as a bullet-for-bullet reply: restate the bullet, then respond under it. Put details inside the matching bullet.

- When posting anywhere others read (GitHub comments and reviews, Slack, Jira, Notion comments), always identify yourself as AI, e.g. start with "🤖 AI-generated on behalf of Devon:".
- When referring to a PR (or issue) in chat, write a markdown link whose text is the number and whose target is the full URL: `[#1692](https://github.com/dbt-labs/ai-codegen-api/pull/1692)`. The app renders it as `dbt-labs/ai-codegen-api#1692`. Never a bare `#123` and never the plain text `org/repo#123` (it doesn't render). Add a short description of what the PR does the first time. Never use an invented label such as "PR A" or "PR 2": the reader can't look those up.
- Always include a link for every relevant resource you mention or rely on, not just PRs: Jira tickets, Slack threads, Notion pages, CI runs, docs. When tying work to a ticket or thread, link the PR to it and the ticket back to the PR, so each can be found from the other.
- Every PR that belongs to a Jira ticket gets the ticket key in its title and a link to the ticket in its body, and the PR is added to the ticket as a remote link (not only pasted in a comment). If a PR has no ticket, say so rather than leaving it out silently. Do this when creating the PR.
- Keep the Jira status in step with the PR: draft PR or no PR yet is "In Progress", open non-draft PR is "In Review" (if the project has that status; if not, say so instead of leaving it "In Progress"), merged is "Done".
- If a step needs the user to run a command or do something themselves (an SSO login, a reinstall, approving a permission, anything outside your reach), stop right away and say exactly what you need, instead of working around it or carrying on with the rest. Resume once they confirm.
- Exception: after changing the `toolbelt` CLI, reinstall it yourself (`uv tool install --reinstall /Users/devonfulcher/git/toolbelt`) and confirm the installed copy has the change. No need to ask.
