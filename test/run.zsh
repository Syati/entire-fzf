#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}

zsh "$repo_root/test/functions_test.zsh"
zsh "$repo_root/test/checkpoint_action_test.zsh"
zsh "$repo_root/test/no_color_test.zsh"
