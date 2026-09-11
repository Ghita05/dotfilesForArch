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
