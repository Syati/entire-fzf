#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
source "$repo_root/entire-zsh.plugin.zsh"

_entire_session_list() {
  print -r -- $'session-1\trunning\tcodex\t06-06 19:00\t-\t2026'
}

session_table=$(_entire_session_table)

if [[ "$session_table" != *$'\033[32m   running\033[0m'* ]]; then
  print -u2 "Expected padded colored running session status:"
  print -u2 -- "$session_table"
  exit 1
fi

_entire_checkpoint_list_by_session() {
  print -r -- '● cp-1 colored checkpoint'
}

checkpoint_table=$(_entire_checkpoint_table_by_session session-1)

if [[ "$checkpoint_table" != *$'\033[36mcp-1\033[0m'* || "$checkpoint_table" != *$'\033[33mcolored checkpoint\033[0m'* ]]; then
  print -u2 "Expected colored checkpoint table:"
  print -u2 -- "$checkpoint_table"
  exit 1
fi
