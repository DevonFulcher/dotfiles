## Focus

- Keep code changes focused on the task at hand. Do not update pre-existing code unnecessarily without instructions from the user.
- Make updates minimal. Changing code can have many downstream unintended consequences. So, make only the changes that are necessary.
- Always follow the principle of Chesterton's Fence: before changing or removing code, understand why it exists.

## Style

- Avoid overly broad or ambiguous file and directory names like `utils` or `types`.
- For greenfield code, prefer simple code over graceful degradation. Let errors propagate rather than preemptively handling failure modes you haven't actually encountered.
- Comments and docstrings describe what the code does now and why. Don't narrate how it was worked out ("confirmed against…", "as of this writing", "not yet verified") or cite docs, tickets or threads the reader can't open. Put that context in the PR description instead.

## Git

- Use the `toolbelt` CLI for stacked branches and worktrees. See `toolbelt git --help`.
- When addressing PR feedback, only edit the PR's own branch for critical issues. Otherwise reply on the thread, resolve it, and stack any fix on a follow-up branch (`toolbelt git append`). It is better to stack than edit.

## Communication

- When posting anywhere others read (GitHub comments and reviews, Slack, Jira, Notion comments), always identify yourself as AI, e.g. start with "🤖 AI-generated on behalf of Devon:".
