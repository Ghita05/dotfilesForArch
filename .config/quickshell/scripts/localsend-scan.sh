#!/usr/bin/env bash
# Scans for LocalSend instances, emits JSON: [{"name":"..","ip":".."}, ...]
# Parses lines like: Name: iPad, Version: 2.1, Address: 192.168.1.142:53317, Protocol: https
BIN="$HOME/go/bin/localsend-cli"

first=1
printf '['
"$BIN" scan 2>/dev/null | grep 'Name:' | while IFS= read -r line; do
    name=$(printf '%s' "$line" | sed -nE 's/.*Name: ([^,]*),.*/\1/p')
    ip=$(printf '%s' "$line"   | sed -nE 's/.*Address: ([0-9.]+):.*/\1/p')
    [ -z "$ip" ] && continue
    [ -z "$name" ] && name="$ip"
    [ $first -eq 0 ] && printf ','
    first=0
    printf '{"name":"%s","ip":"%s"}' "$name" "$ip"
done
printf ']'