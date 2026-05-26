#!/usr/bin/env bash
# Cycle through power-profiles-daemon profiles
current=$(powerprofilesctl get)
case "$current" in
    power-saver) next="balanced" ;;
    balanced)    next="performance" ;;
    performance) next="power-saver" ;;
    *)           next="balanced" ;;
esac
powerprofilesctl set "$next"
notify-send "Power profile" "Switched to $next" -t 2000