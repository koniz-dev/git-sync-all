#!/usr/bin/env bash
# Install git-sync-all into a user-owned bin directory.
set -euo pipefail

PREFIX="${HOME}/.local"
INSTALL_COMPLETIONS=0
FORCE=0

usage() {
  echo 'usage: install.sh [--prefix DIRECTORY] [--completions] [--force]'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --prefix)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      PREFIX="$2"
      shift
      ;;
    --completions) INSTALL_COMPLETIONS=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$PREFIX/bin"
TARGET="$TARGET_DIR/git-sync-all"
if [ "$FORCE" -ne 1 ] && [ -e "$TARGET" ]; then
  echo "install.sh: $TARGET already exists (pass --force to replace it)" >&2
  exit 1
fi
if [ "$INSTALL_COMPLETIONS" -eq 1 ] && [ "$FORCE" -ne 1 ]; then
  for target in "$PREFIX/share/bash-completion/completions/git-sync-all" \
    "$PREFIX/share/zsh/site-functions/_git-sync-all"; do
    if [ -e "$target" ]; then
      echo "install.sh: $target already exists (pass --force to replace it)" >&2
      exit 1
    fi
  done
fi
mkdir -p "$TARGET_DIR"
install -m 0755 "$SOURCE_DIR/bin/git-sync-all" "$TARGET"
printf 'Installed git-sync-all to %s\n' "$TARGET"
if [ "$INSTALL_COMPLETIONS" -eq 1 ]; then
  BASH_COMPLETION_DIR="$PREFIX/share/bash-completion/completions"
  ZSH_COMPLETION_DIR="$PREFIX/share/zsh/site-functions"
  mkdir -p "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR"
  install -m 0644 "$SOURCE_DIR/completions/git-sync-all.bash" \
    "$BASH_COMPLETION_DIR/git-sync-all"
  install -m 0644 "$SOURCE_DIR/completions/_git-sync-all" \
    "$ZSH_COMPLETION_DIR/_git-sync-all"
  printf 'Installed Bash and Zsh completions under %s/share\n' "$PREFIX"
fi
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) printf 'Add %s to PATH, then run: git sync-all --help\n' "$TARGET_DIR" ;;
esac
