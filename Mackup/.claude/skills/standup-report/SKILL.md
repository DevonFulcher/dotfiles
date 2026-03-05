Give a report of what I have been up to the last few days:

1. **Get my Jira tasks**: Use the Jira MCP to find all of my tasks that are "In Progress" or "In Review". Use my Jira account to look up my user.
2. **Gather updates from all sources** — run these in parallel:
   - **Jira-scoped searches**: For each Jira task, search Slack, GitHub, and Notion using the Jira key and task title as search terms.
   - **Broad searches** (to catch work not tied to a Jira ticket):
     - **Slack**: Search for my recent messages from the last 3 days using `from:<@MY_USER_ID>`, sorted by timestamp.
     - **GitHub**: Search for all my recent PRs and commits (author:devonfulcher) from the last 3 days.
     - **Notion**: First search for my user (query_type: "user", query: "Devon Fulcher") to get my user ID. Then search for pages I recently created or edited using `created_by_user_ids` and `created_date_range` (last 5 days), including meeting notes, design docs, and on-call/incident pages.
   - **Correlate results**: Match broad search results back to Jira tasks where possible. Anything that doesn't match a Jira task is flagged as untracked work.
3. **Update Jira tickets**:
   - **Comment**: For each Jira task, add a comment summarizing the current status based on what was found in Slack, GitHub, and Notion.
   - **Status sync**: Based on the gathered evidence (e.g., merged PRs, open review requests, recent activity), verify each ticket has the correct status. If a ticket should be transitioned (e.g., a PR is merged but the ticket is still "In Progress"), transition it to the appropriate status.
   - **Missing tickets**: If there is work found in GitHub/Slack/Notion that doesn't correspond to any Jira ticket, flag it in the report and suggest creating a ticket.
4. **Write the report**: For each Jira task, compile a summary of progress, blockers, and next steps based on the gathered information.
5. **Create a Notion page** in this database: `31abb38ebda780fd8017f7b47ca366a6` with today's date as the title and the standup report as the content.
6. **Open the page**: Run `open <notion_page_url>` to open the newly created page in the browser.
