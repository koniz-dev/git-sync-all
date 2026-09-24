# git-sync-all

Sync a Git superproject and all of its submodules onto a chosen branch, then
pull each branch's upstream. When no branch is given, each repository uses its
own default branch. Install it on `PATH` and invoke it naturally as a Git
subcommand: `git sync-all`.

## Install

```bash
git clone https://github.com/koniz-dev/git-sync-all.git
cd git-sync-all
./install.sh
```

The installer places `git-sync-all` in `~/.local/bin`. Ensure that directory is
on your `PATH`, then verify the installation:

```bash
git sync-all --version
```

Pass `--completions` to install the bundled Bash and Zsh completions under the
same prefix:

```bash
./install.sh --completions
```

The installer refuses to replace an existing command or completion file. Pass
`--force` only when you intentionally want to replace a prior installation.

To remove the command, run `./uninstall.sh`; add `--completions` to remove the
completion files too. Neither command removes directories or other files.

### Homebrew

```bash
brew tap koniz-dev/tap
brew install git-sync-all
```

The formula installs the command and Bash/Zsh completions.

### Windows

The command is supported on Windows 11 through Git Bash or WSL. For a native
PowerShell prompt with Git for Windows installed, use the PowerShell installer:

```powershell
.\install.ps1
```

It installs the Bash command and a `git-sync-all.cmd` wrapper in
`~\.local\bin`, then adds that directory to the user `PATH`. Open a new
terminal and run `git sync-all --version`. The wrapper runs the command with
Git Bash, so Git's Unix utilities (`mktemp`, `sed`, `wc`, and `tr`) are
available without a separate dependency.
It also refuses to replace an existing installation unless `-Force` is passed.

Remove the Windows installation with:

```powershell
.\uninstall.ps1
```

## Supported environments

The supported environments are macOS, Ubuntu LTS, and Windows 11. On Windows,
use Git Bash, WSL, or the PowerShell installer with Git for Windows. CI runs
the syntax and integration suite on `macos-latest`, `ubuntu-latest`, and
`windows-latest` (with Git Bash).

## Usage

Run inside the superproject:

```bash
git sync-all              # default branch in every repository
git sync-all feature/foo  # only repositories that already have feature/foo
git sync-all --dry-run    # print checkout and pull commands only
git sync-all --rebase     # rebase local commits while pulling
git sync-all --merge      # merge while pulling
git sync-all --init-submodules  # initialize missing submodules, then sync them
git sync-all --fetch-only # fetch remote refs without changing the checkout
git sync-all --no-submodules  # sync the superproject only
git sync-all --verbose     # print the Git commands being run
git sync-all --json        # emit a final JSON summary to stdout
```

With an explicit branch, a repository that does not have that branch locally
or on `origin` is left untouched and listed after the run. The command never
creates the requested branch. A submodule's `branch` setting in `.gitmodules`
is used when no explicit branch was supplied; `branch = .` follows the
superproject's default-branch behavior.

`--dry-run` does not initialise missing submodules; it reports the init command
and simulates changes only for submodules that are already available locally.

By default, `git sync-all` uses `git pull --ff-only`: it will never create a
merge commit and stops if local and upstream histories have diverged. Pass
`--rebase` to rebase local commits, or `--merge` to explicitly allow a merge,
for the superproject and every submodule.

Before resolving a branch, the command fetches and prunes `origin` so a branch
created remotely can be selected in the same invocation.

The command refuses to change a repository with tracked or untracked changes.
Use `--allow-dirty` only when you understand the checkout and pull operations
will not overwrite your work. Missing submodules are skipped by default; use
`--init-submodules` to clone and update them from the URLs in `.gitmodules`.

`--fetch-only` does not inspect or change the checkout. `--no-submodules`
skips all submodule work. `--json` reserves standard output for one final JSON
summary; command and Git output is sent to standard error. `--verbose` prints
commands as they execute.

## Requirements

- Git 2.20 or later
- Bash 3.2 or later (macOS, Linux, Git Bash, or WSL)

The tool is intended for local development workspaces. Updating a submodule to
a newer branch commit can make its superproject show a modified gitlink; commit
that gitlink separately if you intend to record the new submodule revision.

## Release verification

Release tags are signed with SSH and verified in CI against
[`keys/allowed_signers`](keys/allowed_signers). Each GitHub release includes a
source archive, a SHA-256 checksum, and a GitHub artifact attestation. Verify a
tag locally with:

```bash
git config gpg.format ssh
git config gpg.ssh.allowedSignersFile keys/allowed_signers
git verify-tag v0.5.0
```

## Shell completion

For zsh, copy `completions/_git-sync-all` into a directory on `fpath`. For
Bash, source `completions/git-sync-all.bash` from your shell profile.

## Development

```bash
bash -n bin/git-sync-all install.sh uninstall.sh
bin/git-sync-all --help
bash test/test-git-sync-all.sh
```

On Windows, also validate the PowerShell installer:

```powershell
.\install.ps1 -Prefix "$env:TEMP\git-sync-all-bin" -NoPath
.\uninstall.ps1 -Prefix "$env:TEMP\git-sync-all-bin"
```

Contributions are welcome under the MIT License.
