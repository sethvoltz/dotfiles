#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$DOTFILES_DIR/claude"
mkdir -p "$HOME/.claude"

for src in "$SRC_DIR"/* "$SRC_DIR"/.[!.]*; do
  [ -e "$src" ] || continue
  name="$(basename "$src")"
  dst="$HOME/.claude/$name"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.backup.$(date +%s)"
  fi
  ln -sfn "$src" "$dst"
done
