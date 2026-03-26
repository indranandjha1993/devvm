_devvm() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local stacks="mysql postgres redis nginx grafana prometheus loki tempo promtail cadvisor obs"
  commands="init start stop restart reset destroy logs ssh run exec open status debug db creds app ports verify version help"

  case "$prev" in
    devvm)
      COMPREPLY=($(compgen -W "$commands" -- "$cur"))
      ;;
    start|stop|restart|reset|logs)
      COMPREPLY=($(compgen -W "$stacks" -- "$cur"))
      ;;
    debug)
      COMPREPLY=($(compgen -W "python node php go java" -- "$cur"))
      ;;
    db)
      COMPREPLY=($(compgen -W "mysql psql redis" -- "$cur"))
      ;;
    open)
      COMPREPLY=($(compgen -W "grafana adminer prometheus loki tempo" -- "$cur"))
      ;;
    creds)
      COMPREPLY=($(compgen -W "list show set reset" -- "$cur"))
      ;;
    app)
      COMPREPLY=($(compgen -W "add remove list create" -- "$cur"))
      ;;
  esac
}
complete -F _devvm devvm
