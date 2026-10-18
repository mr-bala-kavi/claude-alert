#!/bin/sh
# Cross-platform alert sound for Claude Code hook events.
# Usage: alert.sh <question|notify>
# Override sounds with env vars CLAUDE_ALERT_QUESTION_WAV / CLAUDE_ALERT_NOTIFY_WAV
# (any file the platform player supports: .aiff/.wav on macOS, .wav/.oga on Linux).
kind="${1:-notify}"
dir="$(cd "$(dirname "$0")" && pwd)"

if [ "$kind" = "question" ]; then custom="$CLAUDE_ALERT_QUESTION_WAV"; else custom="$CLAUDE_ALERT_NOTIFY_WAV"; fi

case "$(uname -s)" in
  Darwin)
    if [ "$kind" = "question" ]; then def="/System/Library/Sounds/Glass.aiff"; else def="/System/Library/Sounds/Ping.aiff"; fi
    afplay "${custom:-$def}" >/dev/null 2>&1 || osascript -e 'beep' >/dev/null 2>&1
    ;;
  Linux)
    if [ "$kind" = "question" ]; then def="/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"; else def="/usr/share/sounds/freedesktop/stereo/bell.oga"; fi
    snd="${custom:-$def}"
    { command -v paplay >/dev/null 2>&1 && paplay "$snd" >/dev/null 2>&1; } ||
    { command -v aplay  >/dev/null 2>&1 && aplay -q "$snd" >/dev/null 2>&1; } ||
    printf '\a' > /dev/tty 2>/dev/null
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
exit 0
