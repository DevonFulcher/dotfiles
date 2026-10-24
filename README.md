# dotfiles

My configurations for Mac.

## Background

Config files are linked into `$HOME` by `toolbelt dotfiles` (alias `tt dotfiles`)
from the `dotfiles.toml` manifest in this repo, layered under the manifest in
the private `dotfiles-private` repo. Which repos are used is set by
`dotfiles.repos` in `~/.config/toolbelt/config.yaml`.

- `tt dotfiles status`: read-only report of what is linked.
- `tt dotfiles link [--dry-run]`: link everything; anything displaced is first
  moved into `~/.toolbelt/dotfiles-backups/<timestamp>/`.
- `tt dotfiles check`: scan this public repo for secret-looking content and for a literal `/Users/<name>/` path (use `$HOME` or `~`; a path that must stay gets `tt:allow-user-path` on its line).

`bootstrap.sh` also installs the toolbelt Claude Code mods (`toolbelt-claims`,
`toolbelt-usage`; user scope) and registers the `toolbelt-decisions` MCP server
(`claude mcp add --scope user toolbelt-decisions -- toolbelt decisions mcp`) by
running `$GIT_PROJECTS_WORKDIR/toolbelt/claude-plugin/install.sh` when it exists;
re-run that script to update them.

`tt dotfiles link` also points this repo's `core.hooksPath` at `.githooks`, whose
`pre-commit` hook runs `tt dotfiles check` and rejects a commit that contains
secret-looking content (findings show `path:line:rule`, never the match). Add
`tt:allow-secret` to a line to allow a deliberate false positive. To test the
hook: `sh .githooks/test-pre-commit.sh`.

## Setup: moving to a new laptop

Two commands, one on each machine. Nothing in this repo depends on the user name
(`$HOME` everywhere), so the new laptop's account may be named differently.

1. **Old laptop**: `toolbelt machine export`. It stores one archive in 1Password
   (the document "toolbelt machine archive"; `--to-file PATH` writes a file
   instead) and prints a checklist of work git does not carry: uncommitted
   changes, unpushed commits and stashes. Commit and push those first. It refuses
   while an autonomous run is active, a decision is pending, or
   `secrets/machine.sh` says `IS_PERSONAL=true`; `--force` overrides. What is
   carried is documented in toolbelt's `docs/machine-move.md`.
2. **New laptop**: run the bootstrap (or `sh bootstrap.sh` from a clone;
   `DRY_RUN=1` prints the steps without running them):

   ```sh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/DevonFulcher/dotfiles/main/bootstrap.sh)"
   ```

   It installs Homebrew, 1Password and its CLI, **stops for your 1Password
   sign-in**, fetches the archive, restores the SSH keys first (the private repos
   are cloned over SSH), clones `dotfiles`, `dotfiles-private` and `toolbelt`
   under `$GIT_PROJECTS_WORKDIR` (default `~/git`), installs the rest (Homebrew,
   asdf, uv tools, Claude Code), runs `toolbelt dotfiles link`, runs
   `toolbelt machine import` (secrets, toolbelt's DB with the old home rewritten
   to the new one, clones the repos toolbelt tracks, recreates their worktrees),
   installs the Claude plugins and loads the launchd agents. It can be re-run: it
   skips what is done. It ends by printing the checklist below with anything that
   failed added.

### Manual steps

- Sign in to 1Password (the script waits for it): app, then Settings >
  Developer > "Integrate with 1Password CLI".
- `gh auth login` with the work account, then
  `gh extension install github/gh-stack` and `gh extension install cli/gh-webhook`.
- Authorize the restored SSH key for the GitHub org's SSO (GitHub > Settings >
  SSH and GPG keys > Configure SSO). Until then cloning the org's repos fails;
  `toolbelt machine import` lists them under "Still to do", and re-running it
  after authorizing clones them. Once the old laptop is retired, remove its key
  from GitHub: the private key now also lives in the 1Password archive.
- macOS permissions: Accessibility for yabai and skhd (System Settings > Privacy &
  Security), then `yabai --start-service` and `skhd --start-service`.
- Approve any MDM / company software prompts.
- Sign in to Raycast, Cursor (and install its extensions) and the 1Password
  browser extension.
- Check `secrets/machine.sh`: `IS_PERSONAL` must not be `true` on a work laptop.
- Install `MonaspaceNeon-Regular.otf` from
  [Monaspace](https://github.com/githubnext/monaspace/releases).
- Adjust `Key repeat rate` and `Delay until repeat` in the Keyboard settings.
- Worktrees come back as plain checkouts: run `uv sync` / `asdf install` in the
  ones you use. Repos not under `~/git` are not recreated.
- `DEVSPACE_NAMESPACE` defaults to `dev-$USER`; set it in `secrets/machine.sh`
  when the namespace differs from the account name.
- Open a new terminal and run `toolbelt dotfiles status`.

### Intentionally not carried

Claude transcripts, caches and histories (only per-project memory files move);
the Claude app's data (sign in again); `~/.asdf` and `~/.npm` (reinstalled by
`asdf install`); `~/.zsh_history` (opt in with `--include-history`);
`.venv`s and other build output; `.claude/` and `.cursor/` project folders inside
the repos; uncommitted and unpushed work (listed by the export instead);
machine-specific toolbelt tables (GitHub lookup caches, transcript offsets,
tool-call logs), which refill on their own.

### Secrets without the archive

If you do not use the archive, add by hand to `./secrets` (gitignored):

- `GITHUB_PERSONAL_ACCESS_TOKEN`: access token for github-mcp-server.
- `GITHUB_PERSONAL_EMAIL`: personal email used in GitHub.
- `./secrets/toolbelt.sh`: `export JIRA_API_TOKEN=...`, the Atlassian API token `tt ui` uses to show each task's title and status (the account email and site are in toolbelt's config). The `tt ui` launchd service sources this file itself (see its plist), since `.zshenv` does not, so reload the service after changing it.
- `./secrets/machine.sh`, sourced by `.zshenv` so non-interactive shells see it too. No tokens in it:
  - `export IS_PERSONAL=true`: set on a personal laptop. Toolbelt then makes `--task` optional on `tt git append`.

Then run `sh signing_commits.sh` to create a signing key (it copies the public
key to the clipboard for GitHub > Settings > SSH and GPG keys).
