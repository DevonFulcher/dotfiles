brew tap FelixKratz/formulae # used for borders
brew install \
  mackup \
  eza \
  bat \
  gh \
  aicommits \
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
asdf plugin add python
asdf install

# Install Python packages
pip install toml # Used for git-town configuration setup
pip install nbdime # Used for jupyter notebook diffs
