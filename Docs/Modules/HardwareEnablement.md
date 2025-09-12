### Module: HardwareEnablement (optional)

Purpose: Apply safe, device‑specific enablement for ASUS Flow Z13 (2025).

Stable actions:
- Install and enable `asusctl`, `supergfxctl` services
- Add `acpi_backlight=vendor` to GRUB/systemd‑boot entries
- Apply MT7925e stability option (`options mt7925e disable_aspm=1`)
- Ensure PipeWire userspace and enable user services globally

When to run:
- Post‑install if brightness keys, GPU mode switching, Wi‑Fi stability, or audio quirks appear

Re‑run:
```bash
sudo /bin/bash /path/to/repo/Modules/HardwareEnablement.sh
```

