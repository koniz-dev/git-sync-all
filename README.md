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
```

With an explicit branch, a repository that does not have that branch locally
or on `origin` is left untouched and listed after the run. The command never
creates the requested branch. A submodule's `branch` setting in `.gitmodules`
is used when no explicit branch was supplied; `branch = .` follows the
superproject's default-branch behavior.

`--dry-run` does not initialise missing submodules; it reports the init command
and simulates changes only for submodules that are already available locally.

By default, `git sync-all` uses `git pull`, respecting the pull strategy
configured in each repository. Pass `--rebase` to use `git pull --rebase` for
the superproject and every submodule.

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
