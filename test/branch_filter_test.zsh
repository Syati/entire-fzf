#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cp "$repo_root/entire-fzf.plugin.zsh" "$tmpdir/"
cd "$tmpdir"

git init -q
git config user.name "Test"
git config user.email "test@example.com"
touch README.md
git add README.md
git -c commit.gpgsign=false commit -q -m init
git checkout -q -b feature/demo
git checkout -q -b entire/checkpoints/v1
git checkout -q feature/demo
git update-ref refs/remotes/origin/feature/remote HEAD
git update-ref refs/remotes/origin/entire/remote HEAD
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/feature/remote

mkdir -p test-bin
cat > test-bin/fzf <<'EOF'
#!/usr/bin/env sh
cat
EOF
chmod +x test-bin/fzf

output=$(PATH="$PWD/test-bin:$PATH" zsh -fc 'source ./entire-fzf.plugin.zsh; _entire_branch_pick')

if ! print -r -- "$output" | grep -qx 'feature/demo'; then
  print -u2 "Expected local feature branch in output:"
  print -u2 -- "$output"
  exit 1
fi

if ! print -r -- "$output" | grep -qx 'feature/remote'; then
  print -u2 "Expected remote feature branch in output:"
  print -u2 -- "$output"
  exit 1
fi

if print -r -- "$output" | grep -q '^entire/'; then
  print -u2 "Expected entire/* branches to be filtered:"
  print -u2 -- "$output"
  exit 1
fi

if print -r -- "$output" | grep -qx 'origin'; then
  print -u2 "Expected origin/HEAD to be filtered:"
  print -u2 -- "$output"
  exit 1
fi
