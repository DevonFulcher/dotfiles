#!/bin/sh
# Exercises .githooks/pre-commit against a throwaway repo: a clean commit must
# pass and a commit containing a fake AWS key must be rejected without echoing
# the key. Needs `toolbelt` on PATH. Run: sh .githooks/test-pre-commit.sh
set -eu

hooks=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir "$tmp/config" "$tmp/repo"
export XDG_CONFIG_HOME="$tmp/config"
mkdir "$XDG_CONFIG_HOME/toolbelt"
printf 'dotfiles:\n  repos:\n    - %s\n' "$tmp/repo" > "$XDG_CONFIG_HOME/toolbelt/config.yaml"

cd "$tmp/repo"
git init -q
git config user.name test
git config user.email test@example.com
git config core.hooksPath "$hooks"
printf 'visibility = "public"\n' > dotfiles.toml

echo "clean" > notes.txt
git add -A
git commit -q -m "clean" || { echo "FAIL: clean commit was rejected" >&2; exit 1; }

key="AKIA""ABCDEFGHIJKLMNOP"
echo "aws_key $key" > leaked.txt
git add -A
if out=$(git commit -q -m "leak" 2>&1); then
  echo "FAIL: commit with a secret was accepted" >&2
  exit 1
fi
case "$out" in
  *"$key"*) echo "FAIL: hook output echoed the secret" >&2; exit 1 ;;
esac
echo "ok: clean commit passes, secret commit is rejected"
