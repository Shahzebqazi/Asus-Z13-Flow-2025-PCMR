### Module: Bootloader

Purpose: Install and configure the bootloader according to dual‑boot policy.

Stable policy:
- Existing Windows (`DUAL_BOOT_MODE=gpt`): install GRUB (UEFI), enable `os-prober`, generate config
- Fresh/Linux‑only: install systemd‑boot and generate a minimal loader entry using `PARTUUID`
- Secure Boot: disabled for dual‑boot; fresh installs boot unsigned kernels in stable

Outputs:
- GRUB: `/boot/grub/grub.cfg`
- systemd‑boot: `/boot/loader/loader.conf`, `/boot/loader/entries/*.conf`

