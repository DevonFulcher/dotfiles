## Cursor Agent (non-interactive) environment bootstrap
#
# Cursor runs many Agent shell commands in a non-interactive zsh context
# (so `.zshrc` is not reliably sourced). `.zshenv` *is* sourced for `zsh -c`,
# so we use it to make direnv-based env vars available to Agent commands.
#
# Keep this block lightweight: `.zshenv` runs for *every* zsh invocation.
if [[ -n "${CURSOR_AGENT-}" ]]; then
  eval "$(direnv export zsh 2>/dev/null)"
fi
