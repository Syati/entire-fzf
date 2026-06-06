#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}

zsh "$repo_root/test/functions_test.zsh"
zsh "$repo_root/test/branch_filter_test.zsh"
