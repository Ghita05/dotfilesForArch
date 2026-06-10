#!/usr/bin/env bash
# Patch 10 band gains into the EasyEffects 8.x preset, then reload live.
# Usage: eq-apply.sh g0 g1 ... g9
PRESET="$HOME/.local/share/easyeffects/output/quickshell-eq.json"
[ -f "$PRESET" ] || exit 0

filter="."
i=0
for g in "$@"; do
    filter="$filter | .output.\"equalizer#0\".left.band${i}.gain=${g} | .output.\"equalizer#0\".right.band${i}.gain=${g}"
    i=$((i + 1))
done

tmp=$(mktemp)
if jq "$filter" "$PRESET" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
    mv "$tmp" "$PRESET"
    easyeffects -l quickshell-eq
else
    rm -f "$tmp"
fi