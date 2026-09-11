#!/usr/bin/env bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/.config"
CONFIG_DEST="$HOME/.config"

echo "==> Installing official packages..."
if command -v pacman >/dev/null; then
   sudo pacman -S --needed $(cat "$DOTFILES_DIR/packages.txt")
fi

if [ -f "$DOTFILES_DIR/packages-aur.txt" ] && command -v yay >/dev/null; then
    echo "==> Installing AUR packages..."
    yay -S --needed $(cat "$DOTFILES_DIR/packages-aur.txt")
fi

echo "==> Linking confings..."
mkdir -p "$CONFIG_DEST"
for dir in "$CONFIG_SRC"/*/; do
    name="$(basename "$dir")"
    # ambxst: only config/ is tracked (binds.json, presets/, etc. are
    # per-machine state, not dotfiles) — linked as a subdirectory below
    # instead of the whole directory.
    if [ "$name" = "ambxst" ]; then
        continue
    fi
    target="$CONFIG_DEST/$name"
    if [ -e "$target" ] && [ !-L "$target" ]; then
       mv "$target" "$target.bak"
    fi
    ln -sfn "$dir" "$target"
    echo " linked $name"
done

mkdir -p "$CONFIG_DEST/ambxst"
if [ -e "$CONFIG_DEST/ambxst/config" ] && [ ! -L "$CONFIG_DEST/ambxst/config" ]; then
    mv "$CONFIG_DEST/ambxst/config" "$CONFIG_DEST/ambxst/config.bak"
fi
ln -sfn "$CONFIG_SRC/ambxst/config" "$CONFIG_DEST/ambxst/config"
echo " linked ambxst/config (binds.json, presets/ etc. left as machine-local state)"

mkdir -p "$HOME/.config/wallpapers"
cp -n "$DOTFILES_DIR"/wallpapers/* "$HOME/.config/wallpapers/" 2>/dev/null || true

echo ""
echo "!! ON REAL HARDWARE: comment out 'source = ~/.config/hypr/vm.conf'"
echo " in ~/.config/hypr/hyprland.conf (it forces VM software rendering)."
echo "==> Done." 
