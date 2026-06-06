#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
source "$repo_root/entire-zsh.plugin.zsh"

_entire_checkpoint_list_by_session() {
  print -r -- '● cp-1 plain checkpoint'
}

checkpoint_table=$(NO_COLOR=1 _entire_checkpoint_table_by_session session-1)
expected=$'checkpoint_id\tcheckpoint_id\tmessage\ncp-1\tcp-1\tplain checkpoint'

if [[ "$checkpoint_table" != "$expected" ]]; then
  print -u2 "Expected uncolored checkpoint table when NO_COLOR is set:"
  print -u2 -- "$checkpoint_table"
  exit 1
fi
