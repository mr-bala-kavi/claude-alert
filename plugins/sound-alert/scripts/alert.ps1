# Plays an alert sound for Claude Code hook events.
# Usage: alert.ps1 <question|notify>
# Override sounds with env vars CLAUDE_ALERT_QUESTION_WAV / CLAUDE_ALERT_NOTIFY_WAV.
param([string]$Kind = "notify")

$media = Join-Path $env:WINDIR "Media"
switch ($Kind) {
    "question" { $wav = $env:CLAUDE_ALERT_QUESTION_WAV; if (-not $wav) { $wav = Join-Path $media "Windows Notify System Generic.wav" } }
    default    { $wav = $env:CLAUDE_ALERT_NOTIFY_WAV;   if (-not $wav) { $wav = Join-Path $media "Windows Exclamation.wav" } }
}

try {
    if (Test-Path $wav) {
        (New-Object System.Media.SoundPlayer $wav).PlaySync()
    } else {
        [System.Media.SystemSounds]::Exclamation.Play()
        Start-Sleep -Milliseconds 800
    }
} catch {
    [console]::beep(880, 300)
}
exit 0
