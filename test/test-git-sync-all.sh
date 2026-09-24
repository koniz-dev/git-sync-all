#!/usr/bin/env bash
# Integration tests for git-sync-all.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMAND="$ROOT_DIR/bin/git-sync-all"
source "$ROOT_DIR/scripts/publish-release-assets.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/git-sync-all-test.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME='git-sync-all tests'
export GIT_AUTHOR_EMAIL='tests@example.invalid'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
# Fixtures use local bare repositories as submodule remotes.
export GIT_ALLOW_PROTOCOL=file

run_git() {
  git -c protocol.file.allow=always "$@"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1" expected="$2"
  grep -Fqx "$expected" "$file" || fail "expected '$expected' in $file"
}

make_remote() {
  local name="$1" work remote
  work="$TMP_DIR/$name-work"
  remote="$TMP_DIR/$name.git"
  run_git init -q -b main "$work"
  (
    cd "$work"
    printf '%s\n' "$name initial" > README
    run_git add README
    run_git commit -qm 'Initial commit'
  )
  run_git clone -q --bare "$work" "$remote"
}

test_regular_repository() {
  make_remote regular
  run_git clone -q "$TMP_DIR/regular.git" "$TMP_DIR/regular-clone"
  run_git clone -q "$TMP_DIR/regular.git" "$TMP_DIR/regular-update"
  (
    cd "$TMP_DIR/regular-update"
    printf '%s\n' 'regular updated' > README
    run_git commit -am 'Update remote' -q
    run_git push -q
  )

  (
    cd "$TMP_DIR/regular-clone"
    "$COMMAND"
  )
  assert_file_contains "$TMP_DIR/regular-clone/README" 'regular updated'
}

test_missing_branch() {
  make_remote missing-branch
  run_git clone -q "$TMP_DIR/missing-branch.git" "$TMP_DIR/missing-branch-clone"
  local before output
  before="$(run_git -C "$TMP_DIR/missing-branch-clone" rev-parse HEAD)"
  output="$(cd "$TMP_DIR/missing-branch-clone" && "$COMMAND" feature/absent 2>&1)"
  [ "$(run_git -C "$TMP_DIR/missing-branch-clone" rev-parse HEAD)" = "$before" ] \
    || fail 'a missing branch changed the superproject'
  [[ "$output" == *"superproject has no branch 'feature/absent'"* ]] \
    || fail 'a missing branch was not reported'
  output="$(cd "$TMP_DIR/missing-branch-clone" && "$COMMAND" --json feature/absent 2>/dev/null)"
  [[ "$output" == *'"status":"skipped"'* && "$output" == *'"reason":"branch_missing"'* ]] \
    || fail 'JSON did not report a missing branch as skipped'
}

test_remote_branch_refresh() {
  make_remote remote-branch
  run_git clone -q "$TMP_DIR/remote-branch.git" "$TMP_DIR/remote-branch-clone"
  run_git clone -q "$TMP_DIR/remote-branch.git" "$TMP_DIR/remote-branch-update"
  (
    cd "$TMP_DIR/remote-branch-update"
    run_git checkout -qb feature/new
    printf '%s\n' 'new remote branch' > FEATURE
    run_git add FEATURE
    run_git commit -qm 'Add remote branch'
    run_git push -qu origin feature/new
  )
  (
    cd "$TMP_DIR/remote-branch-clone"
    "$COMMAND" feature/new
  )
  [ "$(run_git -C "$TMP_DIR/remote-branch-clone" branch --show-current)" = 'feature/new' ] \
    || fail 'new remote branch was not discovered after refresh'
}

test_missing_remote() {
  local repo="$TMP_DIR/no-remote"
  run_git init -q -b main "$repo"
  (
    cd "$repo"
    printf '%s\n' 'local only' > README
    run_git add README
    run_git commit -qm 'Initial commit'
  )
  local output
  output="$(cd "$repo" && "$COMMAND" 2>&1)"
  [[ "$output" == *'has no upstream — skipped pull'* ]] \
    || fail 'a branch without a remote was not handled gracefully'
}

test_rebase_option() {
  make_remote rebase
  run_git clone -q "$TMP_DIR/rebase.git" "$TMP_DIR/rebase-clone"
  local output
  output="$(cd "$TMP_DIR/rebase-clone" && "$COMMAND" --dry-run --rebase 2>&1)"
  [[ "$output" == *'+ git pull --rebase '* ]] \
    || fail '--rebase did not select git pull --rebase'
}

test_ff_only_default() {
  make_remote ff-only
  run_git clone -q "$TMP_DIR/ff-only.git" "$TMP_DIR/ff-only-clone"
  local output
  output="$(cd "$TMP_DIR/ff-only-clone" && "$COMMAND" --dry-run 2>&1)"
  [[ "$output" == *'+ git pull --ff-only '* ]] \
    || fail 'default pull strategy was not fast-forward only'
}

test_dirty_repository() {
  make_remote dirty
  run_git clone -q "$TMP_DIR/dirty.git" "$TMP_DIR/dirty-clone"
  printf '%s\n' 'uncommitted work' >> "$TMP_DIR/dirty-clone/README"
  local before output rc
  before="$(run_git -C "$TMP_DIR/dirty-clone" rev-parse HEAD)"
  if output="$(cd "$TMP_DIR/dirty-clone" && "$COMMAND" 2>&1)"; then
    rc=0
  else
    rc=$?
  fi
  [ "$rc" -eq 4 ] || fail 'a dirty repository did not return the expected error'
  [ "$(run_git -C "$TMP_DIR/dirty-clone" rev-parse HEAD)" = "$before" ] \
    || fail 'a dirty repository changed HEAD'
  [[ "$output" == *'working tree is dirty — left untouched'* ]] \
    || fail 'a dirty repository was not reported'
}

test_divergent_history() {
  make_remote divergent
  run_git clone -q "$TMP_DIR/divergent.git" "$TMP_DIR/divergent-local"
  run_git clone -q "$TMP_DIR/divergent.git" "$TMP_DIR/divergent-remote"
  (
    cd "$TMP_DIR/divergent-local"
    printf '%s\n' 'local commit' > LOCAL
    run_git add LOCAL
    run_git commit -qm 'Local change'
  )
  (
    cd "$TMP_DIR/divergent-remote"
    printf '%s\n' 'remote commit' > REMOTE
    run_git add REMOTE
    run_git commit -qm 'Remote change'
    run_git push -q
  )
  if (cd "$TMP_DIR/divergent-local" && "$COMMAND") >/dev/null 2>&1; then
    fail 'fast-forward-only sync accepted divergent history'
  fi
}

test_force_push() {
  make_remote force-push
  run_git clone -q "$TMP_DIR/force-push.git" "$TMP_DIR/force-push-local"
  run_git clone -q "$TMP_DIR/force-push.git" "$TMP_DIR/force-push-remote"
  (
    cd "$TMP_DIR/force-push-remote"
    printf '%s\n' 'replacement history' > REPLACED
    run_git add REPLACED
    run_git commit -qm 'Replacement commit'
    run_git push -q
    run_git -C "$TMP_DIR/force-push-local" pull -q
    run_git reset --hard -q HEAD~1
    printf '%s\n' 'forced history' > FORCED
    run_git add FORCED
    run_git commit -qm 'Forced update'
    run_git push --force -q
  )
  if (cd "$TMP_DIR/force-push-local" && "$COMMAND") >/dev/null 2>&1; then
    fail 'fast-forward-only sync accepted a force-push'
  fi
}

test_rebase_conflict() {
  make_remote rebase-conflict
  run_git clone -q "$TMP_DIR/rebase-conflict.git" "$TMP_DIR/rebase-conflict-local"
  run_git clone -q "$TMP_DIR/rebase-conflict.git" "$TMP_DIR/rebase-conflict-remote"
  (
    cd "$TMP_DIR/rebase-conflict-local"
    printf '%s\n' 'local change' > README
    run_git commit -am 'Local change' -q
  )
  (
    cd "$TMP_DIR/rebase-conflict-remote"
    printf '%s\n' 'remote change' > README
    run_git commit -am 'Remote change' -q
    run_git push -q
  )
  if (cd "$TMP_DIR/rebase-conflict-local" && "$COMMAND" --rebase) >/dev/null 2>&1; then
    fail 'rebase sync accepted a conflict'
  fi
}

test_special_paths_and_dry_run() {
  make_remote special-path
  (
    cd "$TMP_DIR/special-path-work"
    printf '%s\n' 'quoted path' > "quote'file"
    run_git add "quote'file"
    run_git commit -qm 'Add quoted path'
    run_git push -q "$TMP_DIR/special-path.git" main
  )
  local clone="$TMP_DIR/clone with spaces"
  run_git clone -q "$TMP_DIR/special-path.git" "$clone"
  run_git clone -q "$TMP_DIR/special-path.git" "$TMP_DIR/special-path-update"
  (
    cd "$TMP_DIR/special-path-update"
    printf '%s\n' 'remote update' > README
    run_git commit -am 'Remote update' -q
    run_git push -q
  )
  local before output
  before="$(run_git -C "$clone" rev-parse HEAD)"
  output="$(cd "$clone" && "$COMMAND" --dry-run 2>&1)"
  [ "$(run_git -C "$clone" rev-parse HEAD)" = "$before" ] \
    || fail 'dry-run changed HEAD'
  assert_file_contains "$clone/README" 'special-path initial'
  assert_file_contains "$clone/quote'file" 'quoted path'
  [[ "$output" == *'+ git pull --ff-only '* ]] || fail 'dry-run did not report pull'
}

test_automation_options() {
  make_remote automation
  run_git clone -q "$TMP_DIR/automation.git" "$TMP_DIR/automation-clone"
  local before output
  before="$(run_git -C "$TMP_DIR/automation-clone" rev-parse HEAD)"
  (
    cd "$TMP_DIR/automation-clone"
    "$COMMAND" --fetch-only --json > "$TMP_DIR/automation.json"
  ) 2>/dev/null
  [ "$(run_git -C "$TMP_DIR/automation-clone" rev-parse HEAD)" = "$before" ] \
    || fail 'fetch-only changed HEAD'
  output="$(<"$TMP_DIR/automation.json")"
  [[ "$output" == *'"fetch_only":true'* ]] || fail 'JSON summary did not report fetch-only'
}

test_installer_and_uninstaller() {
  local prefix="$TMP_DIR/install-prefix"
  bash "$ROOT_DIR/install.sh" --prefix "$prefix" --completions >/dev/null
  [ -x "$prefix/bin/git-sync-all" ] || fail 'installer did not install the command'
  [ -f "$prefix/share/bash-completion/completions/git-sync-all" ] \
    || fail 'installer did not install the Bash completion'
  [ -f "$prefix/share/zsh/site-functions/_git-sync-all" ] \
    || fail 'installer did not install the Zsh completion'
  [ "$("$prefix/bin/git-sync-all" --version)" = 'git-sync-all 0.6.0' ] \
    || fail 'installed command did not report the expected version'

  if bash "$ROOT_DIR/install.sh" --prefix "$prefix" --completions >/dev/null 2>&1; then
    fail 'installer overwrote an existing installation without --force'
  fi
  bash "$ROOT_DIR/install.sh" --prefix "$prefix" --completions --force >/dev/null

  bash "$ROOT_DIR/uninstall.sh" --prefix "$prefix" --completions >/dev/null
  [ ! -e "$prefix/bin/git-sync-all" ] || fail 'uninstaller did not remove the command'
  [ ! -e "$prefix/share/bash-completion/completions/git-sync-all" ] \
    || fail 'uninstaller did not remove the Bash completion'
  [ ! -e "$prefix/share/zsh/site-functions/_git-sync-all" ] \
    || fail 'uninstaller did not remove the Zsh completion'
}

test_nested_submodules() {
  make_remote grandchild
  local child_work="$TMP_DIR/child-work" child_remote="$TMP_DIR/child.git"
  run_git init -q -b main "$child_work"
  (
    cd "$child_work"
    run_git submodule add -q "$TMP_DIR/grandchild.git" vendor/grandchild
    run_git commit -qm 'Add nested submodule'
  )
  run_git clone -q --bare "$child_work" "$child_remote"

  local root_work="$TMP_DIR/root-work" root_remote="$TMP_DIR/root.git" root_clone="$TMP_DIR/root-clone"
  local root_uninitialized="$TMP_DIR/root-uninitialized"
  run_git init -q -b main "$root_work"
  (
    cd "$root_work"
    run_git submodule add -q "$child_remote" modules/child
    run_git commit -qm 'Add submodule'
  )
  run_git clone -q --bare "$root_work" "$root_remote"
  run_git -c protocol.file.allow=always clone -q --recurse-submodules "$root_remote" "$root_clone"
  run_git clone -q "$root_remote" "$root_uninitialized"

  run_git clone -q "$TMP_DIR/grandchild.git" "$TMP_DIR/grandchild-update"
  (
    cd "$TMP_DIR/grandchild-update"
    printf '%s\n' 'grandchild updated' > README
    run_git commit -am 'Update nested remote' -q
    run_git push -q
  )

  (
    cd "$root_clone"
    local quoted_command="$TMP_DIR/tool's-bin/git-sync-all"
    mkdir -p "$(dirname "$quoted_command")"
    cp "$COMMAND" "$quoted_command"
    chmod +x "$quoted_command"
    "$quoted_command"
  )
  assert_file_contains "$root_clone/modules/child/vendor/grandchild/README" 'grandchild updated'

  local output
  output="$(cd "$root_uninitialized" && "$COMMAND" 2>&1)"
  [[ "$output" == *'uninitialized submodules were skipped'* ]] \
    || fail 'uninitialized submodules were not reported'
  [ ! -e "$root_uninitialized/modules/child/README" ] \
    || fail 'submodules were initialized without --init-submodules'

  (
    cd "$root_uninitialized"
    "$COMMAND" --init-submodules
  )
  assert_file_contains "$root_uninitialized/modules/child/vendor/grandchild/README" 'grandchild updated'
}

test_release_publisher() {
  local calls="$TMP_DIR/release-publisher-calls"

  gh() {
    printf '%s\n' "$*" >> "$calls"
    if [ "$1" = release ] && [ "$2" = view ]; then
      [ "${FAKE_RELEASE_EXISTS:-0}" = 1 ]
    fi
  }

  FAKE_RELEASE_EXISTS=0
  publish_release_assets "v-test" "first-asset" "second-asset"
  assert_file_contains "$calls" "release create v-test first-asset second-asset --generate-notes"

  : > "$calls"
  FAKE_RELEASE_EXISTS=1
  publish_release_assets "v-test" "first-asset" "second-asset"
  assert_file_contains "$calls" "release upload v-test first-asset second-asset --clobber"
}

test_regular_repository
test_missing_branch
test_remote_branch_refresh
test_missing_remote
test_rebase_option
test_ff_only_default
test_dirty_repository
test_divergent_history
test_force_push
test_rebase_conflict
test_special_paths_and_dry_run
test_automation_options
test_installer_and_uninstaller
test_nested_submodules
test_release_publisher
printf 'All git-sync-all integration tests passed.\n'
