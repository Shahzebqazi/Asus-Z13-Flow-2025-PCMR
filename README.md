# PCMR Arch Installer for ASUS ROG Flow Z13 (2025)
**AMD Ryzen Strix Halo**

Transform your ASUS ROG Flow Z13 into the ultimate portable Linux powerhouse. Get a fully optimized Arch Linux system with Zen kernel, gaming support, power management, and hardware-specific fixes in under 30 minutes.

## 🚀 **Quick Start**

Choose your installation path:

### **Option 1: Dual Boot from Windows** 🪟➕🐧
*Keep your existing Windows installation*

**Step 1 - Prepare Windows (Run as Administrator):**
```powershell
# Download and run in Windows PowerShell
cd C:\path\to\repo\Windows
PowerShell -ExecutionPolicy Bypass -File .\Preinstall-Check.ps1
PowerShell -ExecutionPolicy Bypass -File .\Create-Partitions.ps1 -DiskNumber 0 -RootSizeGB 50 -SwapSizeGB 8
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1 -MinEspMiB 260 -NewEspMiB 300
```

**Step 2 - Install Arch Linux:**
```bash
# Boot from Arch Linux USB and run:
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/stable/pcmr.sh | bash
```

### **Option 2: Fresh Install on New SSD** 🆕💾
*Clean installation on blank drive*

```bash
# Boot from Arch Linux USB and run:
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/stable/pcmr.sh | bash
```

## ⚡ **What You Get**

- 🔥 **AMD Strix Halo Optimized**: Hardware-specific drivers and optimizations
- 🎮 **Gaming Ready**: Steam, Proton, controller support out of the box
- 🔋 **Smart Power Management**: 7W tablet mode to 120W gaming mode
- 🌐 **Rock-Solid WiFi**: MediaTek MT7925e stability fixes
- 🐚 **Modern Shell**: Zsh with Oh My Posh and beautiful themes
- 📸 **ZFS Snapshots**: Automatic system snapshots for easy recovery
- 🛡️ **Enhanced Reliability**: Comprehensive error handling and recovery

## 🔧 **Installation Details**

**Current Stable Configuration:**
- **Kernel**: Zen kernel (optimized for performance)
- **Filesystem**: ZFS with compression and snapshots
- **Desktop**: omarchy (lightweight and efficient)
- **Boot**: systemd-boot (fresh install) or GRUB (dual-boot)
- **Security**: Secure Boot enabled for fresh installs, disabled for dual-boot compatibility

## 📚 **Documentation**

- **[User Guide](User%20Guide.md)** - Complete installation walkthrough and post-install setup
- **[Troubleshooting Guide](Troubleshooting%20Guide.md)** - Solutions for common issues and hardware-specific problems

## 🤝 **Community & Support**

- **GitHub Issues**: Report bugs or ask questions
- **Level1Techs Forum**: AMD Strix Halo discussion
- **Arch Linux Wiki**: Official documentation and troubleshooting

## 📚 **References**

- [Level1Techs Z13 Linux Guide](https://forum.level1techs.com/t/flow-z13-asus-setup-on-linux-may-2025-wip/229551)
- [Wendell's Ultimate Arch Guide](https://forum.level1techs.com/t/the-ultimate-arch-secureboot-guide-for-ryzen-ai-max-ft-hp-g1a-128gb-8060s-monster-laptop/230652)
- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Dual Boot with Windows - EFI System Partition](https://wiki.archlinux.org/title/Dual_boot_with_Windows#The_EFI_system_partition_created_by_Windows_Setup_is_too_small)

---

**Ready to install?** Choose your path above and get started! 🚀