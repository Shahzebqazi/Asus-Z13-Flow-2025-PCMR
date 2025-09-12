### DualBootStandard.json

Purpose: Dual-boot with existing Windows using the standard kernel.

- Profile file: `Configs/DualBootStandard.json`
- Target user: Keep Windows; add Arch with the standard kernel.

Key settings:
- Kernel: standard
- Filesystem: btrfs
- Desktop: omarchy
- Dual boot: gpt (detects Windows EFI and preserves it)
- Gaming: disabled
- Snapshots: enabled
- Secure Boot: enabled (systemd-boot + sbctl)

Notes:
- Ensure Windows is fully shut down (no Fast Startup) before shrinking partitions.

