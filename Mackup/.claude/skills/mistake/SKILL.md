---
name: mistake
description: Reflect on a mistake and update the appropriate config files and memory to prevent recurrence
---
You made a mistake. Pause, reflect, and update the right files so it doesn't happen again.

## Step 1: Reflect on what went wrong

Describe the mistake clearly:
- What did you do?
- What should you have done instead?
- Why did it happen? (missing context, wrong assumption, ignored instruction, etc.)

## Step 2: Determine where the fix belongs

Choose the right location based on scope:

| Scope | Where to update |
|---|---|
| Applies to a specific project repo | That repo's `AGENTS.md` or `CLAUDE.md` |
| Applies to all projects for this user | `~/.claude/CLAUDE.md` (user-level) |
| Skill-specific behavior | The relevant `.claude/skills/<skill>/SKILL.md` |

When in doubt, prefer the most specific scope. A rule about a specific repo's test runner belongs in that repo's `AGENTS.md`, not the global user config.

## Step 3: Write the fix

- Read the target file before editing it
- Add a concise, actionable bullet — one line, not prose
- Place it in the most relevant existing section, or under `## lessons learned` in AGENTS.md
- If the mistake involved a skill, update that skill's workflow steps directly
- Do not duplicate rules that already exist — if a similar rule is there, sharpen it instead

## Step 4: Update memory

Update your memory as appropriate for this mistake — correct any wrong entries, remove anything that led to this mistake, and add new entries for patterns worth persisting.

## Step 5: Tell the user what you changed

Summarize:
- The mistake
- The file(s) updated and the exact rule added/changed
- Whether memory was updated and how

Keep it short. No need to re-litigate the full incident — just confirm the fix is in place.
