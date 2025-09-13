# User Guide — Arch Linux on ASUS ROG Flow Z13 (2025)

This guide is for Z13 Flow (2025) with AMD Ryzen Strix Halo. It focuses on the fastest, safest path with minimal choices. Developer/agent details live in `Docs/Prompt.md`.

## Quick Start (Recommended)

1) Boot the Arch ISO (UEFI). Connect to the internet.

2) Run the installer (stable branch):
```bash
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/stable/Install_Arch.sh | bash
```

- Uses the Zen kernel and optimizations for the Z13.
- Desktop is enforced to `omarchy`.
- Secure Boot: signing deferred on stable; fresh uses systemd-boot unsigned; dual-boot disables Secure Boot and uses GRUB.

## Choose a Profile (optional)

Stable uses a single config. If you prefer running with an explicit profile:

```bash
./Install_Arch.sh --config Configs/Zen.json
```

## Dual‑Boot Prep on Windows (Recommended)

Before installing alongside Windows, prepare safely with the helper script:

```powershell
# Run in Windows PowerShell as Administrator
cd C:\path\to\repo\Windows
PowerShell -ExecutionPolicy Bypass -File .\Preflight-Checklist.ps1
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1 -MinEspMiB 260 -NewEspMiB 300 -ShrinkOsMiB 512
PowerShell -ExecutionPolicy Bypass -File .\Make-Arch-USB.ps1 -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\me\Downloads\archlinux.iso
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

Module docs:
- Disk management: `Docs/Modules/DiskManagement.md`
- Filesystem setup: `Docs/Modules/FilesystemSetup.md`
- Core installation: `Docs/Modules/CoreInstallation.md`
- Bootloader: `Docs/Modules/Bootloader.md`
- Hardware enablement: `Docs/Modules/HardwareEnablement.md`

## After Reboot

- Log in to your user account (zsh + Oh My Posh included).
- Connect Wi‑Fi if needed (NetworkManager UI, or `nmcli`).
- Update packages:
```bash
sudo pacman -Syu
```

### Optional hardware enablement
If brightness keys, GPU modes, or audio quirks appear, you can (re)apply the optional hardware module after install:
```bash
sudo /bin/bash /path/to/repo/Modules/HardwareEnablement.sh
```

## Troubleshooting (short)

- See the canonical guide: `Docs/Troubleshooting Guide.md`
- Dual‑boot: Windows missing in GRUB menu:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Secure Boot Policy (summary)

- Fresh/Linux‑only installs: systemd‑boot, unsigned on stable (signing deferred).
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
xrandr --output eDP-1 --mode 2560x1600 --rate 180
```

### Audio not working
```bash
systemctl --user restart pipewire pipewire-pulse
alsamixer
```

For deeper fixes (Wi‑Fi ASPM, backlight vendor mode, PipeWire, GPU modes), use `Docs/Troubleshooting Guide.md`. For developer/agent notes, see `Docs/Prompt.md`.


