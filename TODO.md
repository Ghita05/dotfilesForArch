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

- ~~Replace the `hl.unbind()` workaround with a source-level fix in
  `~/.config/ambxst/binds.json`~~ — **done 2026-09-11**, as part of the full
  AZERTY physical-position remap (47 keys changed in `binds.json`: numeric
  workspace binds now use the AZERTY symbol row instead of digits, plus
  A↔Q/Z↔W/COMMA→SEMICOLON/PERIOD→COLON). `hyprland.lua`'s OVERRIDES no longer
  needs any workspace-bind unbinding at all — the old fragile block was
  deleted, not just superseded. `binds.json` stays untracked in dotfiles (live
  per-machine state, same as before), so this fix doesn't show up as a
  dotfiles diff — it's live-only.
