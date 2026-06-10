#!/usr/bin/env bash
# Print current EQ state as JSON: {"enabled":true,"gains":[..10..]}
PRESET="$HOME/.local/share/easyeffects/output/quickshell-eq.json"
[ -f "$PRESET" ] || { echo '{"enabled":true,"gains":[0,0,0,0,0,0,0,0,0,0]}'; exit 0; }
jq -c '{
  enabled: (.output."equalizer#0".bypass | not),
  gains: [ .output."equalizer#0".left | .band0,.band1,.band2,.band3,.band4,.band5,.band6,.band7,.band8,.band9 | .gain ]
}' "$PRESET" 2>/dev/null || echo '{"enabled":true,"gains":[0,0,0,0,0,0,0,0,0,0]}'