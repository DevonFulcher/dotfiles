Give a report of what I have been up to the last few days:

1. Search these sources in parallel:
   - **Slack**: Search for my recent messages from the last 3 days using `from:<@MY_USER_ID>`, sorted by timestamp.
   - **GitHub**: Search for my recent PRs (author:devonfulcher) and commits.
   - **Notion**: First search for my user (query_type: "user", query: "Devon Fulcher") to get my user ID. Then run multiple targeted searches filtered by `created_by_user_ids` and `created_date_range` (last 5 days):
     - Search for meeting notes (query: "sync standup meeting notes")
     - Search for docs I authored (query: "design doc RFC proposal review")
     - Search for on-call or incident pages (query: "on-call incident alert review")
2. Focus on contributions and blockers.
3. Provide a few bullet points of what I have been focused on.
4. Resolve the `$GIT_PROJECTS_WORKDIR` environment variable, then write the report to: `<resolved path>/tech-docs/standups/<YYYY-MM-DD>.md`
5. Open the file with the `e` alias: `e <resolved path>/tech-docs/standups/<YYYY-MM-DD>.md`
6. Update this Jira board with my current work. Use the Jira MCP
