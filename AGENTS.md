# AGENTS.md

## Git workflow

- For the dotfiles and toolbelt repositories, work and commit directly on `main`; do not create task branches or pull requests unless explicitly requested. Use `toolbelt git save` to commit and push verified changes.

## Shared instructions and skills

- Keep repository instructions in `AGENTS.md`. Manage `CLAUDE.md` as a compatibility symlink through `dotfiles.toml`, not as a second copy of the instructions.
- Keep shared skill sources in `home/.agents/skills`. The manifest installs them into `~/.agents/skills` and provides Claude compatibility links under `~/.claude/skills`; preserve each app's separate `synced/` directory.
