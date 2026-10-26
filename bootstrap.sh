#!/bin/sh
# Sets up a new Mac from nothing, and is safe to run again. Either:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/DevonFulcher/dotfiles/main/bootstrap.sh)"
# or, from a clone of this repo:  sh bootstrap.sh
#
# On the old laptop run `toolbelt machine export` first: it stores the archive of
# everything git does not carry (SSH keys, ./secrets, toolbelt's DB) in 1Password.
#
# Environment:
#   DRY_RUN=1                print each step instead of running it
#   GIT_PROJECTS_WORKDIR     where repos live (default $HOME/git)
#   MACHINE_ARCHIVE=PATH     use this archive file instead of fetching from 1Password
#   MACHINE_ARCHIVE_TITLE    1Password document title (default "toolbelt machine archive")
#
# Nothing here depends on the user name: every path comes from $HOME.
set -eu

DRY_RUN="${DRY_RUN:-0}"
GIT_PROJECTS_WORKDIR="${GIT_PROJECTS_WORKDIR:-$HOME/git}"
MACHINE_ARCHIVE_TITLE="${MACHINE_ARCHIVE_TITLE:-toolbelt machine archive}"
export GIT_PROJECTS_WORKDIR
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
export PATH="$HOME/.local/bin:$HOME/.asdf/shims:/opt/homebrew/bin:/usr/local/bin:$PATH"

FOLLOW_UPS=""

step() { printf '\n==> %s\n' "$*"; }
follow_up() { FOLLOW_UPS="${FOLLOW_UPS}
  [ ] $*"; }

# run CMD ARGS...: run it, or only print it under DRY_RUN=1.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '+ %s\n' "$*"
  else
    "$@"
  fi
}

# run_sh 'SCRIPT': the same for a command line that needs the shell (pipes).
run_sh() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '+ %s\n' "$1"
  else
    sh -c "$1"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
step "Rosetta (the dotfiles ask asdf for amd64 terraform and helm builds)"
if [ "$(uname -m)" = arm64 ] && ! pgrep oahd >/dev/null 2>&1; then
  run softwareupdate --install-rosetta --agree-to-license ||
    follow_up "Rosetta did not install: run softwareupdate --install-rosetta --agree-to-license"
fi

step "Homebrew"
if ! have brew; then
  run_sh '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [ -x "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done

step "git, 1Password and its CLI"
run brew install git 1password-cli
if [ ! -d /Applications/1Password.app ]; then
  run brew install --cask 1password
fi

# ---------------------------------------------------------------------------
ARCHIVE=""
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

if [ -n "${MACHINE_ARCHIVE:-}" ]; then
  step "Using the archive $MACHINE_ARCHIVE"
  ARCHIVE="$MACHINE_ARCHIVE"
else
  step "1Password sign-in (manual)"
  if [ "$DRY_RUN" = 1 ]; then
    echo "+ ask you to sign in to the 1Password app and turn on Settings > Developer > Integrate with the 1Password CLI, until 'op whoami' works"
  else
    until op whoami >/dev/null 2>&1; do
      cat <<'MSG'
Sign in to 1Password:
  1. Open the 1Password app and sign in to your account.
  2. Settings > Developer > turn on "Integrate with 1Password CLI".
MSG
      printf 'Press Enter when done (or Ctrl-C to stop): '
      read -r _ </dev/tty
    done
  fi
  step "Fetching the machine archive \"$MACHINE_ARCHIVE_TITLE\" from 1Password"
  if run op document get "$MACHINE_ARCHIVE_TITLE" --out-file "$SCRATCH/machine-archive.zip" --force; then
    ARCHIVE="$SCRATCH/machine-archive.zip"
  else
    follow_up "No archive was fetched: run 'toolbelt machine export' on the old laptop, then re-run this script."
  fi
fi

# ---------------------------------------------------------------------------
step "SSH keys (first: the private repos are cloned over SSH)"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ "$DRY_RUN" = 1 ]; then
  echo "+ restore home/.ssh/* from the archive into ~/.ssh with mode 600 (keys already there are kept)"
elif [ -n "$ARCHIVE" ]; then
  # Members under home/.ssh/ restore to ~/.ssh/ (see archive_layout.py). A key
  # already here is kept; `toolbelt machine import` reports anything that differs.
  unzip -o -q "$ARCHIVE" 'home/.ssh/*' -d "$SCRATCH/ssh" 2>/dev/null || true
  if [ -d "$SCRATCH/ssh/home/.ssh" ]; then
    for key in "$SCRATCH"/ssh/home/.ssh/*; do
      dest="$HOME/.ssh/$(basename "$key")"
      [ -e "$dest" ] && continue
      cp "$key" "$dest"
      case "$dest" in
        *.pub) chmod 644 "$dest" ;;
        *) chmod 600 "$dest" ;;
      esac
      echo "restored $dest"
    done
  fi
fi
if [ "$DRY_RUN" != 1 ]; then
  for key in "$HOME"/.ssh/*; do
    case "$key" in
      *.pub | */config | */known_hosts*) continue ;;
    esac
    ssh-keygen -y -P "" -f "$key" >/dev/null 2>&1 && ssh-add --apple-use-keychain "$key" 2>/dev/null || true
  done
fi

# ---------------------------------------------------------------------------
step "Cloning dotfiles, dotfiles-private and toolbelt into $GIT_PROJECTS_WORKDIR"
run mkdir -p "$GIT_PROJECTS_WORKDIR"

# clone_repo NAME SSH_URL [HTTPS_URL]: public repos fall back to https.
clone_repo() {
  if [ -d "$GIT_PROJECTS_WORKDIR/$1/.git" ]; then
    echo "$1 is already cloned"
    return 0
  fi
  if run git clone "$2" "$GIT_PROJECTS_WORKDIR/$1"; then
    return 0
  fi
  if [ -n "${3:-}" ]; then
    run git clone "$3" "$GIT_PROJECTS_WORKDIR/$1"
  else
    echo "Could not clone $1 over SSH. Check the key in ~/.ssh is added to GitHub and authorized for the org's SSO." >&2
    return 1
  fi
}
clone_repo dotfiles git@github.com:DevonFulcher/dotfiles.git https://github.com/DevonFulcher/dotfiles.git
clone_repo dotfiles-private git@github.com:DevonFulcher/dotfiles-private.git
clone_repo toolbelt git@github.com:DevonFulcher/toolbelt.git https://github.com/DevonFulcher/toolbelt.git

# ---------------------------------------------------------------------------
step "Installing software with shell scripts"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # KEEP_ZSHRC: the real .zshrc is linked from this repo below.
  run_sh 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
fi
if ! have cursor; then
  run_sh 'curl https://cursor.com/install -fsS | bash'
fi
if ! have claude; then
  run_sh 'curl -fsSL https://claude.ai/install.sh | bash'
fi

step "Installing software with Homebrew"
run brew tap FelixKratz/formulae # used for borders
# uv is needed before asdf to install toolbelt, which links the dotfiles
run brew install \
  eza bat gh fzf git-delta difftastic direnv beads \
  koekeishiya/formulae/yabai koekeishiya/formulae/skhd borders \
  rip2 1password-cli asdf starship tmux uv
run brew install --cask iterm2 font-monaspace
# cask_unless_installed APP.app CASK: leave an app that is already there (put there
# by IT or by hand) alone: brew refuses to install over it.
cask_unless_installed() {
  if [ -d "/Applications/$1" ]; then
    echo "$1 is already installed"
  else
    run brew install --cask "$2"
  fi
}
cask_unless_installed "Brave Browser.app" brave-browser
cask_unless_installed "Docker.app" docker-desktop
cask_unless_installed "Slack.app" slack

# ---------------------------------------------------------------------------
step "Installing toolbelt (provides 'toolbelt dotfiles' and 'toolbelt machine')"
run uv tool install --editable --force "$GIT_PROJECTS_WORKDIR/toolbelt"

step "Linking dotfiles from both repos"
run toolbelt dotfiles link

if [ -n "$ARCHIVE" ]; then
  step "Importing the machine archive (secrets, toolbelt DB, repos, worktrees)"
  run toolbelt machine import --from-file "$ARCHIVE" ||
    follow_up "'toolbelt machine import' failed: fix what it printed, then re-run this script."
else
  echo "(no archive: skipping 'toolbelt machine import')"
fi

# ---------------------------------------------------------------------------
step "Installing software with asdf"
if have asdf; then
  # every plugin the ~/.tool-versions of this repo names (toolbelt builds its web app with pnpm)
  for plugin in python rust terraform grpcurl golang uv pre-commit helm task nodejs pnpm buf; do
    run asdf plugin add "$plugin" 2>/dev/null || true
  done
  (cd "$HOME" && run asdf install) || follow_up "'asdf install' failed in \$HOME: re-run it and read the error."
fi

step "Installing software with uv"
run uv tool install nbdime # Used for jupyter notebook diffs
run uv tool install dbt-core

step "Setting up the repos toolbelt tracks (asdf install, uv sync in each checkout)"
# Worktrees are plain checkouts: `toolbelt machine setup --worktrees` does them too.
run toolbelt machine setup ||
  follow_up "'toolbelt machine setup' had failures (listed above): fix them and re-run it."

step "gh extensions"
if have gh && gh auth status >/dev/null 2>&1; then
  gh extension list | grep -q gh-stack || run gh extension install github/gh-stack
  gh extension list | grep -q gh-webhook || run gh extension install cli/gh-webhook
else
  echo "gh is not authenticated: after 'gh auth login', run: gh extension install github/gh-stack && gh extension install cli/gh-webhook"
fi

step "Setting up the dotfiles and toolbelt repos"
run git setup "$GIT_PROJECTS_WORKDIR/dotfiles" || follow_up "git setup on dotfiles failed."
run git setup "$GIT_PROJECTS_WORKDIR/toolbelt" || follow_up "git setup on toolbelt failed."

step "Installing the toolbelt Claude Code plugins and MCP server"
if [ -x "$GIT_PROJECTS_WORKDIR/toolbelt/claude-plugin/install.sh" ]; then
  # idempotent; exits 0 with a message when claude is not on PATH
  run "$GIT_PROJECTS_WORKDIR/toolbelt/claude-plugin/install.sh" ||
    follow_up "claude-plugin/install.sh failed: re-run it from the toolbelt repo."
fi

step "Registering your Claude MCP servers (from dotfiles-private, if it has the script)"
if [ -x "$GIT_PROJECTS_WORKDIR/dotfiles-private/claude-mcp-servers.sh" ]; then
  run "$GIT_PROJECTS_WORKDIR/dotfiles-private/claude-mcp-servers.sh" ||
    follow_up "dotfiles-private/claude-mcp-servers.sh failed: re-run it."
fi

step "Building the toolbelt UI (the launchd service runs it with --no-build)"
if [ ! -d "$GIT_PROJECTS_WORKDIR/toolbelt/src/toolbelt/ui/static/dist" ]; then
  if have pnpm; then
    run pnpm --dir "$GIT_PROJECTS_WORKDIR/toolbelt/web" install --frozen-lockfile &&
      run pnpm --dir "$GIT_PROJECTS_WORKDIR/toolbelt/web" build ||
      follow_up "Build the UI: pnpm --dir $GIT_PROJECTS_WORKDIR/toolbelt/web install && pnpm --dir $GIT_PROJECTS_WORKDIR/toolbelt/web build"
  else
    follow_up "pnpm is not available yet: after 'asdf install', run pnpm --dir $GIT_PROJECTS_WORKDIR/toolbelt/web install && pnpm --dir $GIT_PROJECTS_WORKDIR/toolbelt/web build"
  fi
fi

step "Loading launchd agents (after the import, so tt ui starts on the restored DB)"
uid="$(id -u)"
for plist in "$HOME"/Library/LaunchAgents/com.user.*.plist; do
  [ -e "$plist" ] || continue
  label="$(basename "$plist" .plist)"
  if launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
    echo "$label is already loaded"
  else
    run launchctl bootstrap "gui/$uid" "$plist" || follow_up "launchctl bootstrap gui/$uid $plist"
  fi
done

step "Keyboard repeat (takes effect after you log out and in)"
run defaults write NSGlobalDomain KeyRepeat -int 2
run defaults write NSGlobalDomain InitialKeyRepeat -int 15

step "Window manager services (they need the macOS permissions below to do anything)"
have yabai && { run yabai --start-service || true; }
have skhd && { run skhd --start-service || true; }

step "Checking secrets/machine.sh"
if [ -f "$GIT_PROJECTS_WORKDIR/dotfiles/secrets/machine.sh" ] &&
  grep -q 'IS_PERSONAL=true' "$GIT_PROJECTS_WORKDIR/dotfiles/secrets/machine.sh"; then
  follow_up "secrets/machine.sh says IS_PERSONAL=true: remove it on a work laptop."
fi

# ---------------------------------------------------------------------------
step "Done. Still to do by hand"
cat <<EOF
$FOLLOW_UPS
  [ ] gh auth login with the work account, then re-run this script (it installs the gh extensions and clones what needed the login)
  [ ] Authorize the SSH key for the GitHub org's SSO (GitHub > Settings > SSH and GPG keys > Configure SSO), then re-run this script: it clones the org's repos and recreates their worktrees
  [ ] claude auth login (Claude Code, and so the autonomous agents)
  [ ] If you moved the private key: remove the old laptop's key from GitHub once it is retired
  [ ] System Settings > Privacy & Security: Accessibility for yabai and skhd, Screen Recording for yabai
  [ ] Approve MDM / company software prompts
  [ ] Sign in to Cursor (and install its extensions), iTerm2 settings, the 1Password browser extension
  [ ] Log out and in once (keyboard repeat), then open a new terminal and run: toolbelt dotfiles status
  Everything else is done by this script; the dotfiles README lists what it does.
EOF
