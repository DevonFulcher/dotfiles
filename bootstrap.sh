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
  charmbracelet/tap/mods
# Install UI applications with --cask
brew install --cask \
  raycast \
  alacritty
asdf install

# Install Python packages
pip install nbdime # Used for jupyter notebook diffs
pip install pre-commit
