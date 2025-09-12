### Windows: Create-Arch-USB.ps1 (Orchestrator)

Purpose: Orchestrate preinstall checks, ESP ensure, and optional Rufus USB creation.

Flow:
1) Runs `Preinstall-Check.ps1`
2) Runs `Ensure-ESP.ps1`
3) Optionally runs `Make-Arch-USB.ps1` when `-CreateUSB` is provided

Usage:
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1 -CreateUSB -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

