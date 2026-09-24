#!/usr/bin/env bash
# Create a GitHub release once, or replace its generated assets on a re-run.
set -euo pipefail

publish_release_assets() {
  local tag="$1"
  shift
  if gh release view "$tag" >/dev/null 2>&1; then
    gh release upload "$tag" "$@" --clobber
  else
    gh release create "$tag" "$@" --generate-notes
  fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  [ "$#" -ge 2 ] || {
    echo "usage: $(basename "$0") TAG ASSET..." >&2
    exit 2
  }
  publish_release_assets "$@"
fi
