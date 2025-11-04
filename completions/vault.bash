# Bash completion for the 'vault' CLI

# Fallback if bash-completion isn't loaded
__vault_init_completion_fallback() {
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
}

# Try to use bash-completion helpers if present
__vault_init_completion() {
  if declare -F _init_completion >/dev/null 2>&1; then
    _init_completion -s || return 1
  else
    __vault_init_completion_fallback
  fi
}

# Discover subcommands by scanning bundle + common dirs + local scripts
__vault_discover_subcommands() {
  local subs="install uninstall toggle sync status recover help"
  local d f sc
  local dirs=( 
    "/usr/local/share/vault"     # installed location
    "/usr/local/bin" 
    "$HOME/bin"
    "./scripts"                  # local development
  )
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    for f in "$d"/vault-*; do
      [[ -e "$f" ]] || continue
      [[ -x "$f" && -f "$f" ]] || continue
      sc="${f##*/vault-}"
      [[ -n "$sc" ]] || continue
      case " $subs " in *" $sc "*) ;; *) subs="$subs $sc";; esac
    done
  done
  echo "$subs"
}

_vault() {
  local cur prev
  __vault_init_completion || true

  # First arg: subcommand
  if [[ $COMP_CWORD -eq 1 ]]; then
    local subs
    subs="$(__vault_discover_subcommands)"
    COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
    return 0
  fi

  # Subcommand-specific completion
  case "${COMP_WORDS[1]}" in
    install|uninstall|toggle|status|help)
      COMPREPLY=()   # no extra args
      ;;
    sync)
      # Suggest some lightweight commit message templates
      local templates='"Update notes" "sync: update vault" "docs: edit"'
      COMPREPLY=( $(compgen -W "$templates" -- "$cur") )
      ;;
    recover)
      # Suggest recovery subcommands
      local recovery_actions="backup restore change-password verify help"
      COMPREPLY=( $(compgen -W "$recovery_actions" -- "$cur") )
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

complete -F _vault vault
