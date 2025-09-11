# PCMR Arch Linux Installation for ASUS ROG Flow Z13 (2025)

**Modular Arch Linux installation optimized for the ASUS ROG Flow Z13 with AMD Strix Halo AI Max+, featuring configurable TDP, Steam gaming support, and comprehensive hardware optimization.**

---

## **Quick Install**

```bash
# Boot from Arch Linux USB and run:
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/main/pcmr.sh | bash

# Or with configuration:
./pcmr.sh --config configs/pcmr-standard.conf
```

**That's it!** The modular script handles everything automatically.

---

## **What You Get**

### **✅ Working Hardware**
- **Wi-Fi** - Stable connection (MediaTek MT7925e fixed)
- **Touchpad** - Full functionality with touch support
- **Display** - No flickering, optimized for Z13
- **Audio** - Complete audio setup with PulseAudio
- **Power Management** - AMD Strix Halo TDP control (7W-120W+)
- **Gaming** - Steam, Proton, GameMode, controller support
- **Controllers** - PS4/5, Xbox One/S support (Bluetooth + wired)

### **⚡ Performance Features**
- **ZFS File System** - Compression, snapshots, data integrity
- **Configurable TDP** - 7W (efficient) to 120W+ (gaming)
- **Optimized Fan Curves** - Silent, balanced, and gaming profiles
- **Unified Memory** - 48GB VRAM allocation for AI workloads
- **Steam Gaming** - Complete gaming ecosystem
- **Power Profiles** - Efficient, AI, and Gaming modes
- **Dual-Boot** - Preserves Windows safely

---

## **Configuration Options**

### **Available Configurations:**
- **`configs/pcmr-standard.conf`** - Standard Z13 Flow configuration (ZFS, XFCE)
- **`configs/zen.conf`** - Performance-optimized with Zen kernel
- **`configs/basic.conf`** - Stability-focused with standard kernel
- **`configs/level1techs.conf`** - Level1Techs-inspired configuration

### **Command Line Options:**
```bash
./pcmr.sh --help                    # Show help
./pcmr.sh --config configs/zen.conf # Use specific configuration
./pcmr.sh --standard                # Standard installation (ignore config)
./pcmr.sh --dual-boot-gpt           # Modern GPT UEFI dual boot
./pcmr.sh --dual-boot-new           # Fresh dual boot installation
./pcmr.sh --zen-kernel              # Use zen kernel instead of standard
```

---

## **Power Management**

### **TDP Profiles:**
- **Efficient (7W)** - Maximum battery life, silent operation
- **AI (70W)** - Balanced performance with 48GB VRAM allocation
- **Gaming (120W+)** - Maximum performance for gaming
- **Custom (7-120W)** - User-configurable TDP range

### **Fan Profiles:**
- **Efficient** - Silent operation, fans off until 60°C
- **AI** - Balanced cooling with moderate noise
- **Gaming** - Optimized cooling without max noise

---

## **Gaming Features**

### **Steam Integration:**
- **Steam** with native runtime and optimizations
- **Proton** for Windows game compatibility
- **GameMode** for performance optimization
- **MangoHud** for performance monitoring
- **Additional Libraries** - DXVK, VKD3D, Proton-GE, etc.

### **Controller Support:**
- **PlayStation 4/5** - Full Bluetooth and wired support
- **Xbox One/One S** - Full Bluetooth and wired support
- **Automatic Recognition** - udev rules for instant detection
- **Pairing Scripts** - Step-by-step controller setup

---

## **Before You Start**

### **⚠️ Important:**
1. **Backup Windows** - Create recovery media first
2. **Shrink Windows** - Free up 100GB+ for Linux
3. **Test Windows** - Verify it still boots after partitioning
4. **Keep Power Connected** - Never install on battery
5. **EFI Partition Size** - Ensure at least 100MB for dual boot

### **What You Need:**
- Arch Linux USB (4GB+)
- Internet connection
- 100GB+ free disk space
- UEFI boot mode

---

## **Hardware Compatibility**

| Component | Status | Notes |
|-----------|--------|-------|
| **Wi-Fi** | ✅ Working | MediaTek MT7925e with stability fixes |
| **Touchpad** | ✅ Working | Full touch support with libinput |
| **Display** | ✅ Working | AMD Strix Halo optimized |
| **Audio** | ✅ Working | PulseAudio + PipeWire |
| **Power** | ✅ Working | TDP control (7W-120W+) |
| **Gaming** | ✅ Working | Steam + Proton + controllers |
| **AI Workloads** | ✅ Working | 48GB VRAM allocation |

---

## **Desktop Environments**

### **Supported:**
1. **XFCE** - User-friendly traditional desktop (default)
2. **Omarchy** - Tiling window manager
3. **i3** - Advanced tiling window manager
4. **GNOME** - Modern full desktop
5. **KDE Plasma** - Feature-rich desktop
6. **Minimal** - Command-line only

---

## **File Systems**

### **Supported:**
- **ZFS** - Advanced features, snapshots, compression (default)
- **Btrfs** - Modern features, snapshots (fallback)
- **ext4** - Stable, compatible (fallback)

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
- **EFI partition too small?** - Resize to at least 100MB
- **Need help?** - Check `Docs/My_Instructions.md`

### **Recovery:**
- **ZFS Snapshots** - Rollback system changes instantly
- **Windows Recovery** - Use your recovery media
- **Reinstall** - Script is safe to run multiple times

---

## **Project Info**

- **Version:** 2.0.0 (September 11, 2025)
- **OS:** Arch Linux (rolling release)
- **Kernel:** Standard or Zen (configurable)
- **File System:** ZFS, Btrfs, or ext4 (configurable)
- **Desktop:** XFCE (default), others available
- **Testing:** 9/9 tests passing
- **Hardware:** ASUS ROG Flow Z13 (AMD Strix Halo AI Max+)
- **Quality:** Production-ready with comprehensive error handling

---

## **Support**

- **GitHub Issues:** Report bugs or request features
- **Level1Techs Forum:** Community discussion
- **Arch Wiki:** Linux documentation

---

**Ready to install?** Choose your configuration and run the command above!

*This project builds on the excellent Level1Techs community work and adds modern improvements for the Z13 with modular architecture and comprehensive gaming support.*