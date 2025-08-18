# dotfiles

My configurations for Mac.

## Background

Config files are managed with [mackup](https://github.com/lra/mackup).

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
  - `IS_PERSONAL=true`: Set to true if this is a personal laptop.
8. Run `sh signing_commits.sh` to setup signing git commits. The script will copy a public key to the clipboard which needs to be added at `GitHub → Settings → SSH and GPG keys → New SSH key`
9. Adjust `Key repeat rate` and `Delay until repeat` in the Mac Keyboard settings.
10. Install Cursor [here](https://cursor.com/en) and open it to setup.
11. Alacritty has already been installed, but Mac won't allow it to be opened without updating settings. First, try to open Alacritty. Next, in Mac's `Privacy & Settings` allow Alacritty to be used.