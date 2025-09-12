### Windows: Preinstall-Check.ps1

Purpose: Non-destructive preflight before creating the Arch USB or modifying partitions.

Checks:
- Administrator rights
- UEFI/GPT on OS disk
- BitLocker status on C: (recommend suspend before ESP changes)
- Pending reboot and Fast Startup state
- ESP presence/size (warns if < 260 MiB)

Usage:
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Preinstall-Check.ps1
```

