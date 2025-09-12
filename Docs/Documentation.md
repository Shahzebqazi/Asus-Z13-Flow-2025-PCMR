# Z13 Flow Arch Installer Documentation

## User Stories
- As a Z13 owner, I want a reliable, unattended install that preserves Windows when dual-booting.
- As a power user, I want a resume-capable installer that can recover from failures.
- As a gamer, I want optional gaming packages installed via AUR after user creation.
- As an admin, I want clear logs and modular architecture to customize.

## Technical Requirements
- UEFI-only, GPT partitioning, NVMe disks supported.
- Filesystems: Prefer ZFS if available; fallback to btrfs then ext4.
- Bootloader: GRUB UEFI with os-prober enabled for Windows.
- Device guard: AMD Ryzen Strix Halo only.
- TUI: compact 10-line terminal UI; falls back to echo.
- AUR: install yay post user creation; AUR packages only after yay exists.
- Resume: phases persisted; re-runs skip completed phases.

## Specifications
- Entry: `pcmr.sh` orchestrates phases via `run_phase(name, func)`.
- Modules: `Modules/*.sh` provide idempotent functions.
- Configs: `Configs/*.conf` JSON parsed by `pcmr.sh`.
- State files: host `/tmp/pcmr-installer.state`; target `/mnt/var/lib/pcmr-installer/state`.
- Trap: `trap CleanupOnFailure ERR`; success path unmounts and exits.
- Chroot rule: Only run simple commands in `arch-chroot`. All custom helpers run in parent shell with `... chroot` flags.

## Architecture
- Phases:
  - disk → fs → base → bootloader → syscfg → hardening → performance → monitoring → backup
- Cross-cutting concerns:
  - Logging: TUI `add_log_message` with fallback to echo
  - Error handling: fatal/recoverable/validation helpers
  - Package ops: `InstallPackageWithVerification`, `InstallPackageGroupWithVerification`, `InstallAurPackageWithVerification`

## Compatibility Matrix
- Device: ASUS ROG Flow Z13 (2025), AMD Ryzen Strix Halo (required)
- Boot: UEFI only
- Disks: NVMe and standard SATA detected via lsblk TYPE==disk

## Dual-Boot Policy
- If `--dual-boot-gpt`: preserve existing EFI and Windows partitions; install GRUB with os-prober.
- If `--dual-boot-new`/single: format EFI as FAT32 after partitioning and mount at `/mnt/boot`.

## AUR & Gaming
- `yay` installed as target user; AUR installs gated by `INSTALL_GAMING`.
- Heavy gaming packages installed only when enabled.

## Security Notes
- Consider enabling Secure Boot in a future iteration (sbctl shim). Current ISO requires Secure Boot disabled.

## Future Work
- Optional Secure Boot integration
- Deeper asusctl/supergfxctl tuning when upstream supports Strix Halo fully
