#!/bin/bash
# Links every skill from this repo (and dotfiles-private, if present) into
# ~/.claude/skills. Not Mackup-managed: skills need to merge in symlinks from
# multiple repos, which Mackup's one-symlink-per-path model can't do.
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
PUBLIC_SKILLS="$GIT_PROJECTS_WORKDIR/dotfiles/Mackup/.claude/skills"

if [ -L "$SKILLS_DIR" ]; then
  rm "$SKILLS_DIR"
fi
mkdir -p "$SKILLS_DIR"

for skill in "$PUBLIC_SKILLS"/*/; do
  name=$(basename "$skill")
  ln -sfn "$skill" "$SKILLS_DIR/$name"
done
