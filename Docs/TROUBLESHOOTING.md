# Z13 Troubleshooting Guide

**ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+**

This comprehensive troubleshooting guide covers common issues and their solutions for your Z13 installation.

## 🚨 Emergency Quick Reference

### Critical Issues - Immediate Actions
```bash
# System won't boot
z13-recovery emergency

# High temperature emergency
z13-tdp efficient
systemctl stop cpu-intensive-service

# Out of disk space
z13-backup-manager cleanup
z13-zfs-snapshot cleanup  # or z13-btrfs-snapshot cleanup

# Network completely down
z13-recovery network
systemctl restart NetworkManager

# System completely unresponsive
# Hard reset: Hold power button for 10 seconds
```

## 🔧 Installation Issues

### Issue: Script Fails During Installation
**Symptoms:** Installation stops with error messages, modules fail to load

**Diagnosis:**
```bash
# Check installation log
tail -f /tmp/pcmr-install.log

# Check system resources
df -h  # Disk space
free -h  # Memory
```

**Solutions:**
1. **Insufficient disk space:**
   ```bash
   # Free up space
   rm -rf /tmp/*
   pacman -Scc  # Clear package cache
   ```

2. **Network issues:**
   ```bash
   # Test connectivity
   ping -c 3 archlinux.org
   
   # Restart network
   systemctl restart NetworkManager
   ```

3. **Package conflicts:**
   ```bash
   # Update package database
   pacman -Syy
   
   # Force refresh
   pacman -Syyuu
   ```

### Issue: Configuration Parsing Errors
**Symptoms:** "Invalid JSON" errors, configuration not loading

**Diagnosis:**
```bash
# Validate JSON syntax
python3 -m json.tool Configs/Zen.conf
```

**Solutions:**
```bash
# Fix JSON syntax errors
# Common issues:
# - Missing commas
# - Trailing commas
# - Unquoted strings
# - Missing brackets

# Use default configuration
./pcmr.sh --standard
```

### Issue: Module Loading Failures
**Symptoms:** "Module not found" errors, missing functions

**Diagnosis:**
```bash
# Check module syntax
bash -n Modules/CoreInstallation.sh

# Check file permissions
ls -la Modules/
```

**Solutions:**
```bash
# Fix permissions
chmod +x Modules/*.sh

# Verify module completeness
git status  # Check for missing files
```

## 🖥️ Hardware-Specific Issues

### Issue: WiFi Instability (MediaTek MT7925e)
**Symptoms:** Frequent disconnections, slow speeds, driver errors

**Diagnosis:**
```bash
# Check WiFi status
ip link show
iwctl station wlan0 show

# Check driver logs
dmesg | grep mt7925
journalctl -u NetworkManager
```

**Solutions:**
1. **Apply stability fixes:**
   ```bash
   # Check if fix is applied
   cat /etc/modprobe.d/mt7925e.conf
   # Should contain: options mt7925e disable_aspm=1
   
   # If missing, add it:
   echo "options mt7925e disable_aspm=1" | sudo tee /etc/modprobe.d/mt7925e.conf
   
   # Reload driver
   sudo modprobe -r mt7925e
   sudo modprobe mt7925e
   ```

2. **Power management issues:**
   ```bash
   # Disable WiFi power saving
   sudo iwconfig wlan0 power off
   
   # Make permanent
   echo 'ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/usr/bin/iw dev $name set power_save off"' | sudo tee /etc/udev/rules.d/70-wifi-powersave.rules
   ```

### Issue: Display Issues (180Hz/VRR)
**Symptoms:** Screen flickering, wrong refresh rate, display corruption

**Diagnosis:**
```bash
# Check current display settings
xrandr --verbose
cat /sys/class/drm/card*/device/pp_features

# Check display driver
lspci -v | grep -A 10 "VGA\|Display"
```

**Solutions:**
1. **Force 180Hz mode:**
   ```bash
   # Test 180Hz manually
   xrandr --output eDP-1 --mode 1920x1200 --rate 180
   
   # Make permanent in X11
   echo 'Section "Monitor"
       Identifier "eDP-1"
       Modeline "1920x1200_180.00" 484.00 1920 2072 2280 2640 1200 1203 1213 1271 -hsync +vsync
       Option "PreferredMode" "1920x1200_180.00"
   EndSection' | sudo tee /etc/X11/xorg.conf.d/20-z13-display.conf
   ```

2. **VRR issues:**
   ```bash
   # Check VRR support
   cat /sys/class/drm/card0/device/pp_features | grep VRR
   
   # Enable VRR if supported
   echo "1" | sudo tee /sys/class/drm/card0/device/vrr_capable
   ```

### Issue: Audio Problems
**Symptoms:** No sound, crackling, microphone not working

**Diagnosis:**
```bash
# Check audio devices
aplay -l
arecord -l

# Check PulseAudio/PipeWire
pactl info
systemctl --user status pipewire
```

**Solutions:**
1. **Audio not working:**
   ```bash
   # Restart audio service
   systemctl --user restart pipewire pipewire-pulse
   
   # Check mixer levels
   alsamixer
   ```

2. **Microphone issues:**
   ```bash
   # Test microphone
   arecord -f cd -d 5 test.wav
   aplay test.wav
   
   # Check privacy settings
   # Some DEs have microphone privacy toggles
   ```

### Issue: Touchpad/Touchscreen Problems
**Symptoms:** Gestures not working, sensitivity issues, no touch input

**Diagnosis:**
```bash
# Check input devices
xinput list
libinput list-devices

# Check touchpad driver
dmesg | grep -i touchpad
```

**Solutions:**
1. **Touchpad configuration:**
   ```bash
   # Install touchpad configuration tool
   sudo pacman -S libinput-gestures

   # Configure gestures
   libinput-gestures-setup autostart
   libinput-gestures-setup start
   ```

2. **Touchscreen calibration:**
   ```bash
   # Install calibration tool
   sudo pacman -S xinput-calibrator
   
   # Run calibration
   xinput_calibrator
   ```

## ⚡ Performance Issues

### Issue: High CPU Usage/Temperature
**Symptoms:** System sluggish, fan noise, thermal throttling

**Diagnosis:**
```bash
# Check CPU usage
htop
z13-performance-monitor status

# Check temperature
sensors
z13-health-monitor check
```

**Solutions:**
1. **Immediate cooling:**
   ```bash
   # Switch to efficient mode
   z13-tdp efficient
   
   # Check running processes
   ps aux --sort=-%cpu | head -10
   
   # Kill CPU-intensive processes if needed
   kill -TERM <PID>
   ```

2. **Long-term optimization:**
   ```bash
   # Check CPU governor
   cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
   
   # Switch to powersave if needed
   echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   
   # Review startup services
   systemctl list-unit-files --state=enabled
   ```

### Issue: Memory Issues
**Symptoms:** System freezing, out of memory errors, high swap usage

**Diagnosis:**
```bash
# Check memory usage
free -h
z13-memory-monitor status

# Check memory-hungry processes
ps aux --sort=-%mem | head -10
```

**Solutions:**
1. **Free memory immediately:**
   ```bash
   # Drop caches
   sync
   echo 3 | sudo tee /proc/sys/vm/drop_caches
   
   # Kill memory-intensive processes
   kill -TERM <PID>
   ```

2. **Optimize memory usage:**
   ```bash
   # Adjust swappiness
   echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-z13-memory.conf
   
   # Enable zswap if available
   echo 1 | sudo tee /sys/module/zswap/parameters/enabled
   ```

### Issue: Disk Performance Problems
**Symptoms:** Slow file operations, high I/O wait, disk errors

**Diagnosis:**
```bash
# Check disk usage
df -h
iotop

# Check disk health
z13-health-monitor check
smartctl -a /dev/nvme0n1
```

**Solutions:**
1. **Free disk space:**
   ```bash
   # Clean package cache
   sudo pacman -Scc
   
   # Clean logs
   sudo journalctl --vacuum-time=7d
   
   # Clean temporary files
   sudo rm -rf /tmp/*
   sudo rm -rf /var/tmp/*
   ```

2. **Optimize I/O:**
   ```bash
   # Check I/O scheduler
   cat /sys/block/nvme0n1/queue/scheduler
   
   # Switch to appropriate scheduler
   echo none | sudo tee /sys/block/nvme0n1/queue/scheduler  # For NVMe
   ```

## 🔋 Power Management Issues

### Issue: Poor Battery Life
**Symptoms:** Battery drains quickly, system doesn't sleep properly

**Diagnosis:**
```bash
# Check power consumption
z13-power-manager status
powertop

# Check wake sources
cat /proc/acpi/wakeup
```

**Solutions:**
1. **Optimize power settings:**
   ```bash
   # Switch to efficient mode
   z13-tdp efficient
   
   # Enable power saving features
   powertop --auto-tune
   
   # Check TLP configuration
   sudo tlp-stat -b  # Battery info
   ```

2. **Fix sleep issues:**
   ```bash
   # Check systemd sleep settings
   cat /etc/systemd/sleep.conf
   
   # Test suspend
   systemctl suspend
   
   # Check for processes preventing sleep
   cat /sys/power/wake_lock
   ```

### Issue: TDP Management Not Working
**Symptoms:** TDP commands fail, power profiles don't change

**Diagnosis:**
```bash
# Check TDP service
systemctl status z13-dynamic-tdp.service
z13-tdp status

# Check ryzenadj
sudo ryzenadj --info
```

**Solutions:**
```bash
# Restart TDP service
sudo systemctl restart z13-dynamic-tdp.service

# Check permissions
ls -la /usr/local/bin/z13-tdp

# Manual TDP setting
sudo ryzenadj --stapm-limit=15000 --fast-limit=15000 --slow-limit=15000
```

## 🌐 Network Issues

### Issue: No Internet Connection
**Symptoms:** Can't browse, DNS failures, network unreachable

**Diagnosis:**
```bash
# Check network interface
ip link show
ip addr show

# Test connectivity
ping -c 3 8.8.8.8  # Test IP connectivity
ping -c 3 google.com  # Test DNS resolution
```

**Solutions:**
1. **Basic network troubleshooting:**
   ```bash
   # Restart NetworkManager
   sudo systemctl restart NetworkManager
   
   # Reset network interface
   sudo ip link set wlan0 down
   sudo ip link set wlan0 up
   ```

2. **DNS issues:**
   ```bash
   # Check DNS configuration
   cat /etc/resolv.conf
   
   # Use alternative DNS
   echo 'nameserver 8.8.8.8
   nameserver 8.8.4.4' | sudo tee /etc/resolv.conf
   ```

### Issue: VPN Problems
**Symptoms:** VPN won't connect, DNS leaks, slow VPN speeds

**Diagnosis:**
```bash
# Check VPN status
systemctl status openvpn@client
ip route show

# Test for DNS leaks
dig @8.8.8.8 myip.opendns.com
```

**Solutions:**
```bash
# Fix VPN DNS
echo 'script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf' | sudo tee -a /etc/openvpn/client.conf

# Install VPN helper scripts
sudo pacman -S openvpn-update-resolv-conf
```

## 🎮 Gaming Issues

### Issue: Poor Gaming Performance
**Symptoms:** Low FPS, stuttering, games crashing

**Diagnosis:**
```bash
# Check current TDP
z13-tdp status

# Check GPU usage
radeontop  # For AMD GPU
```

**Solutions:**
1. **Optimize for gaming:**
   ```bash
   # Switch to gaming mode
   z13-tdp gaming
   
   # Enable gamemode
   gamemoderun <game_command>
   
   # Check GPU clocks
   cat /sys/class/drm/card0/device/pp_dpm_sclk
   ```

2. **Steam-specific fixes:**
   ```bash
   # Enable Steam Play (Proton)
   # In Steam: Settings > Steam Play > Enable Steam Play for all titles
   
   # Install additional dependencies
   sudo pacman -S lib32-vulkan-radeon lib32-mesa
   ```

### Issue: Controller Not Working
**Symptoms:** Game controller not detected, wrong button mapping

**Diagnosis:**
```bash
# Check connected controllers
lsusb | grep -i controller
js-test /dev/input/js0  # Test joystick
```

**Solutions:**
```bash
# Install controller support
sudo pacman -S xpadneo  # Xbox controllers
sudo pacman -S ds4drv   # PlayStation controllers

# Test controller
evtest /dev/input/event*
```

## 🔐 Security Issues

### Issue: AppArmor/Firewall Problems
**Symptoms:** Applications blocked, network services inaccessible

**Diagnosis:**
```bash
# Check AppArmor status
sudo aa-status

# Check firewall rules
sudo ufw status verbose
```

**Solutions:**
```bash
# Temporarily disable AppArmor for troubleshooting
sudo aa-complain /usr/bin/firefox

# Allow application through firewall
sudo ufw allow <port>
sudo ufw allow from <ip_address>
```

### Issue: SSH Access Problems
**Symptoms:** Can't connect via SSH, authentication failures

**Diagnosis:**
```bash
# Check SSH service
systemctl status sshd

# Check SSH configuration
sudo sshd -T
```

**Solutions:**
```bash
# Enable SSH service
sudo systemctl enable --now sshd

# Check firewall
sudo ufw allow ssh

# Reset SSH keys if needed
ssh-keygen -R <hostname>
```

## 🔄 Recovery Scenarios

### Issue: System Won't Boot
**Symptoms:** Black screen, GRUB errors, kernel panic

**Solutions:**
1. **Boot from recovery media:**
   ```bash
   # Use Z13 recovery USB
   # Select "Emergency Recovery Mode"
   
   # Or boot from Arch ISO and chroot
   mount /dev/nvme0n1p2 /mnt
   arch-chroot /mnt
   ```

2. **Repair bootloader:**
   ```bash
   z13-recovery bootloader
   
   # Or manually:
   grub-install --target=x86_64-efi --efi-directory=/boot/efi
   grub-mkconfig -o /boot/grub/grub.cfg
   ```

### Issue: Filesystem Corruption
**Symptoms:** File system errors, read-only filesystem, data corruption

**Solutions:**
1. **Check and repair filesystem:**
   ```bash
   z13-recovery filesystem
   
   # Or manually for ext4:
   fsck -f /dev/nvme0n1p2
   
   # For ZFS:
   zpool scrub zroot
   zpool status -v
   ```

2. **Restore from snapshot:**
   ```bash
   z13-recovery-manager
   # Select option 5: Restore from snapshot
   ```

## 📊 Monitoring and Diagnostics

### Comprehensive System Check
```bash
# Run complete system health check
z13-health-monitor check

# Generate system report
z13-monitoring-status

# Check all logs
z13-recovery logs
```

### Performance Analysis
```bash
# Generate performance report
z13-performance-monitor analyze

# Check resource usage
z13-performance-monitor status

# Hardware diagnostics
z13-recovery hardware
```

## 🆘 Getting Help

### Log Files to Check
```bash
# Installation logs
/tmp/pcmr-install.log
/var/log/z13-*.log

# System logs
journalctl -xe
dmesg | tail -50

# Application logs
~/.local/share/xorg/Xorg.0.log  # Display issues
~/.config/pulse/pulse.log        # Audio issues
```

### Information to Gather
```bash
# System information
uname -a
lscpu
lspci
lsusb
free -h
df -h

# Z13-specific information
z13-recovery hardware
z13-health-monitor status
z13-tdp status
```

### Community Resources
- **GitHub Issues**: Report bugs and get help
- **Level1Techs Forum**: AMD Strix Halo discussions  
- **Arch Linux Wiki**: Official documentation
- **ASUS ROG Community**: Hardware-specific tips

## 🔧 Advanced Troubleshooting

### Creating Debug Information
```bash
# Create comprehensive debug report
mkdir -p /tmp/z13-debug
cp /var/log/z13-*.log /tmp/z13-debug/
journalctl --since "24 hours ago" > /tmp/z13-debug/journal.log
dmesg > /tmp/z13-debug/dmesg.log
lshw > /tmp/z13-debug/hardware.log
z13-health-monitor status > /tmp/z13-debug/health.log
tar -czf z13-debug-$(date +%Y%m%d-%H%M%S).tar.gz -C /tmp z13-debug/
```

### Safe Mode Boot
```bash
# Add to GRUB kernel parameters:
# systemd.unit=rescue.target
# or
# single

# This boots to minimal system for troubleshooting
```

Remember: When in doubt, use the Z13 Recovery Manager (`z13-recovery-manager`) for guided troubleshooting and recovery options.
