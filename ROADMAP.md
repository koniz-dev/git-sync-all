# Roadmap

## v0.1.0 — Publish

- [x] Extract the command into the `bin/git-sync-all` executable.
- [x] Add an installer, Bash/Zsh completion, README, and MIT License.
- [x] Add `--help`, `--version`, and `--dry-run`.
- [x] Run syntax checks and local smoke tests.
- [x] Commit and publish the `koniz-dev/git-sync-all` repository.
- [x] Create the `v0.1.0` GitHub Release with short release notes.

Publish from a terminal authenticated with GitHub:

```bash
cd /Users/nguyenanhkiet/Playground/git-sync-all
git add .
git commit -m "Initial release"
gh repo create git-sync-all --public --source=. --remote=origin --push
gh release create v0.1.0 --title "v0.1.0" --generate-notes
```

## v0.2.0 — Reliability

- [x] Add automated tests for regular repositories, missing branches, missing remotes, and nested submodules.
- [x] Run ShellCheck in GitHub Actions.
- [x] Add CI for `bash -n` and smoke tests.
- [x] Add a `--rebase` flag or document a clear pull strategy.

## v0.3.0 — Cross-platform support

Ensure the command works on macOS, Linux, and Windows instead of relying only
on the Bash available on the development machine.

- [x] Define the official support matrix: macOS, Ubuntu LTS, and Windows 11.
- [x] Keep the Bash implementation for macOS/Linux and Git Bash/WSL on Windows.
- [x] Add a PowerShell installer (`install.ps1`) for native Windows use.
- [x] Ensure `git-sync-all` is recognized as a Git subcommand from PATH on Windows.
- [x] Check dependencies and temporary paths for Unix-only assumptions such as
  `mktemp`, `sed`, `wc`, and `tr`.
- [x] If Git for Windows is insufficiently compatible, move orchestration to
  PowerShell or release a cross-platform binary.
- [x] Add a GitHub Actions matrix that runs smoke tests on `macos-latest`,
  `ubuntu-latest`, and `windows-latest`.
- [x] Document the tested environments and supported fallbacks in the README
  (Git Bash/WSL on Windows).

## v0.4.0 — Distribution

- [x] Create a Homebrew tap and the `git-sync-all` formula.
- [x] Install completion automatically through the installer with an opt-in option.
- [x] Add uninstall scripts.

## v0.5.0 — Safety and hardening

- [x] Use `git pull --ff-only` by default, with explicit `--rebase` and
  `--merge` strategies.
- [x] Refuse to change repositories with dirty working trees unless
  `--allow-dirty` is passed.
- [x] Require `--init-submodules` before cloning or updating uninitialized
  submodules.
- [x] Refuse to overwrite an existing installation unless `--force` is passed.
- [x] Pin GitHub Actions to full commit SHAs and keep the checkout action
  current.
- [x] Add tests for dirty trees, divergent branches, force-pushes, rebase
  conflicts, paths containing spaces or quotes, and dry-run immutability.
- [x] Test the PowerShell uninstaller, completion installation, and Homebrew
  formula end-to-end in CI.
- [x] Publish signed tags, checksums, and release provenance.
- [x] Add `--json`, `--verbose`, `--fetch-only`, and `--no-submodules` for
  automation and diagnostics.
- [x] Document minimum supported Git and Bash versions.
- [x] Pin a regression-test matrix to supported platform versions while running
  a scheduled job against current runner images.

## v0.6.0 — Correctness and operational resilience

- [ ] Refresh `origin` refs before resolving default or requested branches.
- [ ] Make `--json` report skipped and failed outcomes accurately.
- [ ] Make the release workflow idempotent when re-run.
- [ ] Make the PowerShell installer resilient to Unicode paths and avoid
  selecting an unrelated `bash` executable from `PATH`.
- [ ] Test quoted repository paths on Windows or document the platform
  limitation explicitly.
- [ ] Align the documented Windows support claim with a Windows 11 test target.
- [ ] Document release-signing key rotation and configure a backup signer.
