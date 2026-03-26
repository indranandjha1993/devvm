_devvm() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  commands="init provision up down stop start restart reboot destroy ssh run exec open status service obs debug db creds app ports verify version help"

  case "$prev" in
    devvm)
      COMPREPLY=($(compgen -W "$commands" -- "$cur"))
      ;;
    debug)
      COMPREPLY=($(compgen -W "python node php go java" -- "$cur"))
      ;;
    db)
      COMPREPLY=($(compgen -W "mysql psql redis" -- "$cur"))
      ;;
    obs)
      COMPREPLY=($(compgen -W "up down start stop restart logs status" -- "$cur"))
      ;;
    open)
      COMPREPLY=($(compgen -W "grafana adminer prometheus loki tempo" -- "$cur"))
      ;;
    service|svc)
      COMPREPLY=($(compgen -W "start stop restart status logs" -- "$cur"))
      ;;
    creds)
      COMPREPLY=($(compgen -W "list show set reset" -- "$cur"))
      ;;
    app)
      COMPREPLY=($(compgen -W "add remove list start stop restart logs create" -- "$cur"))
      ;;
  esac
}
complete -F _devvm devvm
