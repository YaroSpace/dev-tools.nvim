#!/usr/bin/env bash

export TERM=xterm-color

if ! command -v nvim &> /dev/null; then
  echo "nvim is not installed"
  exit 1
fi

install_dependencies() {
  echo "Installing dependencies..."
}

run() {
  nvim --version
  if [[ -n $1 ]]; then
    nvim -l tests/minit.lua tests --filter "$1"
  else
    nvim -l tests/minit.lua tests --shuffle-tests -o utfTerminal -Xoutput --color -v
  fi
}

main() {
  local action="$1"
  shift

  local args=$*

  case $action in
    "run")
      install_dependencies
      run "$args"
      ;;
    *)
      echo "Invalid action"
      exit 1
      ;;
  esac
}

main "$@"
