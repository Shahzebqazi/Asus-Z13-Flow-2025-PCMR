# Project Prompt and Mental Map

Purpose: Provide agents and contributors the minimal context to work safely on this repo.

## Branch Policy
- main: docs-only; user-first. Quick Start must reference stable raw script.
- stable: runnable installer with minimal modules (Disk, FS, Base, Boot) + optional HardwareEnablement; Zen kernel; omarchy-only desktop.
- development: full engineering work, CI, advanced modules, experiments.

## Installer Facts (stable)
- Entry: `pcmr.sh` (bash).
- Core modules loaded: `DiskManagement`, `FilesystemSetup`, `CoreInstallation`, `Bootloader`.
- Optional module: `HardwareEnablement` (asusctl/supergfxctl, MT7925e ASPM fix, backlight param, PipeWire).
- Configs: single stable config `Configs/Zen.json`. Desktop forced to `omarchy`.
- Dual-boot policy: existing Windows → GRUB; fresh/Linux-only → systemd-boot; Secure Boot disabled for dual-boot.

## Docs Canonical Sources
- README.md: overview and Quick Start only; links to guides.
- Docs/User Guide.md: canonical install flow (stable references only).
- Docs/Troubleshooting Guide.md: canonical troubleshooting (main).

## Style & Constraints
- Only offer omarchy as desktop choice.
- Keep stable minimal and safe; no custom kernels. Prefer fallbacks to ext4.
- Use single config on stable; avoid config matrix.

## Tasks To Prefer
- Improve Z13 enablement safely (asusctl, WiFi, audio, brightness) in HardwareEnablement.
- Keep README and User Guide aligned with stable behavior.
- When adding modules, start in development; backport safe subsets to stable.

## Quick Pointers
- Windows prep helper: `Windows/Create-Arch-USB.ps1` (ESP creation via bcdboot; no ESP moves).
- HWE toggles via `ENABLE_HARDWARE_FIXES` in config parsing.
