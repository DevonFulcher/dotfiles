echo "Installing software with shell scripts"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing software with Homebrew"
brew tap FelixKratz/formulae # used for borders
brew install \
  mackup \
  eza \
  bat \
  gh \
  fzf \
  git-delta \
  direnv \
  git-town \
  koekeishiya/formulae/yabai \
  koekeishiya/formulae/skhd \
  borders \
  rip2 \
  1password-cli \
  asdf \
  starship \
  tmux
# Install UI applications with --cask
brew install --cask \
  raycast \
  alacritty \
  claude-code

echo "Restoring configurations with Mackup"
cd $GIT_PROJECTS_WORKDIR/dotfiles/Mackup/.mackup.cfg $HOME/.mackup.cfg
mackup --force restore # Using force to override .mackup.cfg

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

echo "Installing software with git"
git clone https://github.com/DevonFulcher/toolbelt.git $GIT_PROJECTS_WORKDIR/toolbelt

echo "Installing software with uv"
uv tool install nbdime # Used for jupyter notebook diffs
uv tool install dbt-core
uv tool install --editable $GIT_PROJECTS_WORKDIR/toolbelt

echo "Setting up dotfiles and toolbelt repos"
git setup $GIT_PROJECTS_WORKDIR/dotfiles
git setup $GIT_PROJECTS_WORKDIR/toolbelt

echo "Loading startup applications"
launchctl load ~/Library/LaunchAgents/com.user.docker.desktop.plist
