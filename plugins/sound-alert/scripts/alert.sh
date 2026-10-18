#!/bin/sh
# Cross-platform alert sound for Claude Code hook events.
# Usage: alert.sh <question|notify|stop>
#
# question/notify keep ringing until the user responds (a "stop" call from the
# PostToolUse / UserPromptSubmit / Stop hooks) or CLAUDE_ALERT_MAX_SECONDS passes.
#
# Env vars:
#   CLAUDE_ALERT_QUESTION_WAV / CLAUDE_ALERT_NOTIFY_WAV  custom sound files
#   CLAUDE_ALERT_MAX_SECONDS  max ringing time (default 30, 0 = play once)
#   CLAUDE_ALERT_GAP_SECONDS  pause between repeats (default 1)
kind="${1:-notify}"
dir="$(cd "$(dirname "$0")" && pwd)"
max="${CLAUDE_ALERT_MAX_SECONDS:-30}"
gap="${CLAUDE_ALERT_GAP_SECONDS:-1}"

# One marker file per session, so parallel sessions don't silence each other.
input="$(cat 2>/dev/null | tr -d '\r\n')"
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
marker="${TMPDIR:-/tmp}/claude-alert-${sid:-default}.ring"

if [ "$kind" = "stop" ]; then
  rm -f "$marker"
  exit 0
fi

if [ "$kind" = "question" ]; then custom="$CLAUDE_ALERT_QUESTION_WAV"; else custom="$CLAUDE_ALERT_NOTIFY_WAV"; fi

play() {
  case "$(uname -s)" in
    Darwin)
      if [ "$kind" = "question" ]; then def="/System/Library/Sounds/Glass.aiff"; else def="/System/Library/Sounds/Ping.aiff"; fi
      afplay "${custom:-$def}" >/dev/null 2>&1 || osascript -e 'beep' >/dev/null 2>&1
      ;;
    Linux)
      # WSL: Linux audio is often missing, so use the Windows player.
      if [ -z "$custom" ] && grep -qi microsoft /proc/version 2>/dev/null && command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "$dir/alert.ps1")" "$kind" >/dev/null 2>&1
        return
      fi
      if [ "$kind" = "question" ]; then def="/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"; else def="/usr/share/sounds/freedesktop/stereo/bell.oga"; fi
      snd="${custom:-$def}"
      { command -v pw-play >/dev/null 2>&1 && pw-play "$snd" >/dev/null 2>&1; } ||
      { command -v paplay  >/dev/null 2>&1 && paplay "$snd" >/dev/null 2>&1; } ||
      { command -v canberra-gtk-play >/dev/null 2>&1 && canberra-gtk-play -f "$snd" >/dev/null 2>&1; } ||
      { command -v aplay   >/dev/null 2>&1 && aplay -q "$snd" >/dev/null 2>&1; } ||
      { printf '\a' > /dev/tty; sleep 1; } 2>/dev/null
      ;;
    MINGW*|MSYS*|CYGWIN*)
      ps1="$dir/alert.ps1"
      command -v cygpath >/dev/null 2>&1 && ps1="$(cygpath -w "$ps1")"
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps1" "$kind" >/dev/null 2>&1
      ;;
    *)
      printf '\a' > /dev/tty 2>/dev/null
      ;;
  esac
}

# Already ringing for this session (e.g. AskUserQuestion also fires a
# permission_prompt notification) - keep the current alert going.
# A marker older than the max ring time is stale (its loop was killed).
if [ -s "$marker" ]; then
  since="$(cut -d- -f2 "$marker" 2>/dev/null)"
  [ $(( $(date +%s) - ${since:-0} )) -lt $(( max + 15 )) ] && exit 0
fi

# Claim the marker; "stop" removes it and this loop exits.
token="$$-$(date +%s)"
printf '%s' "$token" > "$marker"
start="$(date +%s)"

while :; do
  play
  [ "$max" -gt 0 ] 2>/dev/null || break
  sleep "$gap"
  [ "$(cat "$marker" 2>/dev/null)" = "$token" ] || exit 0
  [ $(( $(date +%s) - start )) -lt "$max" ] || break
done

[ "$(cat "$marker" 2>/dev/null)" = "$token" ] && rm -f "$marker"
exit 0
