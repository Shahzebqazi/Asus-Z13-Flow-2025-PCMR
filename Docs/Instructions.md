# Arch Linux Installation Reference for ASUS ROG Flow Z13

## ⚠️ **DEPRECATED - USE My_Instructions.md INSTEAD**

This file contains the **original installation instructions** from the Level1Techs community research. It serves as a **historical reference** but contains **outdated configurations**.

### **Why This File is Deprecated:**
- **Outdated File System:** Uses Btrfs instead of modern ZFS
- **Missing Hardware Fixes:** Lacks critical Z13-specific fixes
- **No Power Management:** Missing asusctl and TLP configuration
- **Desktop Environment:** References i3 instead of user-friendly XFCE

### **For Current Installation:**
**Use:** `Docs/My_Instructions.md` - Complete, tested, and up-to-date guide

### **For Automated Installation:**
**Use:** `../my_arch_install.sh` - Handles all hardware fixes automatically

---

## **Original Level1Techs Community Research**

*This section preserves the original community work for reference purposes.*

### **Hardware Specifications Covered:**
- ASUS ROG Flow Z13 (2022-2025 models)
- AMD Ryzen 9 7940HS processor
- AMD Radeon 780M integrated graphics
- MediaTek MT7925e Wi-Fi chip
- 13.4" touchscreen display

### **Known Issues Addressed in Updated Guides:**
1. **Wi-Fi Instability** - MediaTek MT7925e ASPM issues
2. **Touchpad Detection** - hid_asus module problems
3. **Display Flickering** - Intel PSR conflicts
4. **Power Management** - Missing TDP control (7W-54W)
5. **File System** - Btrfs vs ZFS performance and reliability

### **References:**
- [Flow Z13 Asus Setup on Linux (May 2025) [WIP]](https://forum.level1techs.com/t/flow-z13-asus-setup-on-linux-may-2025-wip/229551)
- [YouTube: Linux Installation Experience](https://www.youtube.com/watch?v=spxuikqgUpw)
- [The Ultimate Arch + Secureboot Guide for Ryzen AI Max](https://forum.level1techs.com/t/the-ultimate-arch-secureboot-guide-for-ryzen-ai-max-ft-hp-g1a-128gb-8060s-monster-laptop/230652)

---

**For actual installation, please use the current guides that include all bug fixes and hardware optimizations.**