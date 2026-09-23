_git_sync_all() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W '--help --version --dry-run --rebase' -- "$cur") )
}
complete -F _git_sync_all git-sync-all
