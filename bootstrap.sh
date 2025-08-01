echo "Installing software with Homebrew"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
  charmbracelet/tap/mods \
  asdf \
  tmux \
  block-goose-cli
# Install UI applications with --cask
brew install --cask \
  raycast \
  alacritty \
  block-goose \
  claude-code

echo "Restoring configurations with Mackup" # TODO: need to clone dotfiles repo first
mackup restore

echo "Installing versioned software with asdf"
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

echo "Installing software distributed via pip with uv"
uv tool install nbdime # Used for jupyter notebook diffs
# TODO: this relies on dotfiles and toolbelt being cloned
uv tool install $GIT_PROJECTS_WORKDIR/toolbelt
uv tool install datadog # For the dog CLI (used for monitoring by dbt Labs)
uv tool install dbt-core

echo "Installing software distributed via npm"
npm install -g prettier

echo "Loading startup applications"
launchctl load ~/Library/LaunchAgents/com.user.docker.desktop.plist
