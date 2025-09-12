### DualBootZen.json

Purpose: Dual-boot with existing Windows using the Zen kernel.

- Profile file: `Configs/DualBootZen.json`
- Target user: Keep Windows; add Arch with Zen kernel.

Key settings:
- Kernel: zen
- Filesystem: btrfs
- Desktop: omarchy
- Dual boot: gpt (detects Windows EFI and preserves it)
- Gaming: enabled
- Snapshots: enabled
- Secure Boot: disabled (uses GRUB to preserve Windows boot)

Notes:
- Requires EFI System Partition >= 100MB.
- os-prober is enabled for Windows entry (if GRUB fallback is used).

