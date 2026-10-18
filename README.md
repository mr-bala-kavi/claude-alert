# claude-alert

A Claude Code plugin that plays a sound when Claude needs you — so you don't miss it while working in another tab.

## When it plays

| Event | Windows | macOS | Linux |
|---|---|---|---|
| Claude asks a question (AskUserQuestion) | Windows Notify | Glass | message-new-instant |
| Permission prompt / waiting for input | Windows Exclamation | Ping | bell |

## Install

```
claude plugin marketplace add mr-bala-kavi/claude-alert
claude plugin install sound-alert@claude-alert
```

Restart Claude Code after installing.

## Custom sounds

Set an environment variable to the path of any sound file your platform supports:

- `CLAUDE_ALERT_QUESTION_WAV` — sound for questions
- `CLAUDE_ALERT_NOTIFY_WAV` — sound for permission/idle notifications

## Test

```
sh plugins/sound-alert/scripts/alert.sh question
```

## Disable

```
claude plugin disable sound-alert@claude-alert
```

## Requirements

- Windows: Git for Windows (Claude Code runs hooks through its `sh`)
- macOS: nothing extra (`afplay` is built in)
- Linux: `paplay` (PulseAudio/PipeWire) or `aplay` (ALSA)
