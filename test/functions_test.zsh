#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
source "$repo_root/entire-fzf.plugin.zsh"

for function_name in etf etfd etfr; do
  actual=$(whence -w "$function_name")
  expected="$function_name: function"

  if [[ "$actual" != "$expected" ]]; then
    print -u2 "Expected '$expected', got '$actual'"
    exit 1
  fi
done

for old_function_name in es esd esr; do
  if whence -w "$old_function_name" >/dev/null; then
    print -u2 "Expected '$old_function_name' to be undefined"
    exit 1
  fi
done
