### Windows: Ensure-ESP.ps1

Purpose: Safely ensure a sufficiently sized ESP without moving the original one.

Policy:
- Never move/shrink the original ESP
- Shrink C: minimally, create a new ESP at disk end, and populate via `bcdboot`
- Leave the old ESP intact as fallback

Usage:
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1 -MinEspMiB 260 -NewEspMiB 300 -ShrinkOsMiB 512
```

