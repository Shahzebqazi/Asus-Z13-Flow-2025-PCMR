### FreshStandard.json

Purpose: Fresh single-boot install with the standard Arch kernel.

- Profile file: `Configs/FreshStandard.json`
- Target user: New install on blank SSD; prefers standard kernel.

Key settings:
- Kernel: standard
- Filesystem: btrfs
- Desktop: omarchy
- Dual boot: none (single boot)
- Gaming: disabled
- Snapshots: enabled
- Secure Boot: enabled (systemd-boot + sbctl). For dual-boot, keep Secure Boot disabled.

Notes:
- Btrfs subvolumes are created for root, home, var, and snapshots.

