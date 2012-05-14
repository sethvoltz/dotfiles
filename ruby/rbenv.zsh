# Ruby Environment Manager
# /!\ MAKE SURE this is in zshenv.symlink or non-interactive shells will fail on Ruby
#     eval "$(rbenv init -)"

# rehash shims
rbenv rehash 2>/dev/null

# shell thing
rbenv() {
  command="$1"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
  shell)
    eval `rbenv "sh-$command" "$@"`;;
  *)
    command rbenv "$command" "$@";;
  esac
}
