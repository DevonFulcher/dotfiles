START=$(perl -MTime::HiRes -e 'printf("%d\n", Time::HiRes::time()*1000)')

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

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

# source: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/fzf
# fzf install directory with homebrew
export FZF_BASE=/opt/homebrew/bin/fzf

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  starship
  zsh-autocomplete
  gh
  jump
  fzf
  docker
  docker-compose
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

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

export CURRENT_ORG="dbt_labs"
export GIT_PROJECTS_WORKDIR="$HOME/git"
alias g=git
# lsd https://github.com/lsd-rs/lsd is an alternative to eza worth exploring one day
alias ls="eza --classify --all --group-directories-first --long --git --git-repos --no-permissions --no-user --no-time"
export FPATH="$GIT_PROJECTS_WORKDIR/eza/completions/zsh:$FPATH"
alias cat=bat
alias less=bat
alias k='kubectl'
export PATH="$PATH:/usr/local/bin"
export PATH="$HOME/.local/bin:$PATH"


eval "$(/opt/homebrew/bin/brew shellenv)"
# Setup direnv https://direnv.net/
eval "$(direnv hook zsh)"
# Delta completions https://dandavison.github.io/delta/tips-and-tricks/shell-completion.html
eval "$(delta --generate-completion zsh)"
# Git Town completions https://www.git-town.com/commands/completions#zsh
source <(git-town completions zsh)
# Setup asdf https://asdf-vm.com/guide/getting-started.html
. /opt/homebrew/opt/asdf/libexec/asdf.sh # TODO: this is not working


# setup toolbelt
[[ -r $GIT_PROJECTS_WORKDIR/toolbelt ]] ||
    git clone git@github.com:DevonFulcher/toolbelt.git $GIT_PROJECTS_WORKDIR/toolbelt
(cd $GIT_PROJECTS_WORKDIR/toolbelt/cli && go build)
alias tt=$GIT_PROJECTS_WORKDIR/toolbelt/cli/toolbelt

[[ -r $GIT_PROJECTS_WORKDIR/dotfiles ]] ||
    git clone git@github.com:DevonFulcher/dotfiles.git $GIT_PROJECTS_WORKDIR/dotfiles

source $GIT_PROJECTS_WORKDIR/dotfiles/scripts/source_all.sh $GIT_PROJECTS_WORKDIR/dotfiles/secrets
source $GIT_PROJECTS_WORKDIR/dotfiles/scripts/find_and_source.sh $GIT_PROJECTS_WORKDIR/dotfiles/scripts/work $CURRENT_ORG

function git() {
  # Always git clone to the same directory
  if [[ $1 == "clone" && -n $2 && -n $GIT_PROJECTS_WORKDIR ]]; then
    repo_name=$(echo "$2" | awk -F/ '{sub(/\..*/,"",$NF); print $NF}')
    command git "$@" "$GIT_PROJECTS_WORKDIR/$repo_name"
    if [ -d "$GIT_PROJECTS_WORKDIR/$repo_name" ]; then
      cd "$GIT_PROJECTS_WORKDIR/$repo_name"
      cp $GIT_PROJECTS_WORKDIR/dotfiles/config/git-branches.toml .
      cursor .
    fi
  elif [[ $1 == "checkout" || $1 == "merge" ]]; then
    if [ -z "$2" ]; then
      # Handle checkout & merge without parameters
      branch_name=$(echo $(command git branch | fzf ))
      command git $1 $branch_name
    # Make commands main/master agnostic
    elif [ "$2" = "main" ] || [ "$2" = "master" ]; then
      if git rev-parse --verify main >/dev/null 2>&1; then
        # If 'main' exists, checkout to 'main'
        branch_name="main"
      elif git rev-parse --verify master >/dev/null 2>&1; then
        # If 'master' exists but 'main' does not, checkout to 'master'
        branch_name="master"
      else
        echo "Neither 'main' nor 'master' branch exists."
        exit 1
      fi
      command git $1 $branch_name
    elif [ "$2" = "-" ]; then
      # Handle 'git merge -'
      if [ "$1" = "merge" ]; then
        previous_branch=$(git rev-parse --abbrev-ref @{-1})
        if [ -z "$previous_branch" ]; then
          echo "Could not determine the previous branch."
          exit 1
        fi
        command git merge "$previous_branch"
      else
        # Handle 'git checkout -'
        command git checkout -
      fi
    else
      # If not 'main', 'master', or '-', pass all arguments to git
      command git "$@"
    fi
    echo "git status:"
    command git status
  elif [ $1 = "branch" ] && [ "$#" -eq 1 ]; then
    command git branch | head -n 20
  elif [ $1 = "diff" ] && [ "$#" -eq 1 ]; then
    # Exclude files from diff that I rarely care about. Reference: https://stackoverflow.com/a/48259275/8925314
    command git "$@" -- ':!*Cargo.lock' ':!*poetry.lock' ':!*package-lock.json' ':!*pnpm-lock.yaml'
  elif [ $1 = "commit" ]; then
    # Alway push after I commit.
    filtered_args=()
    for arg in "$@"; do
      if [[ "$arg" != "--no-push" ]]; then
        filtered_args+=("$arg")
      fi
    done
    command git "${filtered_args[@]}" || { echo "commit failed"; return 1; }
    for arg in "$@"; do
      if [[ "$arg" == "--no-push" ]]; then
        echo "git status:"
        command git status
        return 0
      fi
    done
    command git push --quiet && echo "commit pushed"
    echo "git status:"
    command git status
  elif [[ $1 == "add" || $1 == "restore" || $1 == "stash" || $1 == "reset" ]]; then
    # Always run git status after these commands.
    command git "$@"
    echo "git status:"
    command git status
  elif [ $1 = "pr" ]; then
    sh $GIT_PROJECTS_WORKDIR/dotfiles/scripts/git/git_pr.sh "$@"
  elif [ $1 = "branch-clean" ]; then
    git fetch -p
    git branch -vv | grep ': gone]' | awk '{print $1}' | while read branch; do
      git branch -D "$branch"
    done
  else
    command git "$@"
  fi
}

function dot() {
  if [ "$1" = "code-fix" ]; then
    code --list-extensions > ~/git/dotfiles/vscode/extensions.txt
  elif diff -u ~/git/dotfiles/vscode/extensions.txt <(code --list-extensions) > /dev/null; then
    git -C $GIT_PROJECTS_WORKDIR/dotfiles $@
  else
    echo "Installed VS Code extensions don't match listed ones. Run 'dot code-fix'."
  fi
}

function cd() {
  if [ "$#" -eq 0 ]; then
    directories=$(find $GIT_PROJECTS_WORKDIR -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)
    directory=$(echo "$directories" | fzf)
    builtin cd "$directory"
  else
    builtin cd "$@" 2>/dev/null || jump "$@"
  fi
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    local git_root=$(git rev-parse --show-toplevel)
    if [ "$git_root" = "$(pwd)" ]; then
      echo "git status:"
      command git status
    fi
  fi
}

# VS Code override
function code() {
  if [ "$#" -eq 0 ]; then
    directories=$(echo "$(find ~/vscode -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)\n$(find $GIT_PROJECTS_WORKDIR -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)")
    directory=$(echo "$directories" | fzf)
    command code "$directory"
  else
    command code $@
  fi
}

# Cursor override
function cursor() {
  if [ "$#" -eq 0 ]; then
    directories=$(echo "$(find ~/vscode -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)\n$(find $GIT_PROJECTS_WORKDIR -mindepth 1 -maxdepth 1 -not -path '*/\.*' -print)")
    directory=$(echo "$directories" | fzf)
    command cursor "$directory"
  else
    command cursor $@
  fi
}

cd $GIT_PROJECTS_WORKDIR

END=$(perl -MTime::HiRes -e 'printf("%d\n", Time::HiRes::time()*1000)')
DURATION=$((END - START))
echo "shell took $DURATION milliseconds to start up."
