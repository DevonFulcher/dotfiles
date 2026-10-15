---
name: pr-description
description: The standard for every pull request description. Use whenever writing, opening, editing, improving or reviewing a PR description or PR body, including via `gh pr create` or `gh pr edit`. Defines the five sections (What, Why, How, Verified, Details), mermaid diagrams, and the PR conventions (Jira key, draft, links, attribution).
---

Every PR description has exactly these `##` sections, in this order: `What`, `Why`, `How`, `Verified`, `Details`.

Keep everything except `Details` high level. A reviewer must understand the whole PR from What/Why/How/Verified in under a minute.

## Sections

- **What**: 1-3 sentences on the change and its user-visible or reviewer-visible outcome. Then a ticket line: `Ticket: [KEY](url)`, or an explicit `No ticket`.
- **Why**: the motivation, the problem, what happens without the change. Link the originating discussion, PR review, Slack thread or incident when there is one (full URLs). Don't invent numbers or link what you cannot open.
- **How**: the approach in a few sentences, normally with a mermaid diagram (below).
- **Verified**: a short bullet list of what was verified and how: the exact command or run, with a link to the real CI run, PR check or observed output, and the numbers (e.g. test counts). Then an explicit `Not verified` list: what was reasoned but not observed, what could not be run (credentials, Linux vs macOS, prod behavior, load), and known caveats. Never claim a check passed that you did not observe; keep "observed" and "reasoned" separate. A visual or UI change includes screenshots of the changed parts and the states a reviewer needs.
- **Details**: everything else, in a collapsible toggle so the body stays short:

  ```
  <details>
  <summary>Details</summary>

  ...content...

  </details>
  ```

  The blank line after `<summary>` is required so markdown renders. Put here: file-by-file or job-by-job changes, event/decision matrices and tables, full verification output, edge cases, rejected alternatives, follow-ups, rollout/rollback notes, caveats and risks, lock/dependency changes. Mermaid diagrams may appear here too. Details must still be accurate and scannable: use headings and tables, not walls of text.

## Mermaid diagrams: use them more often

Put a diagram in `How` whenever the change involves a flow, sequence, state, branching conditions, pipeline/job dependencies, a request path, a stack of PRs, architecture, or before/after behavior. When behavior changes, show before and after. Skip it only for trivial changes (typo, version bump, one-line fix) and say why in `How`.

- Pick the type that fits: `flowchart`, `sequenceDiagram`, `stateDiagram-v2`, `gitGraph`.
- Keep it small (roughly 4-12 nodes), label edges with the condition, and use real names from the code (job names, functions, files). No decorative diagrams.
- Use color (`classDef`) sparingly, only to mark what changed.
- Write valid GitHub-flavored mermaid in a fenced `mermaid` block. Avoid features GitHub does not support. Quote node labels containing parentheses, brackets, colons or slashes. No HTML in labels unless known to work.

## PR conventions

- Title starts with the Jira key: `KEY-123: <title>`.
- Open PRs as draft unless told otherwise.
- Link the Jira ticket in the body and add the PR to the Jira issue as a remote link (not only a comment). Keep status in step: draft or in progress = In Progress, open non-draft = In Review, merged = Done. With no ticket, say so explicitly.
- Refer to related PRs, such as others in a stack, by full markdown link plus a short description of what each does: `[#1692](https://github.com/org/repo/pull/1692) adds X`. Never a bare `#123`, never invented labels like "PR A".
- Public repos (for example dbt-labs/dbt-mcp) must not mention internal repos, internal Jira URLs or internal Slack.
- Documentation- or comment-only changes still get all five sections, but each may be one line.
- The last line of every description is `🤖 Generated with AI assistance`.

## Improving an existing description

1. Read the diff and the existing body: `gh pr view <n> --json title,body,files,commits` and `gh pr diff <n>`.
2. Sort the old body into high level vs detail. Move all detail into `Details`; add the How diagram.
3. Keep every verified fact, caveat and link from the old body. Relocate information, never drop it. Re-check cheap claims against the repo instead of trusting old text.
4. Write the new body to a temp file and run `gh pr edit <n> --body-file <file>`. Never pass large bodies inline.
5. Re-read the result: `gh pr view <n> --json body --jq .body`. Check the mermaid fences and the `<details>` structure are intact.
6. Validate mermaid before publishing if a validator is available: `npx -y -p @mermaid-js/mermaid-cli mmdc -i diagram.mmd -o /tmp/out.svg`, or parse with the `mermaid` package. If it cannot be installed, say so and keep the diagram simple.

## Template

````markdown
## What
<1-3 sentences: the change and its outcome.>

Ticket: [KEY-123](https://example.atlassian.net/browse/KEY-123)

## Why
<Problem or motivation, and what happens without it. Link the originating thread.>

## How
<Approach in a few sentences.>

```mermaid
<diagram>
```

## Verified
- <what was checked>: `<command>` or <link to CI run>, <numbers>.

Not verified:
- <reasoned but not observed, or could not run>

<details>
<summary>Details</summary>

### Changes
| File or job | Change | Why |
|---|---|---|

### Edge cases, alternatives, rollout, follow-ups
...

</details>

🤖 Generated with AI assistance
````

Example `How` diagram (generic):

```mermaid
flowchart LR
  req["request"] --> gate{"flag on?"}
  gate -->|yes| a["service A: new path"]
  gate -->|no| b["service A: old path"]
  a --> jobB["job B: reindex"]
  classDef changed fill:#fde68a,stroke:#b45309
  class a,jobB changed
```
