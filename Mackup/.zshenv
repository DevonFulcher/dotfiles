## Cursor and Claude Code agent (non-interactive) environment bootstrap
#
# Cursor and Claude Code run many Agent shell commands in a non-interactive
# zsh context (so `.zshrc` is not reliably sourced). `.zshenv` *is* sourced
# for `zsh -c`, so we use it to make direnv-based env vars available to Agent
# commands.
#
# Keep this block lightweight: `.zshenv` runs for *every* zsh invocation.
if [[ -n "${CURSOR_AGENT-}" || -n "${CLAUDECODE-}" ]]; then
  eval "$(direnv export zsh 2>/dev/null)"
fi

## Static environment variables
#
# These live here rather than in `.zshrc` because non-interactive shells
# (`zsh -c ...`, e.g. agent/tool invocations) never source `.zshrc`, and
# several shell functions and commands depend on them.
#
# Keep these cheap: `.zshenv` runs for *every* zsh invocation. Anything that
# forks a subprocess (e.g. `PYTHON_PATH`) stays in `.zshrc`.
export GIT_PROJECTS_WORKDIR="$HOME/git"
export DOTFILES="$GIT_PROJECTS_WORKDIR/dotfiles"
export PY_SCRIPTS="$DOTFILES/scripts/python"
export EDITOR="cursor"
export GITHUB_USERNAME="DevonFulcher"
export CURRENT_ORG="dbt_labs"
