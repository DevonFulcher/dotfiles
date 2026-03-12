Scan my repos and consolidate generally-applicable Claude settings into my user-level config.

1. **Discover per-repo settings**: Find all `.claude/settings.json` and `.claude/settings.local.json` files under `$GIT_PROJECTS_WORKDIR` (exclude this dotfiles repo). Read each one. Note: `settings.json` is team-shared (committed to git), while `settings.local.json` is personal (gitignored). Both can contain generally-applicable settings worth promoting.

2. **Read current user-level settings**: Read `$GIT_PROJECTS_WORKDIR/dotfiles/Mackup/.claude/settings.json` — this is the user-level config (symlinked to `~/.claude/settings.json`).

3. **Identify generally-applicable settings**: For each per-repo settings file, identify settings that are NOT repo-specific. Use this guidance:
   - **Generally applicable** (candidates to promote):
     - `permissions.allow` entries for common CLI tools (git, gh, grep, ls, echo, cat, head, tail, jq, curl, find, sort, wc, which, whoami, uname, mkdir, date, diff, basename, dirname, printf, etc.)
     - `permissions.allow` entries for common MCP tools (Slack, Atlassian/Jira, Notion, GitHub, Datadog, etc.)
     - `permissions.allow` entries for common development tools (uv, pytest, pre-commit, etc.)
     - `sandbox` settings
     - `permissions.allow` for WebSearch
     - `permissions.allow` for Edit, Read, Write with broad patterns
   - **Repo-specific** (leave in the per-repo config):
     - Entries referencing repo-specific paths, scripts, or binaries (e.g., `./gradlew`, `./scripts/*`, `packages/ide/...`, `/tmp/test_mocks.sh`)
     - Entries for repo-specific build tools (e.g., `pnpm --filter @dbt-labs/ide`, `npx vitest`)
     - `hooks` (tied to repo-specific scripts)
     - `enabledMcpjsonServers` (repo-specific MCP server configs)
     - `enableAllProjectMcpServers`
     - `defaultMode` (may be intentionally different per repo)
     - `additionalDirectories` (repo-specific paths)
     - `permissions.deny` entries (keep repo-specific for safety)

4. **Merge into user-level settings**: Draft the updated user-level `settings.json` by merging the generally-applicable settings. Deduplicate entries. Keep existing user-level settings intact.

5. **Present the changes for review**: Show me:
   - The proposed new user-level `settings.json`
   - For each affected repo: what was removed vs. what remains
   - A summary of what's being consolidated

6. **Wait for my approval**: Ask me to confirm before making any changes. Do NOT proceed without explicit approval.

7. **Apply changes**: If I approve:
   - Update `$GIT_PROJECTS_WORKDIR/dotfiles/Mackup/.claude/settings.json` with the consolidated settings
   - Do NOT edit any per-repo settings files — only update the user-level dotfiles config
   - Commit the dotfiles repo change (only the dotfiles repo — do not commit to other repos)
