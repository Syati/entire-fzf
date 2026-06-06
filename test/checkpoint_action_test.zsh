#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/test-bin"

cat > "$tmpdir/test-bin/fzf" <<'EOF'
#!/usr/bin/env sh
grep 'cp-selected'
EOF
chmod +x "$tmpdir/test-bin/fzf"

cat > "$tmpdir/test-bin/entire" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$*" >> "$ENTIRE_TEST_LOG"
EOF
chmod +x "$tmpdir/test-bin/entire"

export ENTIRE_TEST_LOG="$tmpdir/entire.log"

PATH="$tmpdir/test-bin:$PATH" zsh -fc "
  source '$repo_root/entire-zsh.plugin.zsh'

  _entire_session_fzf() {
    print -r -- 'session-1\tactive\tcodex\t06-06 19:00\t-\t2026'
  }

  _entire_action_pick() {
    print -r -- 'checkpoints  : pick checkpoint to explain'
  }

  _entire_checkpoint_list_by_session() {
    print -r -- 'cp-old older checkpoint'
    print -r -- '● cp-selected selected checkpoint'
  }

  _entire_session_action
"

actual=$(cat "$ENTIRE_TEST_LOG")
expected='checkpoint explain cp-selected'

if [[ "$actual" != "$expected" ]]; then
  print -u2 "Expected '$expected', got '$actual'"
  exit 1
fi
