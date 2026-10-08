## Focus

- Keep code changes focused on the task at hand. Do not update pre-existing code unnecessarily without instructions from the user.
- Make updates minimal. Changing code can have many downstream unintended consequences. So, make only the changes that are necessary.
- Always follow the principle of Chesterton's Fence: before changing or removing code, understand why it exists.

## Style

- Avoid overly broad or ambiguous file and directory names like `utils` or `types`.
- For greenfield code, prefer simple code over graceful degradation. Let errors propagate rather than preemptively handling failure modes you haven't actually encountered.
- Comments and docstrings describe what the code does now and why. Don't narrate how it was worked out ("confirmed against…", "as of this writing", "not yet verified") or cite docs, tickets or threads the reader can't open. Put that context in the PR description instead.

## Git

- Only open PRs in draft mode unless the user says otherwise.
- Use the `toolbelt` CLI for stacked branches and worktrees. See `toolbelt git --help`.
- When addressing PR feedback, only edit the PR's own branch for critical issues. Otherwise reply on the thread, resolve it, and stack any fix on a follow-up branch (`toolbelt git append`). It is better to stack than edit.
- The exception is PR feedback that only asks for documentation or comment changes: update the PR itself, even if it is approved, rather than stacking a follow-up.

## Communication

- When posting anywhere others read (GitHub comments and reviews, Slack, Jira, Notion comments), always identify yourself as AI, e.g. start with "🤖 AI-generated on behalf of Devon:".
- When referring to a PR (or issue), give its link, not just its number: `[title or short label](https://github.com/org/repo/pull/123)`. Never a bare `#123`.
- Always include a link for every relevant resource you mention or rely on, not just PRs: Jira tickets, Slack threads, Notion pages, CI runs, docs. When tying work to a ticket or thread, link the PR to it and the ticket back to the PR, so each can be found from the other.
- Every PR that belongs to a Jira ticket gets the ticket key in its title and a link to the ticket in its body, and the PR is added to the ticket as a remote link (not only pasted in a comment). If a PR has no ticket, say so rather than leaving it out silently. Do this when creating the PR.
- Keep the Jira status in step with the PR: draft PR or no PR yet is "In Progress", open non-draft PR is "In Review" (if the project has that status; if not, say so instead of leaving it "In Progress"), merged is "Done".
- If a step needs the user to run a command or do something themselves (an SSO login, a reinstall, approving a permission, anything outside your reach), stop right away and say exactly what you need, instead of working around it or carrying on with the rest. Resume once they confirm.
- Exception: after changing the `toolbelt` CLI, reinstall it yourself (`uv tool install --reinstall /Users/devonfulcher/git/toolbelt`) and confirm the installed copy has the change. No need to ask.
