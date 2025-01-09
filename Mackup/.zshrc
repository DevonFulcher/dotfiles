START=$(perl -MTime::HiRes -e 'printf("%d\n", Time::HiRes::time()*1000)')

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Update automatically without asking
zstyle ':omz:update' mode auto

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# setting up autocomplete with these instructions https://github.com/marlonrichert/zsh-autocomplete/issues/658#issuecomment-1800739329
[[ -r ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete ]] ||
    git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  starship
  zsh-autocomplete
  docker
  docker-compose
  kubectl
  alias-finder
)

source $ZSH/oh-my-zsh.sh

# User configuration

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Setup environment variables
export CURRENT_ORG="dbt_labs"
export PYTHON_PATH=$(asdf which python)
export EDITOR="cursor"
export GIT_PROJECTS_WORKDIR="$HOME/git"
export DOTFILES=$GIT_PROJECTS_WORKDIR/dotfiles
export PY_SCRIPTS=$DOTFILES/scripts/python

# Add executables to PATH
export PATH="$PATH:/usr/local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Alias Unix commands
alias ls="eza --classify --all --group-directories-first --long --git --git-repos --no-permissions --no-user --no-time" # lsd https://github.com/lsd-rs/lsd is an alternative to eza worth exploring one day
alias cat=bat
alias less=bat
alias rm="echo Use 'rip' instead of rm."

# git aliases
alias g=git
alias gv="git save"
alias gd="git compare"
alias gc="git change"
alias gs="git status"
alias gu="git push"
alias gl="git pull"
alias gn="git send"
alias ga="git add"
alias gm="git commit"
alias gr="git pr"
alias gta="git-town append"

# Directory aliases
alias lab="$GIT_PROJECTS_WORKDIR/TheLaboratory"

# Alias Toolbelt
alias tt="toolbelt"

cdpath=($GIT_PROJECTS_WORKDIR $cdpath)

# Setup alias-finder https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder
zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' cheaper yes

# Shell completions
eval "$(direnv hook zsh)" # Setup direnv https://direnv.net/
eval "$(delta --generate-completion zsh)" # Delta completions https://dandavison.github.io/delta/tips-and-tricks/shell-completion.html
source <(git-town completions zsh) # Git Town completions https://www.git-town.com/commands/completions#zsh
. /opt/homebrew/opt/asdf/libexec/asdf.sh # Setup asdf completions https://asdf-vm.com/guide/getting-started.html

# Setup dotfiles repo
[[ -r $GIT_PROJECTS_WORKDIR/dotfiles ]] ||
    git clone git@github.com:DevonFulcher/dotfiles.git $DOTFILES
source $DOTFILES/scripts/source_all.sh $DOTFILES/secrets
source $DOTFILES/scripts/find_and_source.sh $DOTFILES/scripts/work $CURRENT_ORG

function dot() {
  if [ "$1" = "fix" ]; then
    code --list-extensions > $GIT_PROJECTS_WORKDIR/dotfiles/vscode/extensions.txt
    cursor --list-extensions > $GIT_PROJECTS_WORKDIR/dotfiles/cursor/extensions.txt
  elif diff -u $GIT_PROJECTS_WORKDIR/dotfiles/vscode/extensions.txt <(code --list-extensions) > /dev/null && diff -u $GIT_PROJECTS_WORKDIR/dotfiles/cursor/extensions.txt <(cursor --list-extensions) > /dev/null; then
    git -C $GIT_PROJECTS_WORKDIR/dotfiles $@
  else
    echo "Installed VS Code or Cursor extensions don't match listed ones. Run 'dot fix'."
  fi
}

function goto() {
  if [ "$#" -eq 0 ]; then
    directories=$(find $GIT_PROJECTS_WORKDIR -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)
    directory=$(echo "$directories" | fzf)
    builtin cd "$directory"
  else
    builtin cd "$@"
  fi
}

function edit() {
  if [ "$#" -eq 0 ]; then
    projects=$(echo "$(find $GIT_PROJECTS_WORKDIR/dotfiles/workspaces -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)\n$(find $GIT_PROJECTS_WORKDIR -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)")
    project=$(echo "$projects" | fzf)
    command $EDITOR "$project"
    [ -d "$project" ] && cd "$project"
    $PYTHON_PATH $PY_SCRIPTS/yabai.py "$@"
  else
    for dir in $(find $GIT_PROJECTS_WORKDIR -mindepth 1 -maxdepth 1 -type d); do
      if [ "$(basename $dir)" = "$1" ]; then
        command $EDITOR "$dir"
        cd "$dir"
        $PYTHON_PATH $PY_SCRIPTS/yabai.py "$@"
        return
      fi
    done
    local target_path=$(alias "$1" 2>/dev/null | cut -d= -f2- | tr -d "'\"" || echo "$1")
    if [ -e "$target_path" ]; then
      command $EDITOR "$target_path"
      cd "$target_path"
      return
    fi
    if [ -d "$@" ]; then
      command $EDITOR "$@" && cd "$@"
    else
      command $EDITOR "$@"
    fi
    $PYTHON_PATH $PY_SCRIPTS/yabai.py "$@"
  fi
}

function kill-port() {
  lsof -t -i:$1 | xargs kill -9
}

function format-json() {
  jq -S . $@ > tmp.json && mv tmp.json $@
}

cd $GIT_PROJECTS_WORKDIR

END=$(perl -MTime::HiRes -e 'printf("%d\n", Time::HiRes::time()*1000)')
DURATION=$((END - START))
echo "shell took $DURATION milliseconds to start up."
