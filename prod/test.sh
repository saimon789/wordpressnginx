#!/bin/bash

set -e

store_pid() {
  pids=("${pids[@]}" "$1")
}

start_command() {
  echo "Running $1"
  bash -c "$1" &
  pid="$!"
  store_pid "$pid"
}

start_commands() {
  while read cmd; do
    start_command "$cmd"
  done
}

to_link_tuple() {
  sed 's/.*_PORT_\([0-9]*\)_TCP=tcp:\/\/\(.*\):\(.*\)/\1,\2,\3/'
}

to_socat_call() {
  sed 's/\(.*\),\(.*\),\(.*\)/socat -ls TCP4-LISTEN:\1,fork,reuseaddr TCP4:\2:\3/'
}

env | grep '_TCP=' | to_link_tuple | sort | uniq | to_socat_call | start_commands

onexit() {
  echo Exiting
  echo sending SIGTERM to all processes
  kill ${pids[*]} &>/dev/null
}
trap onexit EXIT

exec "$*"
