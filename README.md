# PCMR Arch Linux Installation Script
**ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+**

Transform your ASUS ROG Flow Z13 into the ultimate portable Linux powerhouse with this comprehensive installation script. Get a fully optimized Arch Linux system with modern zsh shell, gaming support, power management, and hardware-specific fixes in under 30 minutes.

> **Note**: While the installation scripts use bash (Arch Linux's default), your installed system will have zsh with Oh My Posh for the ultimate terminal experience!

## 🎯 **Why This Script?**

The ASUS ROG Flow Z13 (2025) with AMD Strix Halo is an incredible machine, but getting Linux to work perfectly requires specific hardware fixes, power optimizations, and driver configurations. This script automates everything based on community knowledge from Level1Techs, Arch Wiki, and real Z13 owners.

### **What You Get**
- ⚡ **Blazing Performance**: 7W tablet mode to 120W+ gaming mode with dynamic TDP
- 🎮 **Gaming Ready**: Steam, Proton, controller support out of the box  
- 🔋 **Smart Power Management**: 12+ hours battery life in efficient mode
- 🐚 **Modern Shell**: Zsh with Oh My Posh and beautiful Zen theme
- 🔤 **Nerd Fonts**: JetBrains Mono with icons and symbols
- 🌐 **Rock-Solid WiFi**: MediaTek MT7925e stability fixes included
- 👆 **Perfect Touch**: Touchpad and touchscreen work flawlessly
- 🔊 **Crystal Audio**: All speakers and microphones configured
- 🖥️ **Dual Boot**: Keep Windows - perfect dual boot setup
- 📸 **Snapshots**: Automatic system snapshots for easy recovery

### **Built on Community Knowledge**
This script combines wisdom from:
- **Level1Techs Community**: Wendell's AMD Strix Halo guide (adapted for Z13 hardware)
- **Arch Linux Community**: Best practices and hardware support  
- **Z13 Flow Owners**: Real-world fixes and optimizations specific to ASUS hardware
- **Gaming Community**: Steam Deck/ROG Ally optimization techniques
- **ASUS ROG Community**: Z13-specific drivers and power management

## 🚀 **Quick Start**

### **Automated Installation (Recommended)**
```bash
# Boot from Arch Linux USB and run:
curl -L https://github.com/Shahzebqazi/Asus-Z13-Flow-2025-PCMR/raw/main/pcmr.sh | bash
```

### **Using Configuration Files**
```bash
# Download and run with Level1Techs config
./pcmr.sh --config Configs/level1techs.conf

# Run with Zen kernel optimization
./pcmr.sh --zen-kernel --config Configs/zen.conf

# Dual-boot with existing Windows
./pcmr.sh --dual-boot-gpt --zen-kernel
```


## 📋 **Installation Options**

### **🚀 One-Command Install (Recommended)**
Perfect for most users - uses optimal settings for Z13:
```bash
./pcmr.sh --zen-kernel
```

### **⚙️ Customized Install**
Choose your setup with pre-configured profiles:
```bash
# Performance gaming setup (Wendell's L1T config)
./pcmr.sh --config Configs/level1techs.conf

# Maximum performance (Zen kernel + gaming)
./pcmr.sh --config Configs/zen.conf --zen-kernel

# Minimal desktop setup
./pcmr.sh --config Configs/quick-start.conf

# Dual-boot with existing Windows
./pcmr.sh --dual-boot-gpt --zen-kernel
```

### **🎛️ Manual Configuration**
Want full control? Use standard mode and answer prompts:
```bash
./pcmr.sh --standard
```

## 💡 **Which Option Should I Choose?**

| I Want... | Use This Command |
|-----------|------------------|
| **Gaming powerhouse** | `./pcmr.sh --config Configs/zen.conf` |
| **Work laptop** | `./pcmr.sh --config Configs/level1techs.conf` |
| **Keep Windows** | `./pcmr.sh --dual-boot-gpt --zen-kernel` |
| **Fast minimal setup** | `./pcmr.sh --config Configs/quick-start.conf` |
| **Full control** | `./pcmr.sh --standard` |

## 🚨 **Critical Safety Features**

### **Pre-Installation Validation**
- ✅ **Root access verification**
- ✅ **Internet connectivity check**  
- ✅ **UEFI mode validation** (required for Z13)
- ✅ **Disk space verification**
- ✅ **Existing OS detection**

### **Installation Safety**
- 🔒 **Windows preservation** in dual-boot mode
- 📸 **ZFS snapshots** before each module
- 🔄 **Automatic rollback** on failure
- 🛡️ **Graceful error handling**
- 🧹 **Complete cleanup** on abort

## ⚡ **What Makes Your Z13 Special**

Your ASUS ROG Flow Z13 (2025) isn't just another laptop - it's a technological marvel that needs special care to reach its full potential on Linux:

### **🔥 AMD Strix Halo Power Management**
- **7W Tablet Mode**: 8-12 hours battery for basic tasks (varies by usage)
- **45W Balanced**: Good for work and development (4-6 hours battery)
- **85W Performance**: Higher performance with thermal limitations (2-3 hours battery)
- **120W Maximum**: Short bursts only due to cooling constraints (45-90 minutes)

### **🎮 Gaming Capabilities**
- **Handheld Gaming**: Decent performance for light-medium games (thermal constraints apply)
- **Controller Support**: Standard Linux controller support for common gamepads
- **Steam Integration**: Steam and Proton work but with thermal limitations
- **Performance Reality**: Gaming performance varies significantly due to thermal design

### **📊 **Real-World Performance Expectations**

| Use Case | Power Mode | Battery Life | Performance |
|----------|------------|--------------|-------------|
| **Reading/Web** | 7W Efficient | 8-12 hours | Excellent |
| **Work/Code** | 45W Balanced | 4-6 hours | Very Good |
| **Light Gaming** | 85W Performance | 1.5-2.5 hours | Good |
| **Intensive Gaming** | 120W Maximum | 45-90 minutes | Limited by thermals |

*Note: Battery life varies significantly based on display brightness, background apps, and actual workload. Gaming performance is limited by thermal constraints in tablet form factor.*

### **🛠️ Z13 Flow-Specific Optimizations**

This script includes hardware-specific optimizations that differentiate it from generic Strix Halo guides:

**🔧 Z13 Flow Hardware Optimizations**
- **MediaTek MT7922 WiFi**: Z13-specific stability fixes and power management (uses mt7921e driver)
- **ASUS ROG Controls**: Limited `asusctl` support for basic functions (fan control, power profiles)
- **180Hz Display**: Native refresh rate configuration (VRR support varies by kernel)
- **Audio Array**: Basic speaker configuration for Z13's setup
- **External Monitor Intelligence**: Smart lid-close behavior when external displays connected  
- **Tablet Mode Detection**: Basic convertible form factor support (limited in some DEs)
- **USB-C Power Delivery**: Optimized charging behavior

**⚡ Advanced TDP Management System**
- **System-Wide Dynamic TDP**: Automatic adjustment based on power source and battery level
- **Custom Profile Creation**: Create and manage your own TDP profiles with `z13-tdp`
- **AC Power Profiles**: 15W-120W range with user-selectable profiles
- **Smart Battery TDP**: Dynamic 7W-25W scaling based on battery percentage
- **Real-Time Adaptation**: System monitors and adjusts every 30 seconds
- **Battery Care**: 40-80% charging limits for longevity

### **🐚 Modern Terminal Experience**

Your Z13 comes with a beautiful, modern shell setup:

**🎨 Oh My Posh with Zen Theme**
- Beautiful prompt with git status, directory info, and system stats
- Color-coded elements that match your Z13's aesthetic
- Real-time performance indicators

**⚡ Optimized Zsh Configuration**
- Smart command completion and history
- Z13-specific aliases for power management
- Git workflow shortcuts for development

**🔤 JetBrains Mono Nerd Font**
- Crystal-clear coding font with programming ligatures  
- Full icon support for modern terminal applications
- Perfect for both coding and system administration

**🚀 Ready-to-Use TDP & Power Aliases**
```bash
# Dynamic TDP Management (Z13 Flow specific!)
gaming       # AC: 120W, Battery: Dynamic (thermal limits apply)
performance  # AC: 85W,  Battery: Dynamic (sustainable performance)
balanced     # AC: 45W,  Battery: Dynamic (recommended for most use)
efficient    # AC: 15W,  Battery: Dynamic (maximum battery life)

# TDP Utilities
tdp-status   # Show current power source, battery %, and TDP
tdp-list     # List all available profiles (built-in + custom)
tdp          # Main TDP management command

# Development shortcuts
gs          # git status
ll          # detailed file listing
update      # system update with pacman
```

**🔋 System-Wide Dynamic TDP Features**
- **Automatic Battery Adjustment**: TDP dynamically scales 7W-25W based on battery level
- **AC Power Profiles**: Choose your preferred AC performance level
- **Custom Profile Creation**: Create your own TDP profiles with `z13-tdp create`
- **Real-Time Monitoring**: System adjusts TDP every 30 seconds automatically

## 🔍 **Troubleshooting**

### **Common Issues**

**TUI not displaying properly:**
```bash
# Check terminal compatibility
echo $TERM
# Run without TUI
./pcmr.sh --standard --no-tui
```

**Module dependency errors:**
```bash
# Check module status
grep "MODULE_STATUS" /tmp/installation.log
# Verify dependencies
./Modules/core_installation.sh --check-deps
```

**WiFi instability on Z13:**
```bash
# Check MediaTek driver config
cat /etc/modprobe.d/mt7925e.conf
# Should contain: options mt7925e disable_aspm=1
```

**Oh My Posh not displaying correctly:**
```bash
# Check if Oh My Posh is installed
which oh-my-posh

# Verify Nerd Font is installed
fc-list | grep -i jetbrains

# Test theme manually
oh-my-posh init zsh --config ~/.config/oh-my-posh/zen.omp.json
```

**Zsh not default shell:**
```bash
# Check current shell
echo $SHELL

# Change to zsh if needed
chsh -s /bin/zsh
```

**External monitor lid-close not working:**
```bash
# Check if external monitor detection is working
/usr/local/bin/z13-monitor-setup.sh

# Manually check connected displays
xrandr --query | grep " connected"

# Check lid switch configuration
cat /etc/systemd/logind.conf.d/z13-lid.conf
```

**180Hz display not working:**
```bash
# Check available display modes
xrandr --verbose

# Test 180Hz mode manually
xrandr --output eDP-1 --mode 1920x1200 --rate 180

# Verify VRR support
cat /sys/class/drm/card*/device/pp_features
```

**TDP management not working:**
```bash
# Check if dynamic TDP service is running
systemctl status z13-dynamic-tdp.service

# Check current TDP status
z13-tdp status

# View TDP change log
tail -f /var/log/z13-tdp.log

# Manually test ryzenadj
sudo ryzenadj --info

# Restart TDP service
sudo systemctl restart z13-dynamic-tdp.service
```

**Custom TDP profiles not saving:**
```bash
# Check profile directory permissions
ls -la /etc/z13/

# Manually create profile
sudo z13-tdp create test_profile 60 15 "Test profile"

# List all profiles
z13-tdp list
```

## 🤝 **Community & Support**

### **Get Help**
- **GitHub Issues**: Report bugs or ask questions
- **Level1Techs Forum**: Join the AMD Strix Halo discussion
- **Arch Linux Wiki**: Official documentation and troubleshooting
- **ASUS ROG Community**: Hardware-specific tips and tricks

### **Share Your Experience**
- Post your setup on r/unixporn or r/archlinux
- Share performance benchmarks with the community
- Help others troubleshoot their Z13 installations
- Contribute hardware fixes and optimizations

## 📚 **References**

- [Level1Techs Z13 Linux Guide](https://forum.level1techs.com/t/flow-z13-asus-setup-on-linux-may-2025-wip/229551)
- [Wendell's Ultimate Arch Guide](https://forum.level1techs.com/t/the-ultimate-arch-secureboot-guide-for-ryzen-ai-max-ft-hp-g1a-128gb-8060s-monster-laptop/230652)
- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Dual Boot with Windows - EFI System Partition](https://wiki.archlinux.org/title/Dual_boot_with_Windows#The_EFI_system_partition_created_by_Windows_Setup_is_too_small)
- [ZFS on Linux](https://openzfs.github.io/openzfs-docs/)

---

**Ready to install?** Boot from Arch USB and run: `./pcmr.sh --zen-kernel`

**Want to contribute?** This project uses modern software engineering principles to create a maintainable, scalable installation system. Join us in making Arch Linux installation as smooth as possible for the Z13 Flow!