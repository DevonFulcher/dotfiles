## Focus

- Keep code changes focused on the task at hand. Do not update pre-existing code unnecessarily without instructions from the user.
- Make updates minimal. Changing code can have many downstream unintended consequences. So, make only the changes that are necessary.
- Always follow the principle of Chesterton's Fence: before changing or removing code, understand why it exists.

## Style

- Avoid overly broad or ambiguous file and directory names like `utils` or `types`.
- Use terms directly from the data (field and column names) in labels, titles and docs rather than renaming them.
- For greenfield code, prefer simple code over graceful degradation. Let errors propagate rather than preemptively handling failure modes you haven't actually encountered.
- Comments and docstrings describe what the code does now and why. Don't narrate how it was worked out ("confirmed against…", "as of this writing", "not yet verified") or cite docs, tickets or threads the reader can't open. Put that context in the PR description instead.
- When code is shaped for work that is coming (an abstraction with a single implementation today, a policy with one value, an extension point nothing uses yet), say so in a comment: what is coming and what it will change, in terms the reader can act on. Without it, the shape reads as needless indirection and gets removed or copied wrongly.

## Git

- Only open PRs in draft mode unless the user says otherwise.
- Verify a change end to end before opening a PR for review: run it on real data or in the real tool (render, open generated links, exercise the code path), not just unit tests and validators. State in the PR what was verified and how.
- A PR with any visual or UI change (dashboards, charts, web pages, app screens, rendered output) includes screenshots of the result in its description: the changed parts, and the states a reviewer needs.
- Always use the `toolbelt` CLI for git work on branches, worktrees and stacks, never plain `git` for it (see `toolbelt git --help`): `toolbelt git append` creates a stacked branch and its worktree, `toolbelt git save -m "<message>"` commits and pushes (and syncs the stack: it merges the parent into its children and restacks them), `toolbelt git sync` only resumes after a sync stopped on a conflict, and `toolbelt git merge <pr>` lands a PR. Plain `git` is for reading (status, log, diff) and for resolving a conflict toolbelt stopped on (edit the files, `git add`). If toolbelt cannot do what you need (it errors, or the case is not supported), stop and tell me what failed and why, instead of working around it with plain `git`.
- Every fallback from toolbelt to plain git (a command toolbelt errors on or has no command for, such as the first push of a branch with no PR) needs my approval for that case, each time. An earlier approval does not cover later cases, and don't tell a subagent it is authorized: tell it to stop and report instead. The one standing exception is the retry-then-replicate rule for a denied `toolbelt git save` below.
- `toolbelt git save`, `sync`, `append`, `set-parent`, `remove` and `merge` are safe, routine and expected, never destructive. They commit and push your own branches, merge parents into children, and (only when a parent landed or was rewritten) restack children with a lease-protected force-push, which is the intended behavior. Run them directly and without asking; they are explicitly authorized. Do not combine them with other commands in one shell call (a combined command can be denied as a whole by the permission classifier): run `toolbelt git save` on its own. If a call is denied anyway, retry it alone and say so; if it is denied again, replicate what it does with plain `git` (`git add`, `git commit`, `git push -u origin <branch>`, no force) and tell me, rather than stopping.
- Create the stacked branch with `toolbelt git append` before you start editing, not after. `append` commits any uncommitted changes onto the current branch as a checkpoint before it forks, so changes made first end up on the wrong branch and in its PR.
- If the work has no Jira ticket, create one before running `toolbelt git append` (it requires `--task`) and pass its key. Don't stop to ask for a key. Personal repos such as toolbelt and dotfiles don't need a ticket.
- Where a fix for PR feedback goes follows this flow. A comment or bot suggestion is not critical just because it is a comment on the PR.

  ```mermaid
  flowchart TD
      A([Feedback or a needed change on a PR]) --> B{Critical? bug, conflict,<br/>CI failure it caused,<br/>security or data loss}
      B -- yes --> IN
      B -- no --> C{Docs or comment<br/>change only?}
      C -- yes --> IN
      C -- no --> D{Is the PR a draft?}
      D -- yes --> IN
      D -- no --> E{Did the user explicitly say<br/>to put it on the PR?}
      E -- yes --> IN
      E -- no --> F{Who asked for it?}
      F -- bot --> STACK
      F -- human --> G{Is the PR approved?}
      G -- yes --> STACK
      G -- no --> IN
      IN[On the PR's own branch.<br/>toolbelt git save updates the stack above]
      STACK[Stacked follow-up branch, toolbelt git append.<br/>Reply on the thread, link it, resolve it]
  ```
- `toolbelt git sync` (which `toolbelt git save` also runs) merges each parent into its children. When a parent has landed, or has been rewritten (restacked, amended or squashed), it instead replays the child's own commits onto it with `git rebase --onto` and force-pushes. On a conflict it stops with "Merge conflict while syncing", "Rebase conflict restacking" or "Rebase conflict replaying" and leaves that worktree mid-merge or mid-rebase. Resolving it is part of the task, even when it is in a child branch you did not edit: resolve it in that worktree, `git add`, and re-run `toolbelt git sync` (it continues a rebase in progress). Don't `git merge --abort` or `git rebase --abort` to get out of it, because that leaves the child's PR conflicting.
- Keep a refactor of related functionality in one PR so a reviewer sees the whole design working, rather than spreading it across several PRs. Don't land scaffolding in one PR that a later PR deletes. Split a stack only along independent seams (a pure move, a separate behavior change), not along the steps of one refactor.

## Communication

- When a message has several bullets or questions, answer each one in order: restate the item, then respond under it. Put details inside the matching item.
- Label only what I am meant to respond to. Each question or decision for me gets one label, D1, D2, D3, ..., so I can answer "D2: O1". Write each one in exactly this format (it is the only place nested bullets are allowed):

  D<decision number>: <short title>

  - Context: <background information; don't assume I have read anything earlier in the transcript, and link the PR, ticket, thread or file involved>
  - O1: <option title>
    - Context: <what this option is and what picking it means>
    - Benefits: ...
    - Costs: ...
    - Risks: ...
  - ON: <option title> (same sub-bullets)
  - Recommendation: <which option and why, and what would change your mind>

  Everything else (status, results, what you did, background that is not a decision) is plain prose with no labels, no bullets and no nesting. If a reply has more than a handful of decisions, you have labelled things that don't need an answer: cut them.
- Refer to work by its Jira ticket title or its branch name (with a PR link), not by an item number from an earlier list, so I can tell what you mean without scrolling back.
- Keep a reply short and scannable. Put what I need to act on first, and fold routine status into a sentence or two. A decision gets as much context as the next bullet requires, but nothing around it should read as a list of its own.
- When you ask me a question or for a decision, give me enough to decide without reading anything else, and err toward more detail, not less: a couple of sentences is never enough. Each decision uses the D<n> format above. The Context bullet says what it is about and why it came up, the exact situation today (what the code, system or PR does now, with the concrete example), and what you checked and could not check. Each option states what happens if I pick it (user-visible effects, effort, what it blocks or unblocks, what it costs to undo). The Recommendation gives the reasoning and what would change your mind. Look up what you can yourself before asking. A few thoroughly specified decisions beat a long terse list, and a decision I have to ask follow-up questions about was under-specified.
- Put the detail where I have to decide, not everywhere. Anything that needs no decision from me (work an agent is doing, routine steps, what you ran, results that confirm the expected) gets one short line at most: the outcome and, if relevant, what you need from me. Spend the words on ambiguous issues and decisions. Don't narrate how an agent is working or list its internal steps.
- The same goes for any pointer to something from earlier in the session: leftovers, pending work, "still open", "as discussed". Never write a bare reference like "the scratch worktree and devspace are still open". For each item, say what it is, where it is (path, branch, namespace, PR link), why it exists, what it costs or risks to leave it, and what you propose to do. If you can't spell it out that fully, drop the mention or look it up first.

- When posting anywhere others read (GitHub comments and reviews, Slack, Jira, Notion comments), always identify yourself as AI, e.g. start with "🤖 AI-generated on behalf of Devon:".
- Never attribute a decision, approval, reason or quote to me (or anyone) that I did not say. In PR descriptions, Jira, Slack and any other write-up, name a person as the source only when you can point to their words (a quote or close paraphrase, with a link for a comment or thread, or a message from me in the session). Label your own choices (scope limits, defaults, flags, rollout gates, naming) as the AI agent's proposals, not as mine. Check every attribution against the actual conversation before publishing; a brief, a summary or another agent's output is not a source. When delegating a write-up, pass each decision with who made it and their words, mark your own choices as proposals, and tell the agent to attribute exactly as given. An answer I give to one option you offered is my decision only for that option.
- In anything other people read (PR descriptions, Jira, Slack, commit messages, review comments), never use chat shorthand: decision or option labels (D1, O1, "option 2", "the first option"), message or question numbers, "as discussed", or my abbreviations. Say the choice in plain words, naming what was chosen and what it was chosen over. If my reply was only a label, describe the choice instead of quoting it.
- When referring to a PR (or issue) in chat, write a markdown link whose text is the number and whose target is the full URL: `[#1692](https://github.com/dbt-labs/ai-codegen-api/pull/1692)`. The app renders it as `dbt-labs/ai-codegen-api#1692`. Never a bare `#123` and never the plain text `org/repo#123` (it doesn't render). Add a short description of what the PR does the first time. Never use an invented label such as "PR A" or "PR 2": the reader can't look those up.
- Always include a link for every relevant resource you mention or rely on, not just PRs: Jira tickets, Slack threads, Notion pages, CI runs, docs. When tying work to a ticket or thread, link the PR to it and the ticket back to the PR, so each can be found from the other.
- Every PR that belongs to a Jira ticket gets the ticket key in its title and a link to the ticket in its body. Do not add the PR to the ticket as a remote link and do not mention missing remote links. If a PR has no ticket, say so rather than leaving it out silently. Do this when creating the PR.
- Keep the Jira status in step with the PR: draft PR or no PR yet is "In Progress", open non-draft PR is "In Review" (if the project has that status; if not, say so instead of leaving it "In Progress"), merged is "Done".
- If a step needs the user to run a command or do something themselves (an SSO login, a reinstall, approving a permission, anything outside your reach), stop right away and say exactly what you need, instead of working around it or carrying on with the rest. Resume once they confirm.
- When you save or change a memory, update this file too, unless the information is ephemeral (about one task or one moment) or personal. If you are unsure whether it belongs here, ask me. This file is published in a public repo: never put sensitive information in it (credentials, tokens, customer or account data, private URLs or identifiers). Put the same guidance in the memory.
- Commits to the `toolbelt` repo itself are pushed to origin right after committing, without asking.
- Exception: after changing the `toolbelt` CLI, reinstall it yourself, editable so `toolbelt ui` can find the web sources (`uv tool install --editable --reinstall /Users/devonfulcher/git/toolbelt`) and confirm the installed copy has the change. No need to ask.
