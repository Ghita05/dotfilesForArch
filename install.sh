#!/usr/bin/env bash
set -e
DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/.config"
CONFIG_DEST="$HOME/.config"

echo "==> Installing official packages..."
if command -v pacman >/dev/null; then
   sudo pacman -S -needed - < "$DOTFILES_DIR/packages.txt"
fi

if [ -f "$DOTFILES_DIR/packages-aur.txt" ] && command -v yay >/dev/null; then
    echo "==> Installing AUR packages..."
    yay -S --needed - < "$DOTFILES_DIR/packages-aur.txt"
fi

echo "==> Linking confings..."
mkdir -p "$CONFIG_DEST"
for dir in "$CONFIG_SRC"/*/; do
    name="$(basename "$dir")"
    target="$CONFIG_DEST/$name"
    if [ -e "$target" ] && [ !-L "$target" ]; then
       mv "$target" "$target.bak"
    fi
    ln -sfn "$dir" "$target"
    echo " linked $name"
done

mkdir -p "$HOME/.config/wallpapers"
cp -n "$DOTFILES_DIR"/wallpapers/* "$HOME/.config/wallpapers/" 2>/dev/null || true

echo ""
echo "!! ON REAL HARDWARE: comment out 'source = ~/.config/hypr/vm.conf'"
echo " in ~/.config/hypr/hyprland.conf (it forces VM software rendering)."
echo "==> Done." 
