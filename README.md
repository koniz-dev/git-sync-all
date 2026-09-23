# git-sync-all

Sync a Git superproject and all of its submodules onto a chosen branch, then
pull each branch's upstream. When no branch is given, each repository uses its
own default branch. Install it on `PATH` and invoke it naturally as a Git
subcommand: `git sync-all`.

## Install

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/git-sync-all.git
cd git-sync-all
./install.sh
```

The installer places `git-sync-all` in `~/.local/bin`. Ensure that directory is
on your `PATH`, then verify the installation:

```bash
git sync-all --version
```

## Usage

Run inside the superproject:

```bash
git sync-all              # default branch in every repository
git sync-all feature/foo  # only repositories that already have feature/foo
git sync-all --dry-run    # print checkout and pull commands only
```

With an explicit branch, a repository that does not have that branch locally
or on `origin` is left untouched and listed after the run. The command never
creates the requested branch. A submodule's `branch` setting in `.gitmodules`
is used when no explicit branch was supplied; `branch = .` follows the
superproject's default-branch behavior.

`--dry-run` does not initialise missing submodules; it reports the init command
and simulates changes only for submodules that are already available locally.

## Shell completion

For zsh, copy `completions/_git-sync-all` into a directory on `fpath`. For
Bash, source `completions/git-sync-all.bash` from your shell profile.

## Release as a Homebrew tap

After publishing a tagged GitHub release, create a tap repository containing a
formula which installs `bin/git-sync-all`. The initial version can simply fetch
the tagged source archive and use `bin.install "bin/git-sync-all"`; add its
SHA-256 to the formula. See Homebrew's Formula Cookbook for the current formula
metadata and audit requirements.

## Development

```bash
bash -n bin/git-sync-all install.sh
bin/git-sync-all --help
bash test/test-git-sync-all.sh
```

Contributions are welcome under the MIT License.
