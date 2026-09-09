---
name: handle-task
description: Use this skill for any and all tasks or requests.
---
For every user request, determine complexity and behave accordingly:

## Low Complexity
Category:
- Questions or comments that can be addressed immediately.
- No tool calls necessary.
- Factual statements.
- "Single-shot" conversation.
- Takes seconds to complete.

Behavior:
- Respond normally.

## Medium Complexity
Category:
- Questions or comments that require thinking.
- Usage of tool calls or teammates.
- Abstract ideas.
- Can likely be completed with a few conversational turns.
- Takes minutes to complete.

Behavior:
- Do not answer directly. Create a teammate and delegate the question.
- If the work clearly splits into separate tracks (e.g., different areas to explore in parallel), create multiple teammates with scoped briefs instead of one catch-all delegate. See **Task decomposition and multi-teammate distribution** below.

## High Complexity
Category:
- Similar criteria as medium complexity with additional complexity.
- Tasks that take sustained effort to complete.
- Likely require long back-and-forth conversations.
- Takes hours or days to complete.

Behavior:
- Do not answer directly. Create one or multiple teammates and delegate the question.
- Require that the teammate(s) deliver one or more plans before executing on a task.
- Consider creating a doc in Notion to communicate progress, findings, and open questions.
- Prefer **decomposing** the work and **distributing** it across several teammates rather than giving one teammate an oversized brief. See **Task decomposition and multi-teammate distribution** below.

## Agent lifecycle

Every session has one implicit team — there is no setup step. Spawn a teammate by giving the `Agent` tool a `name`:

- **Spawn:** `Agent({name: "schema-audit", prompt: "..."})`. Always pass a `name`; a named teammate is addressable, an unnamed one is a fire-and-forget subagent.
- **Follow up:** `SendMessage({to: "schema-audit", message: "..."})` continues that teammate with its context intact. A fresh `Agent` call starts over from nothing, so reach for `SendMessage` whenever the work is a continuation.
- **List:** `ListAgents` shows live teammates and their names.
- **Async by default:** teammates run in the background and you are notified when they finish. Pass `run_in_background: false` only when your very next action depends on the result and nothing else could usefully happen meanwhile.
- **Never invent results.** If a teammate is still running, say so — do not predict or fabricate what it will report.
- Do not pass `team_name`; it is accepted but ignored.

If a teammate cannot be spawned at all, do the work yourself rather than silently skipping it.

### Relaying user context to teammates

When you pass information to a teammate that originated from the user—or relay user-origin context from one teammate to another—follow the same rules:

- **Minimize summarization and paraphrasing.** Preserve the user’s wording where practical. You may **enhance** or **elaborate** (e.g., add structure, examples, or constraints the user implied) but do not replace their message with a loose restatement.
- **Attribute the source.** Tell the teammate explicitly that the content came from the user (e.g., what the user asked, stated, or attached).
- **Validate before sending.** Confirm that what you forward matches what the user actually provided and that the teammate can interpret and act on it without critical ambiguity or missing pieces.

### Task decomposition and multi-teammate distribution

For medium- and high-complexity work, **default to splitting effort across multiple teammates** when the task has natural seams (separate areas of the codebase, parallel research tracks, distinct skills, or clear sequential handoffs).

**One teammate vs many—decision rule:**
- **Split** when sub-tasks have independent inputs/outputs, can each be specified in roughly two paragraphs or fewer, and would otherwise force one teammate to context-switch across unrelated areas.
- **Keep together** when steps share heavy context, are tightly sequential, or the coordination overhead of splitting would exceed the work itself.

**How to slice and run the work:**
- **Break the task down** into sub-tasks with explicit goals, inputs, outputs, and dependencies. Prefer pieces that can run in parallel when there is no ordering constraint.
- **Assign ownership** so each teammate has a bounded scope; avoid duplicating full context in every brief—give each teammate what it needs plus pointers to shared artifacts (Notion, key files, etc.).
- **Coordinate handoffs:** make downstream steps depend on named deliverables from upstream steps; use `SendMessage` or the shared task list so everyone sees status and blockers.
- **Delegate through named `Agent` teammates** for essentially all sub-work—including quick lookups—so follow-ups stay possible. Use the leader’s own tools directly only for trivial inline checks.

**Teammate brief template** (each delegation should cover these):
- **Goal:** what done looks like in one sentence.
- **Inputs:** files, links, prior decisions, user-origin context (relayed per the rules above).
- **Deliverable:** the concrete artifact or answer expected back, and where to put it.
- **Constraints / dependencies:** ordering vs other teammates, deadlines, things to avoid.
