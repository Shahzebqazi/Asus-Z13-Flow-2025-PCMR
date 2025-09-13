# User Guide — Arch Linux on ASUS ROG Flow Z13 (2025)

This guide is for Z13 Flow (2025) with AMD Ryzen Strix Halo. It focuses on the fastest, safest path with minimal choices.

## Current Stable Branch Configuration

The stable branch currently installs:
- **Zen kernel** - Performance-optimized kernel for gaming and responsiveness
- **ZFS filesystem** - Advanced filesystem with compression and snapshots
- **Dual-boot support** - Compatible with existing Windows installations
- **systemd-boot** - For fresh installs on new SSDs
- **GRUB** - For dual-boot configurations with Windows
- **omarchy desktop** - Lightweight, efficient desktop environment

## Quick Start (Recommended)

1) Boot the Arch ISO (UEFI). Connect to the internet.

2) Run the installer (stable branch):
```bash
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/stable/pcmr.sh | bash
```

- If you have a USB-C Ethernet dongle, keep it handy (in case Wi‑Fi is finicky on the installer).
- We’ll handle Secure Boot during install; you can leave it off for the USB boot to avoid surprises.

- Uses the Zen kernel and optimizations for the Z13.
- Desktop is enforced to `omarchy`.
- Secure Boot: enabled automatically only for fresh/Linux-only installs; auto-disabled for existing Windows dual-boot (uses GRUB).

## Optional: Single stable config

If you prefer an explicit config instead of defaults:

```bash
./pcmr.sh --config Configs/Zen.json
```

## Dual‑Boot Prep on Windows (Enhanced)

Before installing alongside Windows, prepare safely with the enhanced helper scripts:

```powershell
# Run in Windows PowerShell as Administrator
cd C:\path\to\repo\Windows

# 1) Check system health and space
PowerShell -ExecutionPolicy Bypass -File .\Preinstall-Check.ps1

# 2) Create Linux partitions from unallocated space
PowerShell -ExecutionPolicy Bypass -File .\Create-Partitions.ps1 -DiskNumber 0 -RootSizeGB 50 -SwapSizeGB 8

# 3) Ensure proper EFI System Partition size
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1 -MinEspMiB 260 -NewEspMiB 300
```

What the enhanced scripts do:
- Validate disk health and available space
- Create Linux partitions automatically from unallocated space
- Create restore points and optional system image backups
- Ensure properly sized EFI System Partition without touching the original ESP
- Provide comprehensive error recovery and rollback capabilities

Reference: Arch Wiki guidance on Windows ESP sizing.

## Steps (5–7 minutes of interaction)

1) Boot the Arch ISO (UEFI). Ensure internet connectivity.
2) Pick either Quick Start or the single config from above.
3) Choose install type when prompted: Fresh install or Dual‑boot with Windows.
4) The installer validates prerequisites and shows a summary. Press Enter to continue.
5) Enter passwords when prompted (root and your user).
6) Installation runs through modules automatically; progress is shown in a compact TUI.
7) On success, remove the USB and reboot.

## After Reboot

- Log in to your user account (zsh + Oh My Posh included).
- Connect Wi‑Fi if needed (NetworkManager UI, or `nmcli`).
- Update packages:
```bash
sudo pacman -Syu
```

### Power/TDP Profiles (Z13 Flow specific)
```bash
gaming       # AC: max performance (thermal limits apply)
performance  # AC: 85W balanced performance
balanced     # AC: 45W (recommended for most use)
efficient    # AC: 15W (maximize battery)

tdp-status   # Show power source, battery %, current TDP
tdp-list     # Show available profiles (built-in + custom)
tdp          # Manage profiles
```

## Troubleshooting

For all troubleshooting, see the consolidated guide:

- [Troubleshooting Guide](Troubleshooting%20Guide.md)

## Secure Boot Policy (summary)

- Fresh/Linux‑only installs: systemd‑boot + `sbctl` with key creation and signing.
- Existing Windows dual‑boot: GRUB UEFI with `os-prober`; Secure Boot disabled to preserve Windows boot.

## Extended Troubleshooting

See [Troubleshooting Guide](Troubleshooting%20Guide.md) for detailed commands and fixes.

## Advanced Configuration

The stable branch uses optimized defaults for the Z13 Flow 2025. Advanced configuration options are available on the development branch for users who need custom setups.

**Current Stable Defaults:**
- Zen kernel with AMD Strix Halo optimizations
- ZFS filesystem with compression and snapshots
- omarchy desktop environment
- Hardware-specific drivers and power management
- MediaTek MT7925e WiFi stability fixes

For custom configurations or advanced options, please open an issue to discuss your specific needs.


