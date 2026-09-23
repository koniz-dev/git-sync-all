#!/usr/bin/env bash
# Install git-sync-all into a user-owned bin directory.
set -euo pipefail

PREFIX="${HOME}/.local"
case "${1:-}" in
  "") ;;
  --prefix)
    [ "$#" -eq 2 ] || { echo 'usage: install.sh [--prefix DIRECTORY]' >&2; exit 2; }
    PREFIX="$2"
    ;;
  -h|--help) echo 'usage: install.sh [--prefix DIRECTORY]'; exit 0 ;;
  *) echo "install.sh: unknown option: $1" >&2; exit 2 ;;
esac

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$PREFIX/bin"
mkdir -p "$TARGET_DIR"
install -m 0755 "$SOURCE_DIR/bin/git-sync-all" "$TARGET_DIR/git-sync-all"
printf 'Installed git-sync-all to %s\n' "$TARGET_DIR/git-sync-all"
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) printf 'Add %s to PATH, then run: git sync-all --help\n' "$TARGET_DIR" ;;
esac
