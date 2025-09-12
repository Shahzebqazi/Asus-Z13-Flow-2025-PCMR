# User Guide — Arch Linux on ASUS ROG Flow Z13 (2025)

This guide is for Z13 Flow (2025) with AMD Ryzen Strix Halo. It focuses on the fastest, safest path with minimal choices. Developer/agent details live in `Docs/Prompt.md`.

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

## Dual‑Boot Prep on Windows (Recommended)

Before installing alongside Windows, prepare safely with the helper script:

```powershell
# Run in Windows PowerShell as Administrator
cd C:\path\to\repo\Windows
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1 -BackupTargetDriveLetter E: -MinEspMiB 260 -NewEspMiB 300
```

What it does:
- Creates a restore point (and optional system image backup)
- Ensures a properly sized EFI System Partition without touching the original ESP

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

- `Docs/Troubleshooting Guide.md`

## Secure Boot Policy (summary)

- Fresh/Linux‑only installs: systemd‑boot + `sbctl` with key creation and signing.
- Existing Windows dual‑boot: GRUB UEFI with `os-prober`; Secure Boot disabled to preserve Windows boot.

For developer notes, see `Docs/Prompt.md`.

## Extended Troubleshooting

See `Docs/Troubleshooting Guide.md` for detailed commands and fixes.

## Advanced Configuration (essentials)

- Use a JSON profile to preconfigure install:
```bash
cp Configs/Zen.json Configs/MyCustom.json
# edit MyCustom.json, then
./pcmr.sh --config Configs/MyCustom.json
```

- Example toggles inside JSON:
```json
{
  "installation": {
    "dual_boot_mode": "gpt",
    "kernel_variant": "zen",
    "default_filesystem": "zfs",
    "enable_secure_boot": false
  },
  "power": {
    "enable_power_management": true,
    "default_tdp_profile": "balanced"
  },
  "hardware": {
    "enable_hardware_fixes": true,
    "enable_180hz_display": true
  }
}
```

- Custom TDP profiles (concept): define named AC/battery targets and switch via `z13-tdp <name>`.

For deep dives (kernel params, module tuning, services, advanced security), see the project’s developer docs (`Docs/Prompt.md` for agents) or open an issue to request coverage in the user guide.


