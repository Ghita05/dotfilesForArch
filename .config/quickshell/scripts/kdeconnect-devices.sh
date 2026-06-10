#!/usr/bin/env bash
# JSON array of paired KDE Connect devices: name, reachability, LAN IP. Via D-Bus.
DEST=org.kde.kdeconnect

getprop() {
    gdbus call --session --dest "$DEST" \
        --object-path "$1" \
        --method org.freedesktop.DBus.Properties.Get \
        "$2" "$3" 2>/dev/null
}

clean() {
    sed -E "s/^\(<//; s/>,?\)$//; s/^'//; s/'$//"
}

first=1
printf '['
for id in $(kdeconnect-cli -l --id-only 2>/dev/null); do
    base="/modules/kdeconnect/devices/$id"
    name=$(getprop "$base" org.kde.kdeconnect.device name | clean)
    [ -z "$name" ] && name="$id"
    reach=$(getprop "$base" org.kde.kdeconnect.device isReachable | clean)
    [ "$reach" = true ] && online=true || online=false
    ip=$(getprop "$base" org.kde.kdeconnect.device reachableAddresses \
         | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    [ "$first" -eq 0 ] && printf ','
    first=0
    printf '{"id":"%s","name":"%s","reachable":%s,"ip":"%s"}' \
        "$id" "$name" "$online" "$ip"
done
printf ']'