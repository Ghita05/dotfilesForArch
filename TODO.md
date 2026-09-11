# TODO

- VM popup control (was `~/.config/quickshell/modules/bar/VmPopup.qml`, bound
  to Super+O): parked during the Ambxst migration, no Ambxst equivalent exists.
  `~/.config/quickshell` stays on disk so the QML isn't lost. Investigate later
  whether `ambxst mods` is the right mechanism to port it in as a custom
  addition. Not scoped or started.

- Hibernate: still parked, but smaller than assumed — this machine already has
  a swap LV at `/dev/vg0/swap` (8G, confirmed via `lsblk`). Still needs a
  `resume=` kernel parameter and the `resume` mkinitcpio hook on top of the
  LUKS+LVM layout, but the swap device itself doesn't need to be created.
  Not scoped or started.

- `install.sh` line 22 has a pre-existing bug: `[ !-L "$target" ]` is missing a
  space (should be `[ ! -L "$target" ]`). Not touched, not urgent, but the
  condition likely isn't doing what it looks like it does.

- Replace the `hl.unbind()` workaround in `hyprland.lua`'s workspace-bind
  section with a source-level fix in `~/.config/ambxst/binds.json` — that file
  is what axctl actually reads to generate the numeric workspace binds in
  `~/.local/share/ambxst/hyprland.lua`. Disabling/remapping them at the source
  would be more robust than unbinding them downstream every reload. Found
  during the ambxst-config gitignore review, not scoped or started.
