echo "Installing software with shell scripts"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
curl https://cursor.com/install -fsS | bash
curl -fsSL https://claude.ai/install.sh | bash

echo "Installing software with Homebrew"
brew tap FelixKratz/formulae # used for borders
brew install \
  mackup \
  eza \
  bat \
  gh \
  fzf \
  git-delta \
  difftastic \
  direnv \
  beads \
  koekeishiya/formulae/yabai \
  koekeishiya/formulae/skhd \
  borders \
  rip2 \
  1password-cli \
  asdf \
  starship \
  sst/tap/opencode \
  tmux \
  uv # needed before asdf to install toolbelt, which links the dotfiles
# Install UI applications with --cask
brew install --cask \
  raycast \
  iterm2

echo "Installing toolbelt (provides 'toolbelt dotfiles')"
if [ ! -d $GIT_PROJECTS_WORKDIR/toolbelt ]; then
  git clone https://github.com/DevonFulcher/toolbelt.git $GIT_PROJECTS_WORKDIR/toolbelt
fi
uv tool install --editable $GIT_PROJECTS_WORKDIR/toolbelt

echo "Installing the gh-stack extension (GitHub stacked PRs, mirrored by 'toolbelt git sync')"
if gh auth status >/dev/null 2>&1; then
  gh extension list | grep -q gh-stack || gh extension install github/gh-stack
else
  echo "gh is not authenticated; run 'gh auth login' then 'gh extension install github/gh-stack'"
fi

echo "Cloning private dotfiles (not tracked in this public repo)"
if [ ! -d $GIT_PROJECTS_WORKDIR/dotfiles-private ]; then
  git clone git@github.com:DevonFulcher/dotfiles-private.git $GIT_PROJECTS_WORKDIR/dotfiles-private
fi

echo "Linking dotfiles from both repos with toolbelt"
$HOME/.local/bin/toolbelt dotfiles link

echo "Sourcing zshrc to include new configurations"
source $HOME/.zshrc

echo "Installing software with asdf"
asdf plugin add python
asdf plugin add rust
asdf plugin add terraform
asdf plugin add grpcurl
asdf plugin add golang
asdf plugin add uv
asdf plugin add pre-commit
asdf plugin add helm
asdf plugin add task
asdf plugin add nodejs
asdf install

echo "Installing software with uv"
uv tool install nbdime # Used for jupyter notebook diffs
uv tool install dbt-core

echo "Setting up dotfiles and toolbelt repos"
git setup $GIT_PROJECTS_WORKDIR/dotfiles
git setup $GIT_PROJECTS_WORKDIR/toolbelt

echo "Loading startup applications"
launchctl load ~/Library/LaunchAgents/com.user.docker.desktop.plist
