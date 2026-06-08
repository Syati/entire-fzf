#!/usr/bin/env zsh
set -euo pipefail

repo_root=${0:A:h:h}
source "$repo_root/entire-fzf.plugin.zsh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/test-bin"
cat > "$tmpdir/test-bin/entire" <<'EOF'
#!/usr/bin/env sh
printf '● cp-1 plain checkpoint\n'
EOF
chmod +x "$tmpdir/test-bin/entire"

checkpoint_table=$(NO_COLOR=1 PATH="$tmpdir/test-bin:$PATH" _entire_checkpoint_table_by_session session-1)
expected=$'checkpoint_id\tcheckpoint_id\tmessage\ncp-1\tcp-1\tplain checkpoint'

if [[ "$checkpoint_table" != "$expected" ]]; then
  print -u2 "Expected uncolored checkpoint table when NO_COLOR is set:"
  print -u2 -- "$checkpoint_table"
  exit 1
fi
