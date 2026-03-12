Report on all PRs I have open. Ignore PRs in archived repos. This skill is READ-ONLY — do not modify any PRs, repos, or external systems.

1. **Fetch my open PRs**: Use `gh` to list all open PRs authored by me across all repos.
2. **Gather status for each PR** — run these in parallel:
   - Check CI status (passing, failing, pending)
   - Check review status (approved, changes requested, awaiting review)
   - Check for merge conflicts
   - Check for unresolved review comments
3. **Categorize and report**: Output a report with three sections:

```
## Waiting on CI
<PRs where CI is failing or pending>

## Waiting on Review
<PRs where CI passes but awaiting review or re-review>

## Waiting on Me
<PRs with changes requested, unresolved comments, or merge conflicts>
```

Each PR entry should use this format:
```
- **<title>** — <link-to-pr>
  - CI: <passing | failing | pending>
  - Reviews: <approved | changes requested | awaiting review>
  - Conflicts: <yes | no>
  - Unresolved comments: <count>
  - Age: <days since opened>
```

Rules:
- Do NOT push code, resolve comments, fix conflicts, re-run CI, or make any mutations
- Do NOT create or modify Jira tickets, Notion pages, Slack messages, or any external resources
- Only read and report
