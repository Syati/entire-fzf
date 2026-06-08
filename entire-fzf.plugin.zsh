# fzf helpers for Entire CLI sessions.
#
# Usage:
#   etf    # session picker -> action picker (resume/explain/checkpoints/info/stop/clean)
#   etfd   # entire dispatch --local

typeset -r _ENTIRE_PREVIEW_WINDOW='down,70%,wrap'

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
  _entire_session_table |
    fzf --ansi \
      --header-lines=1 \
      --with-nth=2.. \
      --delimiter=$'\t' \
      --prompt='entire session> ' \
      --footer='Enter: select session | Ctrl-/: toggle preview' \
      --bind='ctrl-/:toggle-preview' \
      --preview='entire session info {1} --json 2>/dev/null | jq -C . || true' \
      --preview-window="$_ENTIRE_PREVIEW_WINDOW"
}

_entire_action_pick() {
  printf '%s\n' \
    'resume       : resume session and reopen matching agent' \
    'explain      : explain latest checkpoint' \
    'checkpoints  : pick checkpoint to explain' \
    'info         : session info' \
    'stop         : stop session' \
    'clean        : entire clean --session' |
    fzf --ansi \
      --prompt='entire action> ' \
      --delimiter=':' \
      --with-nth=1,2 \
      --height=~50% \
      --reverse \
      --footer='Enter: run selected action'
}

_entire_checkpoint_table_by_session() {
  command entire checkpoint list --session "$1" 2>/dev/null |
    awk '
      BEGIN {
        reset = "\033[0m"
        checkpoint_id_color = ENVIRON["ENTIRE_ZSH_CHECKPOINT_ID_COLOR"]
        if (ENVIRON["NO_COLOR"] != "") {
          checkpoint_id_color = ""
          reset = ""
        } else if (checkpoint_id_color == "") {
          checkpoint_id_color = "\033[33m"
        }
        printf "%s\t%s\t%s\n", "checkpoint_id", "checkpoint_id", "message"
      }
      /^●[[:space:]]+/ {
        checkpoint_id = $2
        message = $0
        sub(/^●[[:space:]]+[^[:space:]]+[[:space:]]+/, "", message)
        printf "%s\t%s\t%s\n", checkpoint_id, checkpoint_id_color checkpoint_id reset, message
      }
    '
}

_entire_latest_checkpoint_id_by_session() {
  local checkpoint_id
  [[ -n "$1" ]] || return 1

  checkpoint_id=$(
    command entire checkpoint list --session "$1" 2>/dev/null |
      awk '/^●[[:space:]]+/ { print $2; exit }'
  )

  [[ -n "$checkpoint_id" ]] || {
    print -u2 'No checkpoint found for selected session.'
    return 1
  }

  print -r -- "$checkpoint_id"
}

_entire_checkpoint_pick_by_session() {
  local checkpoint_id
  [[ -n "$1" ]] || return 1

  checkpoint_id=$(
    _entire_checkpoint_table_by_session "$1" |
      fzf --ansi \
        --header-lines=1 \
        --with-nth=2,3 \
        --delimiter=$'\t' \
        --prompt='entire checkpoint> ' \
        --height=~50% \
        --reverse \
        --preview='entire checkpoint explain {1} 2>/dev/null || true' \
        --preview-window="$_ENTIRE_PREVIEW_WINDOW" \
        --footer='Enter: explain selected checkpoint' |
      cut -f1
  ) || return

  [[ -n "$checkpoint_id" ]] || return 1
  print -r -- "$checkpoint_id"
}

_entire_open_agent() {
  local session_id="$1" agent="$2"
  case "$agent" in
    'Claude Code')
      command claude -r "$session_id"
      ;;
    'Codex')
      command codex resume "$session_id"
      ;;
    'Copilot CLI')
      command copilot --resume="$session_id"
      ;;
    *)
      print "No supported agent for: ${agent:-unknown}"
      ;;
  esac
}

_entire_session_action() {
  local line session_id agent checkpoint_id action

  line=$(_entire_session_fzf) || return
  [[ -n "$line" ]] || return

  session_id=$(cut -f1 <<< "$line")
  agent=$(cut -f3 <<< "$line" | xargs)
  action=$(_entire_action_pick | awk -F ':' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1}') || return

  case "$action" in
    resume)
      _entire_open_agent "$session_id" "$agent"
      ;;
    explain)
      checkpoint_id=$(_entire_latest_checkpoint_id_by_session "$session_id") || return
      command entire checkpoint explain "$checkpoint_id"
      ;;
    checkpoints)
      checkpoint_id=$(_entire_checkpoint_pick_by_session "$session_id") || return
      command entire checkpoint explain "$checkpoint_id"
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

etf() {
  _entire_session_action
}

etfd() {
  command entire dispatch --local
}

