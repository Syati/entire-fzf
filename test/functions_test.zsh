#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
source "$repo_root/entire-zsh.plugin.zsh"

for function_name in es esd esr; do
  actual=$(whence -w "$function_name")
  expected="$function_name: function"

  if [[ "$actual" != "$expected" ]]; then
    print -u2 "Expected '$expected', got '$actual'"
    exit 1
  fi
done
