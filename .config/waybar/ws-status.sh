#!/bin/sh
# Live workspace pills for waybar — event-driven, with broken-pipe guard.
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
COLOR_IDLE="#6a6f7c"
COLOR_ACTIVE="
#e0e4ec"
# Exit cleanly if waybar closes (broken pipe = SIGPIPE)
trap 'exit 0' PIPE TERM
emit() {
    WS_LIST=$(hyprctl workspaces -j 2>/dev/null | jq -r '.[].id' | sort -n)
    ACTIVE=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
    PILLS=""
    for WS in $WS_LIST; do
        if [ "$WS" = "$ACTIVE" ]; then
            PILLS="${PILLS}<span foreground='${COLOR_ACTIVE}' weight='bold'>  ${WS}  </span>"
        else
            PILLS="${PILLS}<span foreground='${COLOR_IDLE}'>  ${WS}  </span>"
        fi
    done
    printf '{"text":"%s"}\n' "$PILLS" 2>/dev/null || exit 0
}
emit
socat -U - "UNIX-CONNECT:$SOCKET" 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        workspace*|createworkspace*|destroyworkspace*|focusedmon*|movewindow*|openwindow*|closewindow*)
            emit
            ;;
    esac
done