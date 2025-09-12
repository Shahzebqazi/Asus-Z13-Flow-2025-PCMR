### Windows: Make-Arch-USB.ps1

Purpose: Launch Rufus to create the Arch USB installer from an ISO.

Notes:
- Rufus CLI varies; this script preselects the ISO and elevates Rufus
- Complete the creation in the Rufus GUI

Usage:
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Make-Arch-USB.ps1 -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

