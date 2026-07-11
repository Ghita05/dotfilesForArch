#!/usr/bin/env bash
dev="asus::kbd_backlight"
max=$(brightnessctl -d "$dev" max)
cur=$(brightnessctl -d "$dev" get)
brightnessctl -d "$dev" set "$(( (cur + 1) % (max + 1) ))"
