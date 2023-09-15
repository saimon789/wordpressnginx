#!/bin/bash

# rundeps
# Runs provided command in the meantime starting required number of socats in
# order to attach to default ports to localhost external services.

# Make sure that any errors cause the script to exit immediately.
set -e

# ## Running commands

# When a process is started, we want to keep track of its pid so we can
# `kill` it when the parent process receives a signal, and so we can `wait`
# for it to finish before exiting the parent process.
store_pid() {
  pids=("${pids[@]}" "$1")
}

# This starts a command asynchronously and stores its pid in a list for use
# later on in the script.
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

# ## Starting socats

# The conventional environment variables must be gathered and parsed
# then used to run socats.

to_link_tuple() {
  sed 's/.*_PORT_\([0-9]*\)_TCP=tcp:\/\/\(.*\):\(.*\)/\1,\2,\3/'
}

to_socat_call() {
  sed 's/\(.*\),\(.*\),\(.*\)/socat -ls TCP4-LISTEN:\1,fork,reuseaddr TCP4:\2:\3/'
}

env | grep '_TCP=' | to_link_tuple | sort | uniq | to_socat_call | start_commands

# ## Cleanup

# When script is about to exit, which is usually due to main target
# interruption, this action is run, killing the child processes. The
# sleep stops STDOUT from pouring over the prompt, it should go at
# some point.
onexit() {
  echo Exiting
  echo sending SIGTERM to all processes
  kill ${pids[*]} &>/dev/null
  sleep 1
}
trap onexit EXIT

# Run the given command
exec "$*"
