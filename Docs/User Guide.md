# User Guide — Arch Linux on ASUS ROG Flow Z13 (2025)

This guide is for Z13 Flow (2025) with AMD Ryzen Strix Halo. It focuses on the fastest, safest path with minimal choices. Developer/agent details live in `Docs/Prompt.md`.

## Quick Start (Recommended)

1) Boot the Arch ISO (UEFI). Connect to the internet.

2) Run the installer (stable branch):
```bash
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/stable/pcmr.sh | bash
```

- Uses the Zen kernel and optimizations for the Z13.
- Desktop is enforced to `omarchy`.
- Secure Boot: enabled automatically only for fresh/Linux-only installs; auto-disabled for existing Windows dual-boot (uses GRUB).

## Choose a Profile (one option)

If you prefer explicit configs instead of defaults, pick one profile and run it. Do not mix flags.

```bash
# Fresh SSD, Zen kernel (recommended default)
./pcmr.sh --config Configs/FreshZen.json

# Zen kernel preset (general)
./pcmr.sh --config Configs/Zen.json
```

Learn more: `Docs/Configs/FreshZen.md`.

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
2) Pick either Quick Start or a single config profile from above.
3) The installer validates prerequisites and shows a summary. Press Enter to continue.
4) Enter passwords when prompted (root and your user).
5) Installation runs through modules automatically; progress is shown in a compact TUI.
6) On success, remove the USB and reboot.

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

## Troubleshooting (short)

- TUI not displaying properly:
```bash
./pcmr.sh --standard --no-tui
```

- Wi‑Fi unstable (MediaTek MT7925e):
```bash
cat /etc/modprobe.d/mt7925e.conf
# Expect: options mt7925e disable_aspm=1
```

- TDP service:
```bash
systemctl status z13-dynamic-tdp.service
sudo systemctl restart z13-dynamic-tdp.service
```

- Dual‑boot: Windows missing in menu (GRUB):
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

More issues? See the extended sections below.

## Secure Boot Policy (summary)

- Fresh/Linux‑only installs: systemd‑boot + `sbctl` with key creation and signing.
- Existing Windows dual‑boot: GRUB UEFI with `os-prober`; Secure Boot disabled to preserve Windows boot.

For developer notes, see `Docs/Prompt.md`.

## Extended Troubleshooting

### Installation stops or errors mid-run
```bash
# Tail the live installer log
tail -f /tmp/pcmr-install.log

# Check disk and memory
df -h
free -h
```
Common fixes:
- Update package metadata: `pacman -Syyu`
- Clear pacman cache: `pacman -Scc`
- Restart network: `systemctl restart NetworkManager`

### Wi‑Fi instability (MT7925e)
```bash
cat /etc/modprobe.d/mt7925e.conf
echo "options mt7925e disable_aspm=1" | sudo tee /etc/modprobe.d/mt7925e.conf
sudo modprobe -r mt7925e && sudo modprobe mt7925e
```

### Display refresh/VRR
```bash
xrandr --verbose
xrandr --output eDP-1 --mode 1920x1200 --rate 180
```

### Audio not working
```bash
systemctl --user restart pipewire pipewire-pulse
alsamixer
```

### Battery life/sleep
```bash
z13-tdp efficient
powertop --auto-tune
sudo tlp-stat -b
```

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


