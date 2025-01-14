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
  asdf \
  koekeishiya/formulae/yabai \
  koekeishiya/formulae/skhd \
  borders \
  rip2 \
  1password-cli \
  charmbracelet/tap/mods
# Install UI applications with --cask
brew install --cask \
  raycast \
  alacritty \
  warp

echo "Restoring configurations with Mackup"
mackup restore

echo "Installing versioned software with asdf"
asdf install

echo "Installing Python software with uv"
uv tool install nbdime # Used for jupyter notebook diffs
# TODO: this relies on dotfiles and toolbelt being cloned
uv tool install $GIT_PROJECTS_WORKDIR/toolbelt/toolbelt
uv tool install datadog # For the dog CLI (used for monitoring by dbt Labs)
