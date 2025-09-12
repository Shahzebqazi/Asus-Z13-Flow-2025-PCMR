### FreshZen.json

Purpose: Fresh single-boot install with Zen kernel and full features.

- Profile file: `Configs/FreshZen.json`
- Target user: New install on blank SSD; wants best performance and Secure Boot.

Key settings:
- Kernel: zen
- Filesystem: zfs
- Desktop: omarchy
- Dual boot: none (single boot)
- Gaming: enabled
- Snapshots: enabled
- Secure Boot: enabled (systemd-boot + sbctl)

Notes:
- Requires UEFI mode and sufficient RAM for ZFS.
- Creates/enrolls Secure Boot keys and signs kernel/bootloader.

