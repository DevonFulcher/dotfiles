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

`bootstrap.sh` also installs the toolbelt Claude Code mods (`toolbelt-claims`,
`toolbelt-usage`; user scope) and registers the `toolbelt-decisions` MCP server
(`claude mcp add --scope user toolbelt-decisions -- toolbelt decisions mcp`) by
running `$GIT_PROJECTS_WORKDIR/toolbelt/claude-plugin/install.sh` when it exists;
re-run that script to update them.

## Setting up a laptop

On the old laptop run `toolbelt machine export`; on the new one run `bootstrap.sh`
(`sh -c "$(curl -fsSL https://raw.githubusercontent.com/DevonFulcher/dotfiles/main/bootstrap.sh)"`).
It is safe to re-run, and `DRY_RUN=1 sh bootstrap.sh` prints the steps without
running them. What each side does, the few steps that stay manual and what is not
carried are in [docs/new-laptop.md](docs/new-laptop.md).
