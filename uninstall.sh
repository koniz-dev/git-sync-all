#!/usr/bin/env bash
# Remove git-sync-all from a user-owned prefix.
set -euo pipefail

PREFIX="${HOME}/.local"
REMOVE_COMPLETIONS=0

usage() {
  echo 'usage: uninstall.sh [--prefix DIRECTORY] [--completions]'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --prefix)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      PREFIX="$2"
      shift
      ;;
    --completions) REMOVE_COMPLETIONS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "uninstall.sh: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

TARGET="$PREFIX/bin/git-sync-all"
if [ -e "$TARGET" ]; then
  rm -f "$TARGET"
  printf 'Removed %s\n' "$TARGET"
else
  printf 'git-sync-all is not installed at %s\n' "$TARGET"
fi

if [ "$REMOVE_COMPLETIONS" -eq 1 ]; then
  rm -f "$PREFIX/share/bash-completion/completions/git-sync-all"
  rm -f "$PREFIX/share/zsh/site-functions/_git-sync-all"
  printf 'Removed Bash and Zsh completions under %s/share\n' "$PREFIX"
fi
