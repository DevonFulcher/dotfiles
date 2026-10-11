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
- `tt dotfiles check`: scan this public repo for secret-looking content.

`tt dotfiles link` also points this repo's `core.hooksPath` at `.githooks`, whose
`pre-commit` hook runs `tt dotfiles check` and rejects a commit that contains
secret-looking content (findings show `path:line:rule`, never the match). Add
`tt:allow-secret` to a line to allow a deliberate false positive. To test the
hook: `sh .githooks/test-pre-commit.sh`.

## Setup

1. [Install Homebrew](https://brew.sh/)
2. Install git: `brew install git`
3. Make the expected directory for git projects and cd into it:
`mkdir $HOME/git && cd $HOME/git`
4. Clone this repo: `git clone git@github.com:DevonFulcher/dotfiles.git`
5. Run the setup script: `cd dotfiles && sh bootstrap.sh`
6. Download Monaspace fonts [here](https://github.com/githubnext/monaspace/releases) and install `MonaspaceNeon-Regular.otf` by double-clicking on it.
7. Add secrets shell files in the `./secrets` directory:
  - `GITHUB_PERSONAL_ACCESS_TOKEN`: Access token for github-mcp-server.
  - `GITHUB_PERSONAL_EMAIL`: Personal email used in GitHub.
  - Per-machine flags go in `./secrets/machine.sh`, which `.zshenv` sources so non-interactive shells (agents, `zsh -c`) see them too. Do not put tokens in it:
    - `export IS_PERSONAL=true`: Set to true if this is a personal laptop. Toolbelt then makes `--task` optional on `tt git append`.
8. Run `sh signing_commits.sh` to setup signing git commits. The script will copy a public key to the clipboard which needs to be added at `GitHub → Settings → SSH and GPG keys → New SSH key`
9. Adjust `Key repeat rate` and `Delay until repeat` in the Mac Keyboard settings.
10. Install Cursor [here](https://cursor.com/en) and open it to setup.