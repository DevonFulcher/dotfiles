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
# TODO: I shouldn't install the below packages globally
pip install toml # Used for git-town configuration setup
pip install types-toml
pip install pre-commit # Used for git hooks in this repo
pip install mypy
pip install ruff
