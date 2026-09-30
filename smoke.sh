#!/usr/bin/env bash
# Prove an image can run arc and its separator: arc installed on top of the
# runtime, a measurement, and a real htdemucs separation of a short clip.
set -euo pipefail
/usr/local/share/arc-runtime/install.sh arc
arc version
ffmpeg -loglevel error -f lavfi -i "sine=frequency=220:duration=8" -ar 44100 -c:a pcm_f32le /tmp/tone.wav
arc tonal /tmp/tone.wav --sqlite /tmp/tone.db >/dev/null
test "$(sqlite3 /tmp/tone.db 'select count(*) from bands')" -gt 10
"$ARC_SEPARATOR_PYTHON" /opt/arc/arc-separate --in /tmp/tone.wav --out /tmp/sep | tee /tmp/sep.json
test -s /tmp/sep/voice.wav
echo "smoke: ok"
