# fzf helpers for Entire CLI sessions.
#
# Usage:
#   es     # session picker -> action picker (explain/checkpoints/info/stop/clean)
#   esd    # entire dispatch --local
#   esr    # pick branch and run entire session resume <branch>

_entire_session_list() {
  command entire session list --json 2>/dev/null |
    jq -r '
      def ts_parts($ts):
        ($ts | tostring | try capture("^(?<y>[0-9]{4})-(?<m>[0-9]{2})-(?<d>[0-9]{2})[T ](?<h>[0-9]{2}):(?<min>[0-9]{2})") catch null);
      def fmt($ts):
        (ts_parts($ts) as $p | if $p == null then "" else "\($p.m)-\($p.d) \($p.h):\($p.min)" end);
      def year($ts):
        (ts_parts($ts) as $p | if $p == null then "" else $p.y end);
      .[] |
      [
        (.session_id // ""),
        (.status // ""),
        (.agent // ""),
        (fmt(.started_at // .last_active // "")),
        (fmt(.ended_at // "") // "-" | if . == "" then "-" else . end),
        (year(.started_at // .last_active // ""))
      ] | @tsv
    '
}

_entire_session_table() {
  _entire_session_list |
    awk -F '\t' '
      BEGIN {
        printf "__HEADER__\t%10s\t%14s\t%14s\t%14s\t%6s\n", "status", "agent", "started_at", "ended_at", "year"
      }
      {
        printf "%s\t%10s\t%14s\t%14s\t%14s\t%6s\n", $1, $2, $3, $4, $5, $6
      }
    '
}

_entire_session_fzf() {
  local preview_window="$1"

  _entire_session_table |
    fzf --ansi \
      --header-lines=1 \
      --with-nth=2.. \
      --delimiter=$'\t' \
      --prompt='entire session> ' \
      --footer='Enter: select session | Ctrl-/: toggle preview' \
      --bind='ctrl-/:toggle-preview' \
      --preview='entire session info {1} --json 2>/dev/null | jq -C . || true' \
      --preview-window="$preview_window"
}

_entire_action_pick() {
  printf '%s\n' \
    'explain      : explain latest checkpoint' \
    'checkpoints  : list checkpoints' \
    'info         : session info' \
    'stop         : stop session' \
    'clean        : entire clean --session' |
    fzf --ansi \
      --prompt='entire action> ' \
      --delimiter=':' \
      --with-nth=1,2 \
      --height=50% \
      --reverse \
      --footer='Enter: run selected action'
}

_entire_branch_pick() {
  local current_branch selected
  current_branch=$(git branch --show-current 2>/dev/null)

  selected=$(
    git for-each-ref --format='%(refname:short)' --sort=-committerdate refs/heads refs/remotes/origin 2>/dev/null |
      sed -e '/^origin\/HEAD$/d' -e 's#^origin/##' |
      awk -v cur="$current_branch" 'NF && $0 !~ /^entire\// && !seen[$0]++ { printf "%s\t%s\n", ($0 == cur ? "*" : " "), $0 }' |
      fzf --ansi \
        --delimiter=$'\t' \
        --with-nth=1,2 \
        --prompt='entire branch> ' \
        --height=40% \
        --reverse \
        --preview='git -c color.ui=always log --color=always --oneline --decorate -n 20 {2} 2>/dev/null || git -c color.ui=always log --color=always --oneline --decorate -n 20 origin/{2} 2>/dev/null || echo "No commit preview available"' \
        --preview-window='down:60%:wrap' \
        --footer='Enter: run entire session resume on selected branch'
  ) || return

  [[ -n "$selected" ]] || return
  cut -f2 <<< "$selected"
}

_entire_checkpoint_list_by_session() {
  local session_id
  session_id="$1"

  [[ -n "$session_id" ]] || return 1
  command entire checkpoint list --session "$session_id"
}

_entire_latest_checkpoint_id_by_session() {
  local session_id checkpoint_id
  session_id="$1"

  [[ -n "$session_id" ]] || return 1

  checkpoint_id=$(
    _entire_checkpoint_list_by_session "$session_id" |
      awk '/^●[[:space:]]+/ { print $2; exit }'
  )

  [[ -n "$checkpoint_id" ]] || {
    print -u2 'No checkpoint found for selected session.'
    return 1
  }

  print -r -- "$checkpoint_id"
}

_entire_session_action() {
  local line session_id checkpoint_id action

  line=$(_entire_session_fzf 'down:70%:wrap') || return
  [[ -n "$line" ]] || return

  session_id=$(cut -f1 <<< "$line")
  action=$(_entire_action_pick | awk -F ':' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1}') || return

  case "$action" in
    explain)
      checkpoint_id=$(_entire_latest_checkpoint_id_by_session "$session_id") || return
      command entire checkpoint explain "$checkpoint_id"
      ;;
    checkpoints)
      _entire_checkpoint_list_by_session "$session_id"
      ;;
    info)
      command entire session info "$session_id"
      ;;
    stop)
      command entire session stop "$session_id"
      ;;
    clean)
      command entire clean --session "$session_id"
      ;;
    *)
      return 1
      ;;
  esac
}

es() {
  _entire_session_action
}

esd() {
  command entire dispatch --local
}

esr() {
  local branch
  branch=$(_entire_branch_pick) || return
  [[ -n "$branch" ]] || return
  command entire session resume "$branch"
}
