### Module: DiskManagement

Purpose: Select install type, choose target disk, and prepare/mount partitions.

Stable behavior:
- Fresh install (`new`): wipes disk, creates ESP (300 MiB), root, and optional swap
- Dual‑boot (`gpt`): detects existing ESP, preserves it, prompts for Linux root and optional swap
- Always formats only root/swap; ESP is formatted only for fresh installs

Key variables produced:
- `EFI_PART`, `ROOT_PART`, `SWAP_PART`, `DISK_DEVICE`, `DUAL_BOOT_MODE`

Entry points:
- `DiskManagement_setup` (primary)
- `disk_management_setup` (lowercase alias)

Notes:
- Requires UEFI/GPT. For dual‑boot, prepare Windows first using `Docs/Windows/Ensure-ESP.md` and scripts under `Windows/`.

