Give a report of what I have been up to the last few days:

1. **Get my Jira tasks**: Use the Jira MCP to find all of my tasks that are "In Progress" or "In Review". Use my Jira account to look up my user.
2. **Gather updates from all sources** — run these in parallel:
   - **Jira-scoped searches**: For each Jira task, search Slack, GitHub, and Notion using the Jira key and task title as search terms.
   - **Broad searches** (to catch work not tied to a Jira ticket):
     - **Slack**: Search for my recent messages from the last 3 days using `from:<@MY_USER_ID>`, sorted by timestamp.
     - **GitHub**: Search for all my recent PRs and commits (author:devonfulcher) from the last 3 days.
     - **Notion**: First search for my user (query_type: "user", query: "Devon Fulcher") to get my user ID. Then search for pages I recently created or edited using `created_by_user_ids` and `created_date_range` (last 5 days), including meeting notes, design docs, and on-call/incident pages.
   - **Correlate results**: Match broad search results back to Jira tasks where possible. Anything that doesn't match a Jira task is flagged as untracked work.
3. **Identify Jira follow-ups (do not mutate Jira)**: Based on gathered evidence, decide what *should* happen in Jira, but only record that in the report—do not add comments, transition statuses, or create tickets via MCP.
   - **Comment needed**: For each Jira task where a standup-style comment would help, note the suggested summary (what you would have posted).
   - **Status mismatch**: If evidence suggests the wrong status (e.g., PR merged but ticket still "In Progress"), note the ticket, current status, and recommended status (and why).
   - **Missing tickets**: If work in GitHub/Slack/Notion has no matching Jira ticket, flag it under "Other activity" and suggest creating a ticket (title/scope hint).
4. **Write the report**: Use the bullet point format below. For each Jira task, list concrete accomplishments, current state, and next steps as bullets. Add an "Other activity" section for untracked work, then end with **Tickets needing updates** (recommended Jira actions only—nothing applied via MCP).

**Output format** (use this exact structure):

```
### <TICKET-KEY> — <summary>
- <concrete accomplishment or status update>
- <concrete accomplishment or status update>
- Next: <what's coming next>

### <TICKET-KEY> — <summary>
- ...

### Other activity
- <item not tied to a Jira ticket>
- <item not tied to a Jira ticket>

## Tickets needing updates
- **<TICKET-KEY>**: <what to do in Jira — e.g. add comment: …; or transition In Progress → Done because …>
- **<TICKET-KEY>**: ...
```

If no Jira actions are suggested, keep the heading and use a single bullet: `- No Jira updates suggested.`

Rules for the bullets:
- Lead with what was done, not what the ticket is about — the reader already knows the ticket context
- Reference specific artifacts: PR numbers, Notion doc names, Slack channels, deploy targets
- Keep each bullet concise
- Use "Next:" prefix for forward-looking items
- Flag stale tickets (no activity in 30+ days) and suggest closing or reassigning (in **Tickets needing updates**, not by changing Jira)

Rules for **Tickets needing updates**:
- Each item is something you should do in Jira yourself: suggested comments (concise), status transitions with current → target and rationale, stale-ticket close/reassign, or "create ticket for …" when work is untracked
- Do not describe changes as already applied

1. **Create a Notion page** in this database: `31abb38ebda780fd8017f7b47ca366a6` with today's date as the title and the standup report as the content.
2. **Open the page**: Run `open <notion_page_url>` to open the newly created page in the browser.
