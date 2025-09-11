# Z13 Advanced Configuration Guide

**ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+ Advanced System Configuration**

This guide covers advanced configuration topics for power users who want to customize their Z13 installation beyond the default settings.

## 🔧 Custom Configuration Files

### Creating Custom Installation Profiles

The Z13 installation system supports JSON-based configuration files that allow you to pre-configure every aspect of your installation.

#### Configuration File Structure

```json
{
  "metadata": {
    "name": "Custom Z13 Configuration",
    "description": "Your custom description here",
    "author": "Your Name",
    "version": "1.0.0",
    "created": "2025-01-01",
    "target_hardware": "ASUS ROG Flow Z13 (2025)"
  },
  "system": {
    "default_username": "your_username",
    "default_hostname": "your-z13",
    "default_timezone": "Your/Timezone",
    "locale": "en_US.UTF-8",
    "keymap": "us",
    "additional_locales": ["en_GB.UTF-8", "es_ES.UTF-8"]
  },
  "installation": {
    "dual_boot_mode": "none",
    "kernel_variant": "zen",
    "default_filesystem": "zfs",
    "default_desktop": "kde",
    "enable_gaming": true,
    "enable_snapshots": true,
    "enable_secure_boot": false,
    "enable_suspend_resume": true,
    "enable_hibernate": true,
    "partition_scheme": "auto",
    "encryption": {
      "enable_full_disk_encryption": false,
      "encryption_method": "luks2",
      "key_derivation": "argon2id"
    }
  },
  "power": {
    "enable_power_management": true,
    "enable_tlp": true,
    "enable_asusctl": true,
    "default_tdp_profile": "balanced",
    "tdp_profiles": {
      "efficient": 7,
      "balanced": 45,
      "performance": 85,
      "gaming": 93,
      "maximum": 120
    },
    "battery_care": {
      "enable_battery_care": true,
      "start_charge_threshold": 40,
      "stop_charge_threshold": 80
    },
    "thermal_management": {
      "enable_thermal_throttling": true,
      "thermal_threshold": 85,
      "fan_curve": "balanced"
    }
  },
  "hardware": {
    "enable_hardware_fixes": true,
    "enable_wifi_stability_fixes": true,
    "enable_audio_firmware": true,
    "enable_touchpad_fixes": true,
    "enable_180hz_display": true,
    "enable_variable_refresh_rate": true,
    "gpu_configuration": {
      "vram_allocation": "auto",
      "performance_mode": "auto",
      "power_profile": "balanced"
    },
    "audio_configuration": {
      "enable_pipewire": true,
      "enable_low_latency": false,
      "sample_rate": 48000,
      "buffer_size": 1024
    }
  },
  "networking": {
    "enable_networkmanager": true,
    "enable_wifi": true,
    "enable_bluetooth": true,
    "wifi_powersave": false,
    "dns_servers": ["8.8.8.8", "8.8.4.4"],
    "vpn_support": {
      "enable_openvpn": false,
      "enable_wireguard": false
    }
  },
  "security": {
    "enable_security_hardening": true,
    "enable_apparmor": true,
    "enable_firewall": true,
    "enable_intrusion_detection": true,
    "enable_file_integrity": true,
    "enable_kernel_hardening": true,
    "enable_ssh_hardening": true,
    "firewall_profile": "desktop",
    "ssh_configuration": {
      "enable_ssh_server": false,
      "disable_root_login": true,
      "disable_password_auth": true,
      "custom_port": 22
    }
  },
  "performance": {
    "enable_performance_optimization": true,
    "cpu_optimization": true,
    "memory_optimization": true,
    "io_optimization": true,
    "gpu_optimization": true,
    "gaming_optimization": true,
    "thermal_optimization": true,
    "performance_profiles": ["gaming", "productivity", "battery"]
  },
  "monitoring": {
    "enable_system_monitoring": true,
    "enable_health_checks": true,
    "enable_performance_monitoring": true,
    "enable_hardware_monitoring": true,
    "enable_alerting": true,
    "monitoring_interval": 300,
    "log_retention_days": 30
  },
  "backup": {
    "enable_backup_recovery": true,
    "enable_automatic_snapshots": true,
    "enable_scheduled_backups": true,
    "backup_schedule": "daily",
    "snapshot_retention": 10,
    "backup_retention_days": 30,
    "backup_destinations": {
      "local": "/var/backups/z13",
      "remote": {
        "enabled": false,
        "host": "",
        "user": "",
        "path": ""
      }
    }
  },
  "applications": {
    "development_tools": {
      "enable": false,
      "packages": ["code", "git", "docker", "nodejs", "python"]
    },
    "media_tools": {
      "enable": false,
      "packages": ["gimp", "blender", "obs-studio", "vlc"]
    },
    "office_suite": {
      "enable": false,
      "suite": "libreoffice"
    },
    "gaming_tools": {
      "enable": true,
      "packages": ["steam", "lutris", "gamemode", "mangohud"]
    }
  },
  "customization": {
    "theme": {
      "gtk_theme": "Adwaita-dark",
      "icon_theme": "Adwaita",
      "cursor_theme": "Adwaita"
    },
    "fonts": {
      "system_font": "Noto Sans",
      "monospace_font": "JetBrains Mono Nerd Font",
      "document_font": "Noto Serif"
    },
    "shell": {
      "default_shell": "zsh",
      "enable_oh_my_posh": true,
      "theme": "zen"
    }
  }
}
```

#### Using Custom Configurations

```bash
# Create your custom configuration
cp Configs/Zen.conf Configs/MyCustom.conf
# Edit MyCustom.conf with your preferences

# Use custom configuration
./pcmr.sh --config Configs/MyCustom.conf

# Validate configuration before installation
python3 -m json.tool Configs/MyCustom.conf
```

### Advanced Configuration Options

#### Filesystem Configuration

```json
{
  "filesystem": {
    "type": "zfs",
    "options": {
      "compression": "zstd",
      "atime": "off",
      "xattr": "sa",
      "dnodesize": "auto",
      "encryption": {
        "enabled": false,
        "algorithm": "aes-256-gcm",
        "keyformat": "passphrase"
      },
      "datasets": {
        "root": {
          "mountpoint": "/",
          "compression": "zstd",
          "recordsize": "128K"
        },
        "home": {
          "mountpoint": "/home",
          "compression": "zstd",
          "recordsize": "1M"
        },
        "var": {
          "mountpoint": "/var",
          "compression": "gzip",
          "recordsize": "16K"
        }
      }
    }
  }
}
```

#### Custom TDP Profiles

```json
{
  "tdp_profiles": {
    "silent": {
      "ac_tdp": 15,
      "battery_tdp": 7,
      "description": "Ultra-quiet operation"
    },
    "workstation": {
      "ac_tdp": 65,
      "battery_tdp": 25,
      "description": "Professional workstation mode"
    },
    "ai_training": {
      "ac_tdp": 100,
      "battery_tdp": 35,
      "description": "AI/ML training workloads"
    },
    "content_creation": {
      "ac_tdp": 75,
      "battery_tdp": 30,
      "description": "Video editing and content creation"
    }
  }
}
```

## 🎛️ Advanced System Tuning

### Kernel Parameter Optimization

#### Custom Kernel Parameters for Z13

```bash
# Create custom kernel parameter configuration
cat > /etc/kernel/cmdline << 'EOF'
# Z13 Optimized Kernel Parameters

# AMD Strix Halo specific optimizations
amd_pstate=active
processor.max_cstate=1
amd_iommu=on
iommu=pt

# Performance optimizations
mitigations=off
nowatchdog
nmi_watchdog=0
rcu_nocbs=0-7
isolcpus=managed_irq,domain,4-7
intel_idle.max_cstate=0
idle=poll

# Memory optimizations
transparent_hugepage=madvise
hugepagesz=2M
hugepages=512

# I/O optimizations
elevator=none
nvme_core.default_ps_max_latency_us=0

# Graphics optimizations
amdgpu.dc=1
amdgpu.dpm=1
amdgpu.runpm=1
amdgpu.bapm=1
amdgpu.deep_color=1

# Audio optimizations
snd_hda_intel.power_save=0
snd_hda_intel.power_save_controller=N

# Network optimizations
pcie_aspm=off

# Security (adjust based on needs)
slub_debug=off
page_poison=off
EOF

# Apply kernel parameters
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

#### Kernel Module Configuration

```bash
# Create custom module configuration
cat > /etc/modprobe.d/z13-advanced.conf << 'EOF'
# Z13 Advanced Module Configuration

# WiFi optimization (MediaTek MT7925e)
options mt7925e disable_aspm=1 power_save=0

# AMD GPU optimization
options amdgpu deep_color=1 dc=1 dpm=1 runpm=1 bapm=1
options amdgpu gpu_recovery=1 ras_enable=1

# Audio optimization
options snd_hda_intel power_save=0 power_save_controller=N
options snd_hda_intel enable_msi=1 single_cmd=0

# CPU frequency scaling
options acpi_cpufreq boost=1

# Power management
options processor ignore_ppc=1 ignore_tpc=1

# USB optimization
options usbcore autosuspend=-1

# Network optimization
options e1000e InterruptThrottleRate=1 EEE=0
EOF
```

### Advanced Systemd Configuration

#### Custom System Services

```bash
# Create Z13 optimization service
cat > /etc/systemd/system/z13-optimization.service << 'EOF'
[Unit]
Description=Z13 System Optimization
After=multi-user.target
Before=graphical.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/z13-system-optimizer
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create the optimization script
cat > /usr/local/bin/z13-system-optimizer << 'EOF'
#!/bin/bash
# Z13 System Optimizer

# CPU optimizations
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo 0 | tee /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias

# GPU optimizations
echo high | tee /sys/class/drm/card0/device/power_dpm_force_performance_level
echo 1 | tee /sys/class/drm/card0/device/pp_power_profile_mode

# I/O optimizations
for device in /sys/block/nvme*; do
    echo none | tee $device/queue/scheduler
    echo 0 | tee $device/queue/add_random
    echo 256 | tee $device/queue/read_ahead_kb
done

# Network optimizations
for interface in /sys/class/net/wl*; do
    if [[ -d "$interface" ]]; then
        interface_name=$(basename "$interface")
        iw dev "$interface_name" set power_save off
    fi
done

# Memory optimizations
echo 1 | tee /proc/sys/vm/compaction_proactiveness
echo 50 | tee /proc/sys/vm/watermark_boost_factor

logger "Z13 system optimizations applied"
EOF

chmod +x /usr/local/bin/z13-system-optimizer
systemctl enable z13-optimization.service
```

#### Custom udev Rules

```bash
# Create advanced udev rules for Z13
cat > /etc/udev/rules.d/99-z13-advanced.rules << 'EOF'
# Z13 Advanced udev Rules

# Set I/O scheduler for NVMe devices
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="256"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/read_ahead_kb}="256"

# WiFi power management
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="/usr/bin/iw dev $name set power_save off"

# USB device power management
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{power/autosuspend}="-1"

# Audio device optimization
ACTION=="add", SUBSYSTEM=="sound", KERNEL=="card*", ATTR{power/control}="on"

# Graphics device optimization
ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card*", ATTR{device/power_dpm_force_performance_level}="auto"

# Thermal zone optimization
ACTION=="add", SUBSYSTEM=="thermal", KERNEL=="thermal_zone*", ATTR{policy}="power_allocator"

# CPU frequency scaling
ACTION=="add", SUBSYSTEM=="cpu", KERNEL=="cpu*", ATTR{cpufreq/scaling_governor}="performance"
EOF
```

### Advanced Power Management

#### Custom TLP Configuration

```bash
# Create advanced TLP configuration
cat > /etc/tlp.d/01-z13-advanced.conf << 'EOF'
# Z13 Advanced TLP Configuration

# CPU Scaling
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_SCALING_MIN_FREQ_ON_AC=1200000
CPU_SCALING_MAX_FREQ_ON_AC=5400000
CPU_SCALING_MIN_FREQ_ON_BAT=1200000
CPU_SCALING_MAX_FREQ_ON_BAT=3600000

# CPU Energy Performance Preferences
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# CPU Boost
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Platform Profile
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Processor P-states
CPU_HWP_ON_AC=balance_performance
CPU_HWP_ON_BAT=balance_power

# GPU Power Management
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery
RADEON_DPM_PERF_LEVEL_ON_AC=high
RADEON_DPM_PERF_LEVEL_ON_BAT=low

# WiFi Power Saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Sound Power Saving
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=10
SOUND_POWER_SAVE_CONTROLLER_ON_AC=N
SOUND_POWER_SAVE_CONTROLLER_ON_BAT=Y

# Runtime Power Management
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB Autosuspend
USB_AUTOSUSPEND=1
USB_BLACKLIST_BTUSB=1
USB_BLACKLIST_PHONE=1

# Battery Features
START_CHARGE_THRESH_BAT0=40
STOP_CHARGE_THRESH_BAT0=80
RESTORE_THRESHOLDS_ON_BAT=1

# PCIe Power Management
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave

# Disk Power Management
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"
DISK_SPINDOWN_TIMEOUT_ON_AC="0 0"
DISK_SPINDOWN_TIMEOUT_ON_BAT="0 0"
DISK_IOSCHED="none none"

# SATA Link Power Management
SATA_LINKPWR_ON_AC=med_power_with_dipm
SATA_LINKPWR_ON_BAT=min_power
EOF
```

#### Custom Power Profiles

```bash
# Create custom power profile daemon
cat > /usr/local/bin/z13-power-daemon << 'EOF'
#!/bin/bash
# Z13 Advanced Power Management Daemon

POWER_STATE_FILE="/tmp/z13-power-state"
LOG_FILE="/var/log/z13-power-daemon.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

get_power_source() {
    if [[ -f /sys/class/power_supply/ADP*/online ]]; then
        cat /sys/class/power_supply/ADP*/online | head -1
    else
        echo "0"
    fi
}

get_battery_level() {
    if [[ -f /sys/class/power_supply/BAT*/capacity ]]; then
        cat /sys/class/power_supply/BAT*/capacity | head -1
    else
        echo "100"
    fi
}

get_cpu_load() {
    awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' \
        <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat) | tr -d '%'
}

apply_power_profile() {
    local profile="$1"
    local current_state=$(cat "$POWER_STATE_FILE" 2>/dev/null || echo "unknown")
    
    if [[ "$current_state" == "$profile" ]]; then
        return 0  # Already in this state
    fi
    
    log_message "Switching to power profile: $profile"
    echo "$profile" > "$POWER_STATE_FILE"
    
    case "$profile" in
        "ac_performance")
            z13-tdp performance
            echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            echo high | tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1
            ;;
        "ac_balanced")
            z13-tdp balanced
            echo ondemand | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            echo auto | tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1
            ;;
        "battery_performance")
            z13-tdp balanced
            echo ondemand | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            echo auto | tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1
            ;;
        "battery_balanced")
            z13-tdp efficient
            echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            echo low | tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1
            ;;
        "battery_saver")
            z13-tdp efficient
            echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            echo low | tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1
            # Enable additional power saving
            for interface in /sys/class/net/wl*; do
                if [[ -d "$interface" ]]; then
                    interface_name=$(basename "$interface")
                    iw dev "$interface_name" set power_save on 2>/dev/null || true
                fi
            done
            ;;
    esac
}

# Main daemon loop
main_loop() {
    log_message "Z13 Power Daemon started"
    
    while true; do
        local power_source=$(get_power_source)
        local battery_level=$(get_battery_level)
        local cpu_load=$(get_cpu_load)
        
        if [[ "$power_source" == "1" ]]; then
            # On AC power
            if (( $(echo "$cpu_load > 80" | bc -l) )); then
                apply_power_profile "ac_performance"
            else
                apply_power_profile "ac_balanced"
            fi
        else
            # On battery power
            if [[ $battery_level -lt 20 ]]; then
                apply_power_profile "battery_saver"
            elif [[ $battery_level -lt 50 ]]; then
                apply_power_profile "battery_balanced"
            else
                if (( $(echo "$cpu_load > 60" | bc -l) )); then
                    apply_power_profile "battery_performance"
                else
                    apply_power_profile "battery_balanced"
                fi
            fi
        fi
        
        sleep 30  # Check every 30 seconds
    done
}

case "$1" in
    "start")
        main_loop
        ;;
    "status")
        cat "$POWER_STATE_FILE" 2>/dev/null || echo "unknown"
        ;;
    *)
        echo "Usage: $0 {start|status}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/z13-power-daemon

# Create systemd service for power daemon
cat > /etc/systemd/system/z13-power-daemon.service << 'EOF'
[Unit]
Description=Z13 Advanced Power Management Daemon
After=multi-user.target
Wants=z13-tdp.service

[Service]
Type=simple
ExecStart=/usr/local/bin/z13-power-daemon start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl enable z13-power-daemon.service
```

## 🖥️ Advanced Display Configuration

### Custom Display Profiles

```bash
# Create display profile manager
cat > /usr/local/bin/z13-display-manager << 'EOF'
#!/bin/bash
# Z13 Display Profile Manager

DISPLAY_CONFIG_DIR="/etc/z13/display-profiles"
CURRENT_PROFILE_FILE="/tmp/z13-display-profile"

mkdir -p "$DISPLAY_CONFIG_DIR"

# Gaming profile - 180Hz, VRR enabled
create_gaming_profile() {
    cat > "$DISPLAY_CONFIG_DIR/gaming.conf" << 'GAMING_PROFILE'
# Gaming Display Profile
refresh_rate=180
vrr_enabled=true
adaptive_sync=true
color_depth=8
color_space=sRGB
brightness=80
contrast=100
gamma=1.0
GAMING_PROFILE
}

# Productivity profile - 60Hz, color accuracy
create_productivity_profile() {
    cat > "$DISPLAY_CONFIG_DIR/productivity.conf" << 'PRODUCTIVITY_PROFILE'
# Productivity Display Profile
refresh_rate=60
vrr_enabled=false
adaptive_sync=false
color_depth=10
color_space=DCI-P3
brightness=60
contrast=95
gamma=2.2
PRODUCTIVITY_PROFILE
}

# Battery profile - 60Hz, reduced brightness
create_battery_profile() {
    cat > "$DISPLAY_CONFIG_DIR/battery.conf" << 'BATTERY_PROFILE'
# Battery Saving Display Profile
refresh_rate=60
vrr_enabled=false
adaptive_sync=false
color_depth=8
color_space=sRGB
brightness=30
contrast=90
gamma=1.8
BATTERY_PROFILE
}

apply_profile() {
    local profile="$1"
    local config_file="$DISPLAY_CONFIG_DIR/$profile.conf"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Profile not found: $profile"
        return 1
    fi
    
    source "$config_file"
    
    # Apply refresh rate
    xrandr --output eDP-1 --mode 1920x1200 --rate "$refresh_rate"
    
    # Apply brightness
    echo $(( brightness * 255 / 100 )) | tee /sys/class/backlight/*/brightness
    
    # Apply VRR if supported
    if [[ "$vrr_enabled" == "true" ]]; then
        echo 1 | tee /sys/class/drm/card0/device/vrr_capable 2>/dev/null || true
    else
        echo 0 | tee /sys/class/drm/card0/device/vrr_capable 2>/dev/null || true
    fi
    
    echo "$profile" > "$CURRENT_PROFILE_FILE"
    echo "Applied display profile: $profile"
}

case "$1" in
    "create-defaults")
        create_gaming_profile
        create_productivity_profile
        create_battery_profile
        echo "Default display profiles created"
        ;;
    "apply")
        apply_profile "$2"
        ;;
    "current")
        cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo "unknown"
        ;;
    "list")
        echo "Available display profiles:"
        ls "$DISPLAY_CONFIG_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/.conf$//'
        ;;
    *)
        echo "Usage: $0 {create-defaults|apply <profile>|current|list}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/z13-display-manager

# Initialize default profiles
/usr/local/bin/z13-display-manager create-defaults
```

### Advanced Color Management

```bash
# Install color management tools
sudo pacman -S colord argyllcms displaycal

# Create color profile script
cat > ~/.local/bin/color-calibration << 'EOF'
#!/bin/bash
# Z13 Color Calibration Helper

calibrate_display() {
    echo "Starting display calibration..."
    echo "Make sure your display has been warmed up for at least 30 minutes"
    echo "Ensure ambient lighting is consistent with your typical usage"
    
    # Launch DisplayCAL
    displaycal
}

apply_color_profile() {
    local profile="$1"
    
    if [[ -f "$profile" ]]; then
        colormgr import-profile "$profile"
        colormgr device-add-profile eDP-1 "$profile"
        colormgr device-make-profile-default eDP-1 "$profile"
        echo "Applied color profile: $profile"
    else
        echo "Color profile not found: $profile"
    fi
}

case "$1" in
    "calibrate")
        calibrate_display
        ;;
    "apply")
        apply_color_profile "$2"
        ;;
    "list")
        colormgr get-profiles
        ;;
    *)
        echo "Usage: $0 {calibrate|apply <profile>|list}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/color-calibration
```

## 🔊 Advanced Audio Configuration

### Professional Audio Setup

```bash
# Install professional audio tools
sudo pacman -S pipewire-jack pipewire-alsa pipewire-pulse
sudo pacman -S qjackctl carla ardour reaper

# Create low-latency audio configuration
cat > ~/.config/pipewire/pipewire.conf.d/99-z13-audio.conf << 'EOF'
# Z13 Professional Audio Configuration

context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 256
    default.clock.min-quantum = 64
    default.clock.max-quantum = 2048
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level = -11
            rt.prio = 88
            rt.time.soft = 2000000
            rt.time.hard = 2000000
        }
        flags = [ ifexists nofail ]
    }
]
EOF

# Create JACK configuration for ultra-low latency
cat > ~/.jackdrc << 'EOF'
/usr/bin/jackd -P75 -dalsa -dhw:0 -r48000 -p64 -n3 -s -S
EOF

# Create audio optimization script
cat > ~/.local/bin/audio-optimizer << 'EOF'
#!/bin/bash
# Z13 Audio Optimizer

enable_pro_audio() {
    echo "Enabling professional audio mode..."
    
    # Set real-time limits
    echo "@audio - rtprio 95
@audio - memlock unlimited
@audio - nice -10" | sudo tee -a /etc/security/limits.conf
    
    # Add user to audio group
    sudo usermod -a -G audio "$USER"
    
    # Optimize kernel for audio
    echo 'kernel.sched_rt_runtime_us = -1' | sudo tee -a /etc/sysctl.d/99-audio.conf
    
    # Start JACK
    jack_control start
    
    echo "Professional audio mode enabled. Please log out and back in."
}

disable_pro_audio() {
    echo "Disabling professional audio mode..."
    
    # Stop JACK
    jack_control stop
    
    # Switch back to regular audio
    systemctl --user restart pipewire pipewire-pulse
    
    echo "Regular audio mode restored"
}

case "$1" in
    "enable")
        enable_pro_audio
        ;;
    "disable")
        disable_pro_audio
        ;;
    "status")
        jack_control status
        ;;
    *)
        echo "Usage: $0 {enable|disable|status}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/audio-optimizer
```

## 🌐 Advanced Networking

### Network Performance Optimization

```bash
# Create advanced network configuration
cat > /etc/sysctl.d/99-z13-network-advanced.conf << 'EOF'
# Z13 Advanced Network Optimization

# TCP congestion control
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# TCP window scaling
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 131072 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mem = 786432 1048576 26777216

# TCP performance tuning
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_base_mss = 1024

# Network buffer optimization
net.core.rmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_default = 262144
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 30000
net.core.netdev_budget = 600

# Reduce network latency
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_low_latency = 1

# IPv6 optimization
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
EOF

sudo sysctl -p /etc/sysctl.d/99-z13-network-advanced.conf
```

### VPN Configuration

```bash
# Install VPN tools
sudo pacman -S openvpn wireguard-tools networkmanager-openvpn

# Create VPN optimization script
cat > ~/.local/bin/vpn-optimizer << 'EOF'
#!/bin/bash
# Z13 VPN Optimizer

optimize_for_vpn() {
    echo "Optimizing network for VPN usage..."
    
    # Increase MTU for better VPN performance
    sudo ip link set dev wlan0 mtu 1500
    
    # Optimize TCP for VPN
    echo 'net.ipv4.tcp_mtu_probing = 1' | sudo tee -a /etc/sysctl.d/99-vpn.conf
    echo 'net.ipv4.tcp_congestion_control = bbr' | sudo tee -a /etc/sysctl.d/99-vpn.conf
    
    sudo sysctl -p /etc/sysctl.d/99-vpn.conf
    
    echo "VPN optimization applied"
}

create_wireguard_config() {
    local config_name="$1"
    
    if [[ -z "$config_name" ]]; then
        echo "Usage: create_wireguard_config <config_name>"
        return 1
    fi
    
    # Generate keys
    local private_key=$(wg genkey)
    local public_key=$(echo "$private_key" | wg pubkey)
    
    echo "Generated WireGuard configuration:"
    echo "Private Key: $private_key"
    echo "Public Key: $public_key"
    
    # Create configuration template
    cat > "/tmp/wg-$config_name.conf" << WG_CONFIG
[Interface]
PrivateKey = $private_key
Address = 10.0.0.2/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_ENDPOINT>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
WG_CONFIG
    
    echo "Configuration template created: /tmp/wg-$config_name.conf"
    echo "Please edit the file and add your server details"
}

case "$1" in
    "optimize")
        optimize_for_vpn
        ;;
    "create-wg")
        create_wireguard_config "$2"
        ;;
    *)
        echo "Usage: $0 {optimize|create-wg <name>}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/vpn-optimizer
```

## 🔒 Advanced Security Configuration

### Custom Security Policies

```bash
# Create custom AppArmor profiles
cat > /etc/apparmor.d/local/z13-custom << 'EOF'
# Z13 Custom AppArmor Profiles

# Profile for custom applications
/usr/local/bin/z13-* {
    #include <abstractions/base>
    #include <abstractions/bash>
    
    capability sys_admin,
    capability dac_override,
    
    /usr/local/bin/z13-* r,
    /bin/bash ix,
    /usr/bin/* rix,
    /sys/class/** rw,
    /proc/sys/** rw,
    /var/log/z13-*.log w,
    /etc/z13/** r,
    /tmp/z13-* rw,
}
EOF

# Advanced firewall configuration
cat > ~/.local/bin/firewall-advanced << 'EOF'
#!/bin/bash
# Z13 Advanced Firewall Configuration

setup_gaming_firewall() {
    echo "Setting up gaming-optimized firewall..."
    
    # Reset UFW
    sudo ufw --force reset
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Gaming ports
    sudo ufw allow 27000:27050/udp  # Steam
    sudo ufw allow 3478:3480/udp    # PlayStation
    sudo ufw allow 53/udp           # DNS
    sudo ufw allow 80/tcp           # HTTP
    sudo ufw allow 443/tcp          # HTTPS
    
    # Local network
    sudo ufw allow from 192.168.0.0/16
    sudo ufw allow from 10.0.0.0/8
    
    # Enable with logging
    sudo ufw logging on
    sudo ufw --force enable
    
    echo "Gaming firewall configured"
}

setup_work_firewall() {
    echo "Setting up work-optimized firewall..."
    
    # Reset UFW
    sudo ufw --force reset
    
    # Strict default policies
    sudo ufw default deny incoming
    sudo ufw default deny outgoing
    
    # Essential services only
    sudo ufw allow out 53/udp       # DNS
    sudo ufw allow out 80/tcp       # HTTP
    sudo ufw allow out 443/tcp      # HTTPS
    sudo ufw allow out 22/tcp       # SSH
    sudo ufw allow out 993/tcp      # IMAPS
    sudo ufw allow out 587/tcp      # SMTP
    
    # Local network (restricted)
    sudo ufw allow from 192.168.1.0/24
    
    # Enable with high logging
    sudo ufw logging high
    sudo ufw --force enable
    
    echo "Work firewall configured"
}

case "$1" in
    "gaming")
        setup_gaming_firewall
        ;;
    "work")
        setup_work_firewall
        ;;
    "status")
        sudo ufw status verbose
        ;;
    *)
        echo "Usage: $0 {gaming|work|status}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/firewall-advanced
```

### Intrusion Detection System

```bash
# Create advanced IDS configuration
cat > ~/.local/bin/z13-ids << 'EOF'
#!/bin/bash
# Z13 Intrusion Detection System

IDS_LOG="/var/log/z13-ids.log"
IDS_CONFIG="/etc/z13/ids.conf"

create_ids_config() {
    mkdir -p "$(dirname "$IDS_CONFIG")"
    
    cat > "$IDS_CONFIG" << 'IDS_CONFIG_CONTENT'
# Z13 IDS Configuration

# Monitoring settings
MONITOR_NETWORK=true
MONITOR_FILES=true
MONITOR_PROCESSES=true
MONITOR_LOGINS=true

# Alert thresholds
MAX_FAILED_LOGINS=5
MAX_NETWORK_CONNECTIONS=100
SUSPICIOUS_PROCESSES="nc,netcat,nmap,nikto,sqlmap"

# Notification settings
ENABLE_ALERTS=true
ALERT_EMAIL=""
ALERT_DESKTOP=true
IDS_CONFIG_CONTENT
}

monitor_network() {
    local connections=$(netstat -tuln | wc -l)
    
    if [[ $connections -gt $MAX_NETWORK_CONNECTIONS ]]; then
        log_alert "HIGH" "Excessive network connections: $connections"
    fi
    
    # Monitor for suspicious network activity
    netstat -tuln | grep -E ":(1234|4444|5555|6666|31337)" && {
        log_alert "CRITICAL" "Suspicious network ports detected"
    }
}

monitor_processes() {
    for process in $SUSPICIOUS_PROCESSES; do
        if pgrep "$process" >/dev/null; then
            log_alert "WARNING" "Suspicious process detected: $process"
        fi
    done
    
    # Monitor for unusual CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$cpu_usage > 95" | bc -l) )); then
        log_alert "WARNING" "High CPU usage: $cpu_usage%"
    fi
}

monitor_logins() {
    local failed_logins=$(journalctl --since "1 hour ago" | grep "Failed password" | wc -l)
    
    if [[ $failed_logins -gt $MAX_FAILED_LOGINS ]]; then
        log_alert "CRITICAL" "Multiple failed login attempts: $failed_logins"
    fi
}

log_alert() {
    local severity="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$severity] $message" >> "$IDS_LOG"
    
    if [[ "$ENABLE_ALERTS" == "true" ]]; then
        if [[ "$ALERT_DESKTOP" == "true" ]]; then
            notify-send --urgency=critical "Z13 IDS Alert" "$message"
        fi
    fi
}

main_monitor() {
    if [[ ! -f "$IDS_CONFIG" ]]; then
        create_ids_config
    fi
    
    source "$IDS_CONFIG"
    
    while true; do
        [[ "$MONITOR_NETWORK" == "true" ]] && monitor_network
        [[ "$MONITOR_PROCESSES" == "true" ]] && monitor_processes
        [[ "$MONITOR_LOGINS" == "true" ]] && monitor_logins
        
        sleep 60  # Check every minute
    done
}

case "$1" in
    "start")
        echo "Starting Z13 IDS..."
        main_monitor
        ;;
    "status")
        echo "Recent IDS alerts:"
        tail -20 "$IDS_LOG" 2>/dev/null || echo "No alerts logged"
        ;;
    "config")
        if [[ -f "$IDS_CONFIG" ]]; then
            cat "$IDS_CONFIG"
        else
            echo "Creating default IDS configuration..."
            create_ids_config
            echo "Configuration created at: $IDS_CONFIG"
        fi
        ;;
    *)
        echo "Usage: $0 {start|status|config}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/z13-ids
```

## 🎮 Advanced Gaming Configuration

### Game-Specific Optimizations

```bash
# Create game optimizer
cat > ~/.local/bin/game-optimizer << 'EOF'
#!/bin/bash
# Z13 Game-Specific Optimizer

GAME_PROFILES_DIR="$HOME/.config/z13-gaming/profiles"
mkdir -p "$GAME_PROFILES_DIR"

create_steam_profile() {
    cat > "$GAME_PROFILES_DIR/steam.conf" << 'STEAM_PROFILE'
# Steam Optimization Profile
tdp_profile=gaming
cpu_governor=performance
gpu_profile=high
memory_optimization=true
network_optimization=true
audio_optimization=false

# Steam-specific settings
steam_launch_options="gamemoderun %command%"
proton_version="experimental"
enable_fsync=true
enable_esync=true
STEAM_PROFILE
}

create_native_profile() {
    cat > "$GAME_PROFILES_DIR/native.conf" << 'NATIVE_PROFILE'
# Native Games Optimization Profile
tdp_profile=gaming
cpu_governor=performance
gpu_profile=high
memory_optimization=true
network_optimization=false
audio_optimization=true

# Native game settings
enable_gamemode=true
cpu_affinity="4-7"
nice_level=-10
NATIVE_PROFILE
}

apply_game_profile() {
    local profile="$1"
    local config_file="$GAME_PROFILES_DIR/$profile.conf"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Profile not found: $profile"
        return 1
    fi
    
    source "$config_file"
    
    # Apply TDP profile
    z13-tdp "$tdp_profile"
    
    # Apply CPU governor
    echo "$cpu_governor" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    
    # Apply GPU profile
    case "$gpu_profile" in
        "high")
            echo high | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
            ;;
        "auto")
            echo auto | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
            ;;
    esac
    
    # Memory optimization
    if [[ "$memory_optimization" == "true" ]]; then
        echo 1 | sudo tee /proc/sys/vm/drop_caches
        echo 1 | sudo tee /proc/sys/vm/compact_memory
    fi
    
    echo "Applied game profile: $profile"
}

optimize_for_game() {
    local game_name="$1"
    
    case "$game_name" in
        "cyberpunk2077"|"witcher3"|"rdr2")
            apply_game_profile "steam"
            echo "Optimized for AAA gaming"
            ;;
        "csgo"|"valorant"|"apex")
            apply_game_profile "competitive"
            echo "Optimized for competitive gaming"
            ;;
        "minecraft"|"terraria"|"stardew")
            apply_game_profile "indie"
            echo "Optimized for indie gaming"
            ;;
        *)
            apply_game_profile "steam"
            echo "Applied default gaming optimization"
            ;;
    esac
}

case "$1" in
    "create-profiles")
        create_steam_profile
        create_native_profile
        echo "Game profiles created"
        ;;
    "apply")
        apply_game_profile "$2"
        ;;
    "optimize")
        optimize_for_game "$2"
        ;;
    "list")
        echo "Available game profiles:"
        ls "$GAME_PROFILES_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/.conf$//'
        ;;
    *)
        echo "Usage: $0 {create-profiles|apply <profile>|optimize <game>|list}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/game-optimizer

# Initialize game profiles
/usr/local/bin/game-optimizer create-profiles
```

## 🔧 System Maintenance Automation

### Automated Maintenance Scripts

```bash
# Create comprehensive maintenance script
cat > /usr/local/bin/z13-maintenance << 'EOF'
#!/bin/bash
# Z13 Automated Maintenance System

MAINTENANCE_LOG="/var/log/z13-maintenance.log"
MAINTENANCE_CONFIG="/etc/z13/maintenance.conf"

log_maintenance() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$MAINTENANCE_LOG"
}

create_maintenance_config() {
    mkdir -p "$(dirname "$MAINTENANCE_CONFIG")"
    
    cat > "$MAINTENANCE_CONFIG" << 'MAINT_CONFIG'
# Z13 Maintenance Configuration

# System maintenance
ENABLE_PACKAGE_UPDATES=true
ENABLE_CACHE_CLEANUP=true
ENABLE_LOG_ROTATION=true
ENABLE_TEMP_CLEANUP=true

# Performance maintenance
ENABLE_MEMORY_OPTIMIZATION=true
ENABLE_DISK_OPTIMIZATION=true
ENABLE_DATABASE_OPTIMIZATION=true

# Security maintenance
ENABLE_SECURITY_UPDATES=true
ENABLE_VIRUS_SCAN=false
ENABLE_INTEGRITY_CHECK=true

# Backup maintenance
ENABLE_BACKUP_VERIFICATION=true
ENABLE_OLD_BACKUP_CLEANUP=true

# Notification settings
ENABLE_MAINTENANCE_REPORTS=true
MAINTENANCE_EMAIL=""
MAINT_CONFIG
}

system_maintenance() {
    log_maintenance "Starting system maintenance"
    
    if [[ "$ENABLE_PACKAGE_UPDATES" == "true" ]]; then
        log_maintenance "Updating package database"
        pacman -Sy --noconfirm
    fi
    
    if [[ "$ENABLE_CACHE_CLEANUP" == "true" ]]; then
        log_maintenance "Cleaning package cache"
        pacman -Scc --noconfirm
        
        # Clean user cache
        rm -rf ~/.cache/thumbnails/*
        rm -rf ~/.cache/mozilla/*
    fi
    
    if [[ "$ENABLE_LOG_ROTATION" == "true" ]]; then
        log_maintenance "Rotating logs"
        journalctl --vacuum-time=30d
        find /var/log -name "*.log" -mtime +30 -delete
    fi
    
    if [[ "$ENABLE_TEMP_CLEANUP" == "true" ]]; then
        log_maintenance "Cleaning temporary files"
        rm -rf /tmp/*
        rm -rf /var/tmp/*
    fi
}

performance_maintenance() {
    log_maintenance "Starting performance maintenance"
    
    if [[ "$ENABLE_MEMORY_OPTIMIZATION" == "true" ]]; then
        log_maintenance "Optimizing memory"
        sync
        echo 3 > /proc/sys/vm/drop_caches
        echo 1 > /proc/sys/vm/compact_memory
    fi
    
    if [[ "$ENABLE_DISK_OPTIMIZATION" == "true" ]]; then
        log_maintenance "Optimizing disk"
        
        # Trim SSD
        fstrim -av
        
        # Optimize filesystem based on type
        local fs_type=$(findmnt -n -o FSTYPE /)
        case "$fs_type" in
            "zfs")
                zpool scrub zroot
                ;;
            "btrfs")
                btrfs balance start -dusage=50 -musage=50 /
                btrfs scrub start /
                ;;
            "ext4")
                tune2fs -l /dev/$(findmnt -n -o SOURCE /) | grep -q "needs_recovery" && {
                    log_maintenance "WARNING: ext4 filesystem needs recovery"
                }
                ;;
        esac
    fi
    
    if [[ "$ENABLE_DATABASE_OPTIMIZATION" == "true" ]]; then
        log_maintenance "Optimizing databases"
        
        # Update locate database
        updatedb
        
        # Update font cache
        fc-cache -fv
        
        # Update desktop database
        update-desktop-database
    fi
}

security_maintenance() {
    log_maintenance "Starting security maintenance"
    
    if [[ "$ENABLE_SECURITY_UPDATES" == "true" ]]; then
        log_maintenance "Checking for security updates"
        # This would integrate with your security update system
    fi
    
    if [[ "$ENABLE_INTEGRITY_CHECK" == "true" ]]; then
        log_maintenance "Running integrity checks"
        
        # Check important system files
        if command -v aide >/dev/null 2>&1; then
            aide --check --quiet || log_maintenance "WARNING: AIDE integrity check failed"
        fi
        
        # Verify package integrity
        pacman -Qkk | grep -E "warning|error" && {
            log_maintenance "WARNING: Package integrity issues detected"
        }
    fi
}

backup_maintenance() {
    log_maintenance "Starting backup maintenance"
    
    if [[ "$ENABLE_BACKUP_VERIFICATION" == "true" ]]; then
        log_maintenance "Verifying backups"
        z13-backup-monitor check
    fi
    
    if [[ "$ENABLE_OLD_BACKUP_CLEANUP" == "true" ]]; then
        log_maintenance "Cleaning old backups"
        z13-backup-manager cleanup
    fi
}

generate_maintenance_report() {
    local report_file="/tmp/z13-maintenance-report-$(date +%Y%m%d).txt"
    
    cat > "$report_file" << REPORT_HEADER
Z13 Maintenance Report
Generated: $(date)
System: $(uname -a)

REPORT_HEADER
    
    echo "System Status:" >> "$report_file"
    z13-health-monitor status >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Disk Usage:" >> "$report_file"
    df -h >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Memory Usage:" >> "$report_file"
    free -h >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Recent Maintenance Activities:" >> "$report_file"
    tail -20 "$MAINTENANCE_LOG" >> "$report_file"
    
    if [[ "$ENABLE_MAINTENANCE_REPORTS" == "true" ]]; then
        echo "Maintenance report generated: $report_file"
        
        if [[ -n "$MAINTENANCE_EMAIL" ]]; then
            mail -s "Z13 Maintenance Report" "$MAINTENANCE_EMAIL" < "$report_file"
        fi
    fi
}

full_maintenance() {
    if [[ ! -f "$MAINTENANCE_CONFIG" ]]; then
        create_maintenance_config
    fi
    
    source "$MAINTENANCE_CONFIG"
    
    log_maintenance "Starting full system maintenance"
    
    system_maintenance
    performance_maintenance
    security_maintenance
    backup_maintenance
    
    generate_maintenance_report
    
    log_maintenance "Full system maintenance completed"
}

case "$1" in
    "full")
        full_maintenance
        ;;
    "system")
        source "$MAINTENANCE_CONFIG" 2>/dev/null || create_maintenance_config
        system_maintenance
        ;;
    "performance")
        source "$MAINTENANCE_CONFIG" 2>/dev/null || create_maintenance_config
        performance_maintenance
        ;;
    "security")
        source "$MAINTENANCE_CONFIG" 2>/dev/null || create_maintenance_config
        security_maintenance
        ;;
    "backup")
        source "$MAINTENANCE_CONFIG" 2>/dev/null || create_maintenance_config
        backup_maintenance
        ;;
    "report")
        generate_maintenance_report
        ;;
    "config")
        if [[ -f "$MAINTENANCE_CONFIG" ]]; then
            cat "$MAINTENANCE_CONFIG"
        else
            create_maintenance_config
            echo "Configuration created at: $MAINTENANCE_CONFIG"
        fi
        ;;
    *)
        echo "Usage: $0 {full|system|performance|security|backup|report|config}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/z13-maintenance

# Create automated maintenance timer
cat > /etc/systemd/system/z13-maintenance.service << 'EOF'
[Unit]
Description=Z13 System Maintenance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-maintenance full
StandardOutput=journal
StandardError=journal
EOF

cat > /etc/systemd/system/z13-maintenance.timer << 'EOF'
[Unit]
Description=Run Z13 maintenance weekly
Requires=z13-maintenance.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl enable z13-maintenance.timer
```

This completes the comprehensive advanced configuration guide. The Z13 installation system now includes:

1. **Custom configuration files** with full JSON schema support
2. **Advanced system tuning** with kernel parameters and module optimization
3. **Professional audio** configuration for content creation
4. **Advanced networking** with VPN optimization
5. **Enhanced security** with custom policies and IDS
6. **Game-specific optimizations** for different gaming scenarios
7. **Automated maintenance** system for long-term system health

All these advanced features work together to provide a truly professional-grade installation system that can be customized for any use case while maintaining the Z13's unique hardware optimizations.
