#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/test-bin"

cat > "$tmpdir/test-bin/fzf" <<'EOF'
#!/usr/bin/env sh
tee "$FZF_TEST_INPUT" | grep 'cp-selected'
EOF
chmod +x "$tmpdir/test-bin/fzf"

cat > "$tmpdir/test-bin/entire" <<'EOF'
#!/usr/bin/env sh
case "$1 $2" in
  'checkpoint list')
    printf '  branch       main\n'
    printf '  checkpoints  2\n'
    printf '\n'
    printf '● cp-selected selected checkpoint\n'
    printf '  06-06 19:40 (2a482d5) Explain selected checkpoint from picker\n'
    ;;
  *)
    printf '%s\n' "$*" >> "$ENTIRE_TEST_LOG"
    ;;
esac
EOF
chmod +x "$tmpdir/test-bin/entire"

export ENTIRE_TEST_LOG="$tmpdir/entire.log"
export FZF_TEST_INPUT="$tmpdir/fzf-input.txt"

env -u NO_COLOR PATH="$tmpdir/test-bin:$PATH" zsh -fc "
  source '$repo_root/entire-fzf.plugin.zsh'

  _entire_session_fzf() {
    print -r -- 'session-1\tactive\tcodex\t06-06 19:00\t-\t2026'
  }

  _entire_action_pick() {
    print -r -- 'checkpoints  : pick checkpoint to explain'
  }

  _entire_session_action
"

actual=$(cat "$ENTIRE_TEST_LOG")
expected='checkpoint explain cp-selected'

if [[ "$actual" != "$expected" ]]; then
  print -u2 "Expected '$expected', got '$actual'"
  exit 1
fi

fzf_input=$(cat "$FZF_TEST_INPUT")
expected_fzf_input=$'checkpoint_id\tcheckpoint_id\tmessage\ncp-selected\t\033[33mcp-selected\033[0m\tselected checkpoint'

if [[ "$fzf_input" != "$expected_fzf_input" ]]; then
  print -u2 "Unexpected fzf checkpoint input:"
  print -u2 -- "$fzf_input"
  exit 1
fi
