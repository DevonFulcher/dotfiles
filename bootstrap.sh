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
  charmbracelet/tap/mods
brew install --cask raycast
asdf install

# Install Python packages
pip install nbdime # Used for jupyter notebook diffs
pip install -e $GIT_PROJECTS_WORKDIR/toolbelt/toolbelt
pip install pre-commit
