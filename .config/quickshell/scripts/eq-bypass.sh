#!/usr/bin/env bash
# Usage: eq-bypass.sh true|false
PRESET="$HOME/.local/share/easyeffects/output/quickshell-eq.json"
[ -f "$PRESET" ] || exit 0
tmp=$(mktemp)
if jq ".output.\"equalizer#0\".bypass=${1}" "$PRESET" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    mv "$tmp" "$PRESET"
    easyeffects -l quickshell-eq
else
    rm -f "$tmp"
fi