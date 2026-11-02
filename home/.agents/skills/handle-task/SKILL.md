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
- Do not answer directly. Delegate a bounded subtask or the task itself to one addressable subagent, then integrate and review its result.
- If the work clearly splits into independent tracks (e.g., different areas to explore in parallel), use multiple agents with scoped briefs. If the work is tightly coupled, assign it to one agent instead of creating overlapping agents. See **Task decomposition and multi-teammate distribution** below.

## High Complexity
Category:
- Similar criteria as medium complexity with additional complexity.
- Tasks that take sustained effort to complete.
- Likely require long back-and-forth conversations.
- Takes hours or days to complete.

Behavior:
- Do not answer directly. Create one or multiple teammates and delegate the question.
- Require that the teammate(s) deliver one or more plans before executing on a task.
- Use a durable shared progress note only when it materially helps and the destination is authorized; otherwise keep the progress in the task and its working files.
- Prefer **decomposing** the work and **distributing** it across several teammates rather than giving one teammate an oversized brief. See **Task decomposition and multi-teammate distribution** below.

## Agent lifecycle across hosts

Use the current host's native subagent tools; do not assume tools from another
host are available.

### Claude

- **Spawn:** use `Agent` with a descriptive `name` and a scoped prompt.
- **Continue:** use `SendMessage` for follow-up so the agent keeps its context.
- **List:** use `ListAgents` to inspect live agents.
- Agents run asynchronously by default. Wait synchronously only when the next
  step depends on the result and no useful independent work can proceed.

### Codex

- **Spawn:** use `multi_agent_v1__spawn_agent` with a scoped prompt. Choose an
  appropriate role such as `explorer`, `plan`, `test`, or `worker` when the tool
  supports it. Full-history forks inherit the parent role, so omit an explicit
  role for those forks. In Codex environments that expose these tools through
  `functions.exec`, call the corresponding `tools.multi_agent_v1__...` method.
- **Continue:** use `multi_agent_v1__send_input` with the agent ID.
- **Wait:** use `multi_agent_v1__wait_agent` only when the result is needed to
  proceed; otherwise keep doing independent work while the agent runs.
- **Close:** close completed agents with `multi_agent_v1__close_agent` when their
  work is reviewed, so they no longer occupy an agent slot.

Do not repeatedly poll unchanged agent state. Never invent results: if an agent
is still running, say so instead of predicting what it will report. If the
current host has no subagent tool or spawning fails, continue the work directly
and say delegation was unavailable; do not imply that an agent was used.

### Relaying user context to teammates

When you pass information to a teammate that originated from the user—or relay user-origin context from one teammate to another—follow the same rules:

- **Minimize summarization and paraphrasing.** Preserve the user’s wording where practical. You may **enhance** or **elaborate** (e.g., add structure, examples, or constraints the user implied) but do not replace their message with a loose restatement.
- **Attribute the source.** Tell the teammate explicitly that the content came from the user (e.g., what the user asked, stated, or attached).
- **Validate before sending.** Confirm that what you forward matches what the user actually provided and that the teammate can interpret and act on it without critical ambiguity or missing pieces.

### Task decomposition and multi-teammate distribution

For medium- and high-complexity work, **default to splitting effort across multiple teammates** when the task has natural seams (separate areas of the codebase, parallel research tracks, distinct skills, or clear sequential handoffs).

**One teammate vs many—decision rule:**
- **Split** when sub-tasks have independent inputs/outputs, can each be specified in roughly two paragraphs or fewer, and would otherwise force one teammate to context-switch across unrelated areas.
- **Keep together** when steps share heavy context, are tightly sequential, or the coordination overhead of splitting would exceed the work itself; assign the cohesive task to one agent rather than skipping delegation.

**How to slice and run the work:**
- **Break the task down** into sub-tasks with explicit goals, inputs, outputs, and dependencies. Prefer pieces that can run in parallel when there is no ordering constraint.
- **Assign ownership** so each teammate has a bounded scope; avoid duplicating full context in every brief—give each teammate what it needs plus pointers to shared artifacts (Notion, key files, etc.).
- **Coordinate handoffs:** make downstream steps depend on named deliverables from upstream steps; use the host's native follow-up tools or a shared task list to communicate status and blockers.
- **Delegate through addressable subagents** for essentially all sub-work—including quick lookups—so follow-ups stay possible. Use the leader’s own tools directly only for trivial inline checks.

**Teammate brief template** (each delegation should cover these):
- **Goal:** what done looks like in one sentence.
- **Inputs:** files, links, prior decisions, user-origin context (relayed per the rules above).
- **Deliverable:** the concrete artifact or answer expected back, and where to put it.
- **Constraints / dependencies:** ordering vs other teammates, deadlines, things to avoid.
