# Arch Linux Installation for ASUS ROG Flow Z13

**One-command Arch Linux installation optimized for the ASUS ROG Flow Z13 with ZFS, Omarchy desktop, and all hardware fixes applied.**

---

## **Quick Install**

```bash
# Boot from Arch Linux USB and run:
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/main/Install.sh | bash
```

**That's it!** The script handles everything automatically.

---

## **What You Get**

### **✅ Working Hardware**
- **Wi-Fi** - Stable connection (MediaTek MT7925e fixed)
- **Touchpad** - Full functionality with touch support
- **Display** - No flickering, optimized for Z13
- **Audio** - Complete audio setup
- **Power Management** - AMD Strix Halo TDP control (45W-120W+)
- **Gaming** - Steam, Proton, GameMode ready

### **⚡ Performance Features**
- **ZFS File System** - Compression, snapshots, data integrity
- **Omarchy Desktop** - Tiling window manager (default)
- **Zen Kernel** - Desktop-optimized for low latency and gaming
- **Zsh Shell** - Modern shell with better autocompletion
- **Fast Boot** - 5-6 seconds to desktop
- **Dual-Boot** - Preserves Windows safely
- **Advanced Cooling** - Optimized for high TDP workloads

---

## **Before You Start**

### **⚠️ Important:**
1. **Backup Windows** - Create recovery media first
2. **Shrink Windows** - Free up 100GB+ for Linux
3. **Test Windows** - Verify it still boots after partitioning
4. **Keep Power Connected** - Never install on battery

### **What You Need:**
- Arch Linux USB (4GB+)
- Internet connection
- 100GB+ free disk space

---

## **Installation Options**

### **Desktop Environments:**
1. **Omarchy** - Tiling window manager (default)
2. **XFCE** - User-friendly traditional desktop
3. **i3** - Advanced tiling window manager
4. **GNOME** - Modern full desktop
5. **KDE Plasma** - Feature-rich desktop
6. **Minimal** - Command-line only

### **Additional Options:**
- **Gaming Setup** - Steam, Proton, GameMode
- **Power Management** - AMD Strix Halo TDP control (45W-120W+)
- **ZFS Snapshots** - Automatic system recovery
- **Hardware Fixes** - All Z13-specific optimizations
- **AUR Support** - yay helper for additional packages
- **Zen Kernel** - Low latency, desktop-optimized performance
- **Zsh Shell** - Modern shell with advanced features

---

## **Hardware Compatibility**

| Component | Status | Notes |
|-----------|--------|-------|
| **Wi-Fi** | ✅ Working | ASPM disabled for stability |
| **Touchpad** | ✅ Working | Full touch support |
| **Display** | ✅ Working | No flickering issues |
| **Audio** | ✅ Working | PulseAudio configured |
| **Power** | ✅ Working | AMD Strix Halo TDP (45W-120W+) |
| **Gaming** | ✅ Working | Steam + Proton ready |

---

## **Boot Times**

| Configuration | Boot Time |
|---------------|-----------|
| **Linux-only** | **5-6 seconds** |
| **Dual-boot** | **10-11 seconds** |
| **Windows 11** | 25-30 seconds |

---

## **Manual Installation**

If you prefer step-by-step control:

```bash
# Follow the complete guide
cat Docs/My_Instructions.md
```

---

## **Troubleshooting**

### **Common Issues:**
- **Wi-Fi unstable?** - Script fixes this automatically
- **Touchpad not working?** - Reboot after installation
- **Can't boot?** - Check BIOS UEFI settings
- **Need help?** - Check `Docs/My_Instructions.md`

### **Recovery:**
- **ZFS Snapshots** - Rollback system changes instantly
- **Windows Recovery** - Use your recovery media
- **Reinstall** - Script is safe to run multiple times

---

## **Project Info**

- **Version:** 1.0.0 (September 10, 2025)
- **OS:** Arch Linux (rolling release)
- **Kernel:** Zen kernel (desktop-optimized)
- **File System:** ZFS with compression
- **Desktop:** Omarchy tiling window manager
- **Testing:** 14/14 Python tests, 7/7 unit tests passing
- **Hardware:** ASUS ROG Flow Z13 (AMD Ryzen Strix Halo)
- **Quality:** Production-ready with comprehensive error handling

---

## **Support**

- **GitHub Issues:** Report bugs or request features
- **Level1Techs Forum:** Community discussion
- **Arch Wiki:** Linux documentation

---

**Ready to install?** Just run the command above and follow the prompts!

*This project builds on the excellent Level1Techs community work and adds modern improvements for the Z13.*