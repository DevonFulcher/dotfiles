# Moving to a new laptop

Nothing in this repo depends on the user name (`$HOME` everywhere), so the new
laptop's account may be named differently. In short: **export on the old laptop,
run `bootstrap.sh` on the new one, do the few sign-ins it lists, and run it
again.** The script is safe to re-run; it skips what is done.

## 1. On the old laptop

Commit or discard uncommitted changes in the repos you work in, then run
`toolbelt machine export`. It:

- pushes the branches only this laptop has (open PRs and branches that already
  have an upstream; never by force; branches whose PR is merged or closed are
  left alone and listed);
- stops the `tt ui` service and its webhook forwarders (GitHub allows one
  forwarder per repo, so the old laptop's would block the new one's);
- stores one archive in 1Password: a *Document* item titled "toolbelt machine
  archive", in the `op` CLI's default vault (`--vault NAME` picks another;
  `--to-file PATH` writes a file instead). It holds the secrets, your SSH keys,
  toolbelt's DB and Claude's memory files;
- prints what git still does not carry: uncommitted changes and unpushed commits
  to deal with, and how many stashes there are (not carried).

It refuses while an autonomous run is active, a decision is pending, or
`secrets/machine.sh` says `IS_PERSONAL=true` (`--force` overrides). What is
carried is in toolbelt's `docs/machine-move.md`.

## 2. On the new laptop

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/DevonFulcher/dotfiles/main/bootstrap.sh)"
```

(or `sh bootstrap.sh` from a clone; `DRY_RUN=1` prints the steps without running
them.) It stops once, for your **1Password sign-in** (the app, then Settings >
Developer > "Integrate with 1Password CLI"). Everything else it does by itself:

- installs Homebrew, 1Password, git, the formulae and casks listed in the
  script (including iTerm2, the Monaspace font, Cursor and DisplayLink), Claude Code, asdf and
  its tools, and the uv tools;
- restores your SSH keys first, then clones `dotfiles`, `dotfiles-private` and
  `toolbelt` under `$GIT_PROJECTS_WORKDIR` (default `~/git`);
- installs toolbelt, runs `toolbelt dotfiles link` and `toolbelt machine import`
  (secrets, the toolbelt DB with the old home rewritten to the new one, the repos
  toolbelt tracks cloned, their worktrees recreated);
- runs `toolbelt machine setup` (`asdf install` and `uv sync` in each tracked
  repo's checkout; `toolbelt machine setup --worktrees` does the worktrees too);
- installs the Claude plugins and MCP servers, builds the `tt ui` web app, loads
  the launchd agents, sets the keyboard repeat, starts yabai and skhd, and checks
  `secrets/machine.sh`.

It ends by pointing here and listing what it found still missing or failed:
steps that errored, and `gh auth login` / `claude auth login` while either is
still needed. Do those first, re-running `bootstrap.sh` when it says to.

## 3. By hand afterwards

These are the steps the script cannot check, so it does not list them.

1. Open a new terminal (or run `exec zsh`) so `PATH` picks up `~/.local/bin` and
   asdf.
2. System Settings > Privacy & Security: Accessibility for yabai and skhd, Screen
   Recording for yabai. Reboot for DisplayLink, then allow it there too (Screen
   Recording).
3. Run `toolbelt dotfiles status`: it should say 0 need attention.
4. Once the old laptop is retired, and only if this laptop got its own new SSH
   key, remove the old laptop's key from GitHub. If you restored the key from
   the archive, both laptops share it: leave it.

Also worth knowing:

- Repos that are not under `~/git` are not recreated.
- `DEVSPACE_NAMESPACE` defaults to `dev-$USER`; set it in `secrets/machine.sh` when
  the namespace differs from the account name.

## Intentionally not carried

Claude transcripts, caches and histories (only per-project memory files move);
the Claude app's data (sign in again); `~/.asdf` and `~/.npm` (reinstalled by
`asdf install`); `~/.zsh_history` (opt in with `--include-history`);
`.venv`s and other build output; `.claude/` and `.cursor/` project folders inside
the repos; uncommitted and unpushed work (listed by the export instead);
machine-specific toolbelt tables (GitHub lookup caches, transcript offsets,
tool-call logs), which refill on their own.

## Secrets without the archive

If you do not use the archive, add by hand to `./secrets` (gitignored):

- `GITHUB_PERSONAL_ACCESS_TOKEN`: access token for github-mcp-server.
- `GITHUB_PERSONAL_EMAIL`: personal email used in GitHub.
- `./secrets/toolbelt.sh`: `export JIRA_API_TOKEN=...`, the Atlassian API token `tt ui` uses to show each task's title and status (the account email and site are in toolbelt's config). The `tt ui` launchd service sources this file itself (see its plist), since `.zshenv` does not, so reload the service after changing it.
- `./secrets/machine.sh`, sourced by `.zshenv` so non-interactive shells see it too. No tokens in it:
  - `export IS_PERSONAL=true`: set on a personal laptop. Toolbelt then makes `--task` optional on `tt git append`.

Then run `sh signing_commits.sh` to create a signing key (it copies the public
key to the clipboard for GitHub > Settings > SSH and GPG keys).
