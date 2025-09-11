# Z13 Performance Tuning Guide

**ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+ Performance Optimization**

Unlock the full potential of your Z13 with comprehensive performance tuning strategies.

## 🎯 Performance Overview

The ASUS ROG Flow Z13 (2025) with AMD Strix Halo AI Max+ is a unique device that balances portability with performance. Understanding its thermal and power characteristics is key to optimal tuning.

### Hardware Specifications
- **CPU**: AMD Strix Halo AI Max+ (up to 120W TDP)
- **GPU**: Integrated RDNA graphics with up to 48GB VRAM allocation
- **Memory**: DDR5-5600 (32GB+ recommended)
- **Storage**: PCIe 4.0 NVMe SSD
- **Display**: 13.4" 1920x1200 @ 180Hz with VRR support

### Performance Characteristics
- **Thermal Design**: Compact form factor limits sustained high-power operation
- **Power Scaling**: Dynamic 7W-120W TDP range based on workload and power source
- **Memory Architecture**: Unified memory architecture with configurable VRAM allocation

## ⚡ Dynamic TDP Management

### Understanding TDP Profiles

The Z13's dynamic TDP system automatically adjusts performance based on conditions:

```bash
# Check current TDP status
z13-tdp status

# Available profiles
efficient    # 7W  - Maximum battery life (8-12 hours)
balanced     # 45W - Good performance/battery balance (4-6 hours)
performance  # 85W - High performance with thermal limits (2-3 hours)
gaming       # 93W - Maximum performance for gaming (1.5-2.5 hours)
maximum      # 120W - Peak performance, very limited duration
```

### Custom TDP Configuration

Create custom TDP profiles for specific workloads:

```bash
# Create custom profile for development work
sudo z13-tdp create dev_profile 35 20 "Development workload - 35W AC, 20W battery"

# Create custom profile for AI workloads
sudo z13-tdp create ai_workload 75 30 "AI/ML training - 75W AC, 30W battery"

# List all profiles
z13-tdp list

# Use custom profile
z13-tdp dev_profile
```

### Advanced TDP Scripting

Automate TDP changes based on running applications:

```bash
# Create application-specific TDP script
cat > ~/.local/bin/smart-tdp << 'EOF'
#!/bin/bash
# Smart TDP management based on running applications

while true; do
    # Check for gaming applications
    if pgrep -f "steam|lutris|wine|proton" > /dev/null; then
        current_profile=$(z13-tdp status | grep "Current profile" | awk '{print $3}')
        if [[ "$current_profile" != "gaming" ]]; then
            z13-tdp gaming
        fi
    
    # Check for development tools
    elif pgrep -f "code|vim|emacs|jetbrains|docker" > /dev/null; then
        current_profile=$(z13-tdp status | grep "Current profile" | awk '{print $3}')
        if [[ "$current_profile" != "dev_profile" ]]; then
            z13-tdp dev_profile 2>/dev/null || z13-tdp balanced
        fi
    
    # Check for media/streaming
    elif pgrep -f "obs|vlc|mpv|firefox.*youtube|chrome.*netflix" > /dev/null; then
        current_profile=$(z13-tdp status | grep "Current profile" | awk '{print $3}')
        if [[ "$current_profile" != "balanced" ]]; then
            z13-tdp balanced
        fi
    
    # Default to efficient when idle
    else
        current_profile=$(z13-tdp status | grep "Current profile" | awk '{print $3}')
        if [[ "$current_profile" != "efficient" ]]; then
            # Only switch to efficient if system has been idle for 10 minutes
            idle_time=$(xprintidle 2>/dev/null || echo 0)
            if [[ $idle_time -gt 600000 ]]; then  # 10 minutes in milliseconds
                z13-tdp efficient
            fi
        fi
    fi
    
    sleep 30  # Check every 30 seconds
done
EOF

chmod +x ~/.local/bin/smart-tdp

# Create systemd service for smart TDP
cat > ~/.config/systemd/user/smart-tdp.service << 'EOF'
[Unit]
Description=Smart TDP Management
After=graphical-session.target

[Service]
ExecStart=%h/.local/bin/smart-tdp
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Enable smart TDP service
systemctl --user enable smart-tdp.service
systemctl --user start smart-tdp.service
```

## 🖥️ CPU Optimization

### CPU Governor Tuning

Optimize CPU scaling for different workloads:

```bash
# Check available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# Performance tuning for different scenarios
performance_cpu() {
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias
}

balanced_cpu() {
    echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    echo 50 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
    echo 10 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
}

efficient_cpu() {
    echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    echo 1 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias
}
```

### AMD P-State Tuning

Leverage AMD P-State driver for better power efficiency:

```bash
# Check if AMD P-State is available
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver

# Configure AMD P-State EPP (Energy Performance Preference)
configure_amd_pstate() {
    local mode="$1"  # performance, balance_performance, balance_power, power
    
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [[ -f "$cpu" ]]; then
            echo "$mode" | sudo tee "$cpu"
        fi
    done
}

# Usage examples
configure_amd_pstate "performance"        # Gaming/intensive workloads
configure_amd_pstate "balance_performance" # General use
configure_amd_pstate "balance_power"      # Battery optimization
configure_amd_pstate "power"              # Maximum power saving
```

### CPU Core Management

Optimize CPU core usage for specific workloads:

```bash
# Isolate CPU cores for real-time applications
isolate_cores() {
    local cores="$1"  # e.g., "4-7" for cores 4,5,6,7
    
    # Add to kernel parameters (requires reboot)
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/&isolcpus=$cores /" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    echo "Reboot required to isolate cores $cores"
}

# CPU affinity for applications
set_cpu_affinity() {
    local app="$1"
    local cores="$2"
    
    # Set affinity for running application
    pgrep "$app" | xargs -I {} taskset -cp "$cores" {}
}

# Example: Dedicate cores 0-3 to system, 4-7 to gaming
# isolate_cores "4-7"
# set_cpu_affinity "steam" "4-7"
```

## 🧠 Memory Optimization

### Memory Tuning Parameters

Optimize memory management for the Z13's unified architecture:

```bash
# Create optimized memory configuration
cat > /etc/sysctl.d/99-z13-memory-performance.conf << 'EOF'
# Z13 Memory Performance Tuning

# Virtual memory tuning for high-memory systems (32GB+)
vm.swappiness = 1                    # Minimize swap usage
vm.vfs_cache_pressure = 50           # Balance between cache and memory
vm.dirty_background_ratio = 3        # Start background writeback early
vm.dirty_ratio = 6                   # Aggressive dirty page writeback
vm.dirty_expire_centisecs = 1500     # Dirty pages expire quickly
vm.dirty_writeback_centisecs = 250   # Frequent writeback intervals

# Memory allocation optimization
vm.overcommit_memory = 1             # Allow memory overcommit
vm.overcommit_ratio = 80             # Conservative overcommit ratio
vm.min_free_kbytes = 262144          # 256MB minimum free memory

# Transparent Huge Pages optimization
vm.nr_hugepages = 512                # Pre-allocate huge pages
kernel.mm.transparent_hugepage.enabled = always
kernel.mm.transparent_hugepage.defrag = defer+madvise
kernel.mm.transparent_hugepage.khugepaged.scan_sleep_millisecs = 10000

# Memory compaction for reduced fragmentation
vm.compaction_proactiveness = 50     # Proactive memory compaction
vm.watermark_boost_factor = 15000    # Boost reclaim when needed
vm.watermark_scale_factor = 10       # Scale watermarks appropriately

# NUMA optimization (even for single-socket systems)
kernel.numa_balancing = 1            # Enable NUMA balancing
kernel.numa_balancing_scan_delay_ms = 1000
kernel.numa_balancing_scan_period_min_ms = 1000
kernel.numa_balancing_scan_period_max_ms = 60000

# Memory zone optimization
vm.zone_reclaim_mode = 0             # Disable zone reclaim
vm.lowmem_reserve_ratio = 256 256 32 0 0

# Page allocation optimization  
vm.percpu_pagelist_fraction = 0      # Disable per-CPU page lists
vm.page_cluster = 0                  # Disable swap clustering for SSD
EOF

# Apply settings
sudo sysctl -p /etc/sysctl.d/99-z13-memory-performance.conf
```

### VRAM Allocation Optimization

Optimize VRAM allocation for AMD Strix Halo's unified memory:

```bash
# Check current VRAM allocation
check_vram_allocation() {
    echo "System Memory Information:"
    free -h
    
    echo -e "\nGPU Memory Information:"
    if command -v radeontop >/dev/null 2>&1; then
        timeout 2s radeontop -d- | head -5
    fi
    
    echo -e "\nDRM Memory Information:"
    cat /sys/class/drm/card0/device/mem_info_vram_total 2>/dev/null || echo "VRAM info not available"
}

# Optimize VRAM allocation based on use case
optimize_vram_for_gaming() {
    # These settings typically require BIOS configuration
    echo "For gaming optimization:"
    echo "1. Enter BIOS setup (F2 during boot)"
    echo "2. Navigate to Advanced > AMD CBS > NBIO Common Options"
    echo "3. Set 'UMA Frame Buffer Size' to 8GB or higher"
    echo "4. Enable 'Above 4G Decoding' if available"
    echo "5. Save and reboot"
}

optimize_vram_for_productivity() {
    echo "For productivity optimization:"
    echo "1. Enter BIOS setup (F2 during boot)"
    echo "2. Navigate to Advanced > AMD CBS > NBIO Common Options"
    echo "3. Set 'UMA Frame Buffer Size' to 4-6GB"
    echo "4. This leaves more RAM available for applications"
    echo "5. Save and reboot"
}
```

### Memory Monitoring and Optimization

```bash
# Create memory monitoring script
cat > ~/.local/bin/memory-optimizer << 'EOF'
#!/bin/bash
# Z13 Memory Optimizer

optimize_memory() {
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    
    if [[ $mem_usage -gt 85 ]]; then
        echo "High memory usage detected ($mem_usage%). Optimizing..."
        
        # Drop caches if safe to do so
        sync
        echo 1 | sudo tee /proc/sys/vm/drop_caches > /dev/null
        
        # Compact memory
        echo 1 | sudo tee /proc/sys/vm/compact_memory > /dev/null
        
        # Trigger memory reclaim
        echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
        
        echo "Memory optimization completed"
    fi
}

# Run optimization
optimize_memory

# Monitor memory pressure
echo "Memory pressure indicators:"
grep -r . /proc/pressure/memory 2>/dev/null || echo "PSI not available"
EOF

chmod +x ~/.local/bin/memory-optimizer

# Create cron job for automatic memory optimization
(crontab -l 2>/dev/null; echo "*/15 * * * * ~/.local/bin/memory-optimizer") | crontab -
```

## 💾 Storage Optimization

### NVMe SSD Tuning

Optimize NVMe performance for the Z13:

```bash
# Check NVMe information
nvme list
nvme id-ctrl /dev/nvme0n1

# Optimize NVMe queue settings
optimize_nvme() {
    local device="$1"  # e.g., nvme0n1
    
    # Set optimal queue depth
    echo 32 | sudo tee /sys/block/$device/queue/nr_requests
    
    # Disable add_random for SSDs
    echo 0 | sudo tee /sys/block/$device/queue/add_random
    
    # Set appropriate scheduler (none for NVMe)
    echo none | sudo tee /sys/block/$device/queue/scheduler
    
    # Optimize read-ahead
    echo 256 | sudo tee /sys/block/$device/queue/read_ahead_kb
    
    # Disable NCQ if not beneficial
    echo 1 | sudo tee /sys/block/$device/queue/nomerges
}

# Apply to main NVMe drive
optimize_nvme "nvme0n1"
```

### Filesystem Optimization

#### ZFS Tuning (Recommended)

```bash
# Optimize ZFS for Z13 performance
optimize_zfs() {
    # Set ARC (cache) limits - use 25% of RAM for ARC
    local total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local arc_max=$((total_ram * 1024 / 4))  # 25% of RAM in bytes
    local arc_min=$((arc_max / 2))           # Minimum ARC size
    
    echo $arc_max | sudo tee /sys/module/zfs/parameters/zfs_arc_max
    echo $arc_min | sudo tee /sys/module/zfs/parameters/zfs_arc_min
    
    # Optimize ZFS for NVMe
    sudo zfs set compression=zstd zroot
    sudo zfs set atime=off zroot
    sudo zfs set recordsize=1M zroot/home  # Large files
    sudo zfs set recordsize=16K zroot/var  # Small files
    
    # Enable prefetch for sequential workloads
    echo 1 | sudo tee /sys/module/zfs/parameters/zfs_prefetch_disable
    
    # Optimize transaction group timeout
    echo 5 | sudo tee /sys/module/zfs/parameters/zfs_txg_timeout
}
```

#### Btrfs Tuning

```bash
# Optimize Btrfs for performance
optimize_btrfs() {
    # Mount with performance options
    sudo mount -o remount,compress=zstd:3,space_cache=v2,ssd,discard=async /
    
    # Add to fstab for persistence
    sudo sed -i 's/btrfs.*defaults/&,compress=zstd:3,space_cache=v2,ssd,discard=async/' /etc/fstab
    
    # Balance filesystem regularly
    sudo btrfs balance start -dusage=50 -musage=50 /
    
    # Optimize for SSD
    sudo btrfs filesystem defragment -r -v -czstd /
}
```

#### ext4 Tuning

```bash
# Optimize ext4 for performance
optimize_ext4() {
    # Tune filesystem parameters
    sudo tune2fs -o journal_data_writeback /dev/nvme0n1p2
    sudo tune2fs -O ^has_journal /dev/nvme0n1p2  # Disable journal for performance (risky)
    
    # Mount with performance options
    sudo mount -o remount,noatime,commit=60,barrier=0 /
    
    # Add to fstab
    sudo sed -i 's/ext4.*defaults/&,noatime,commit=60,barrier=0/' /etc/fstab
}
```

### I/O Scheduler Optimization

```bash
# Optimize I/O schedulers for different workloads
optimize_io_schedulers() {
    # For NVMe drives - use none (no scheduling overhead)
    for nvme in /sys/block/nvme*; do
        echo none | sudo tee $nvme/queue/scheduler
    done
    
    # For SATA SSDs - use mq-deadline
    for ssd in /sys/block/sd*; do
        if [[ $(cat $ssd/queue/rotational) == "0" ]]; then
            echo mq-deadline | sudo tee $ssd/queue/scheduler
        fi
    done
    
    # For HDDs - use bfq (if any)
    for hdd in /sys/block/sd*; do
        if [[ $(cat $hdd/queue/rotational) == "1" ]]; then
            echo bfq | sudo tee $hdd/queue/scheduler
        fi
    done
}

# Make I/O scheduler changes persistent
cat > /etc/udev/rules.d/60-ioschedulers.rules << 'EOF'
# Set I/O scheduler for NVMe devices
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"

# Set I/O scheduler for SATA SSDs
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"

# Set I/O scheduler for HDDs
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
```

## 🎮 Gaming Optimization

### GPU Performance Tuning

```bash
# AMD GPU optimization for gaming
optimize_amd_gpu_gaming() {
    # Set GPU to high performance mode
    echo high | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
    
    # Set GPU power profile to 3D full screen
    echo 1 | sudo tee /sys/class/drm/card0/device/pp_power_profile_mode
    
    # Maximize GPU clocks
    local max_sclk=$(cat /sys/class/drm/card0/device/pp_dpm_sclk | tail -1 | cut -d: -f1)
    local max_mclk=$(cat /sys/class/drm/card0/device/pp_dpm_mclk | tail -1 | cut -d: -f1)
    
    echo "$max_sclk" | sudo tee /sys/class/drm/card0/device/pp_dpm_sclk
    echo "$max_mclk" | sudo tee /sys/class/drm/card0/device/pp_dpm_mclk
    
    # Enable GPU fan control
    echo 1 | sudo tee /sys/class/drm/card0/device/hwmon/hwmon*/pwm1_enable 2>/dev/null || true
}

# Create gaming optimization script
cat > ~/.local/bin/gaming-optimizer << 'EOF'
#!/bin/bash
# Z13 Gaming Optimizer

start_gaming_mode() {
    echo "Enabling gaming optimizations..."
    
    # Switch to gaming TDP profile
    z13-tdp gaming
    
    # Set CPU to performance
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    
    # Optimize GPU
    optimize_amd_gpu_gaming
    
    # Disable CPU power saving
    echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/powersave_bias
    
    # Set I/O priority
    echo 1 | sudo tee /proc/sys/vm/page-cluster
    echo 15 | sudo tee /proc/sys/vm/dirty_background_ratio
    echo 25 | sudo tee /proc/sys/vm/dirty_ratio
    
    # Disable unnecessary services
    systemctl --user stop evolution-data-server 2>/dev/null || true
    systemctl --user stop tracker-miner-fs 2>/dev/null || true
    
    echo "Gaming mode enabled!"
}

stop_gaming_mode() {
    echo "Disabling gaming optimizations..."
    
    # Switch back to balanced profile
    z13-tdp balanced
    
    # Reset CPU governor
    echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    
    # Reset GPU to auto
    echo auto | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
    
    # Reset I/O settings
    echo 3 | sudo tee /proc/sys/vm/page-cluster
    echo 5 | sudo tee /proc/sys/vm/dirty_background_ratio
    echo 10 | sudo tee /proc/sys/vm/dirty_ratio
    
    # Re-enable services
    systemctl --user start evolution-data-server 2>/dev/null || true
    systemctl --user start tracker-miner-fs 2>/dev/null || true
    
    echo "Gaming mode disabled!"
}

case "$1" in
    "start"|"on")
        start_gaming_mode
        ;;
    "stop"|"off")
        stop_gaming_mode
        ;;
    *)
        echo "Usage: $0 {start|stop|on|off}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/gaming-optimizer
```

### Game-Specific Optimizations

```bash
# Steam optimization
optimize_steam() {
    # Enable Steam Play (Proton) for all titles
    echo "Enable Steam Play in Steam settings for Windows games"
    
    # Install performance libraries
    sudo pacman -S lib32-vulkan-radeon lib32-mesa lib32-vulkan-icd-loader
    
    # Create Steam launch options for better performance
    echo "Recommended Steam launch options for games:"
    echo "  General: gamemoderun %command%"
    echo "  Proton games: PROTON_USE_WINED3D=1 gamemoderun %command%"
    echo "  CPU-intensive: taskset -c 4-7 gamemoderun %command%"
}

# Lutris optimization  
optimize_lutris() {
    # Install Lutris and dependencies
    sudo pacman -S lutris wine-staging winetricks
    
    # Configure Wine for performance
    echo "Wine performance settings:"
    echo "1. Run winecfg"
    echo "2. Set Windows version to Windows 10"
    echo "3. In Graphics tab: Enable 'Automatically capture mouse in full-screen windows'"
    echo "4. Set video memory size to match your VRAM allocation"
}

# Native game optimization
optimize_native_games() {
    # Set library paths for better compatibility
    export LD_LIBRARY_PATH="/usr/lib32:/usr/lib:$LD_LIBRARY_PATH"
    
    # Enable gamemode for all games
    alias game='gamemoderun'
    
    # Create game launcher with optimizations
    cat > ~/.local/bin/game-launcher << 'GAME_LAUNCHER'
#!/bin/bash
# Optimized game launcher

# Enable gaming mode
gaming-optimizer start

# Set nice priority for game
nice -n -10 gamemoderun "$@"

# Wait for game to finish
wait

# Disable gaming mode
gaming-optimizer stop
GAME_LAUNCHER
    
    chmod +x ~/.local/bin/game-launcher
}
```

## 🌐 Network Optimization

### WiFi Performance Tuning

```bash
# Optimize MediaTek MT7925e WiFi performance
optimize_wifi() {
    # Apply stability fixes
    echo 'options mt7925e disable_aspm=1' | sudo tee /etc/modprobe.d/mt7925e.conf
    
    # Disable power saving
    sudo iwconfig wlan0 power off
    
    # Make power saving disable persistent
    cat > /etc/udev/rules.d/70-wifi-powersave.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/usr/bin/iw dev $name set power_save off"
EOF
    
    # Optimize WiFi for gaming
    sudo iw dev wlan0 set txpower fixed 2000  # 20dBm
    
    # Set optimal channel width (if supported)
    sudo iw dev wlan0 set channel 36 HT40+  # Use 5GHz with 40MHz width
}

# Network buffer optimization
optimize_network_buffers() {
    cat > /etc/sysctl.d/99-z13-network.conf << 'EOF'
# Z13 Network Performance Tuning

# TCP buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# TCP window scaling
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Reduce TCP latency
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3

# Network device queue optimization
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
EOF

    sudo sysctl -p /etc/sysctl.d/99-z13-network.conf
}
```

## 🔋 Battery Life Optimization

### Power Management Tuning

```bash
# Comprehensive battery optimization
optimize_battery_life() {
    # Switch to efficient TDP mode
    z13-tdp efficient
    
    # Enable TLP for advanced power management
    sudo systemctl enable tlp.service
    sudo systemctl start tlp.service
    
    # Configure TLP for maximum battery life
    cat > /etc/tlp.d/01-z13-battery.conf << 'EOF'
# Z13 Battery Optimization

# CPU scaling governor
CPU_SCALING_GOVERNOR_ON_AC=ondemand
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU energy performance preferences
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# CPU boost
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Turbo boost
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

# Platform profile
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power

# WiFi power saving
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Sound power saving
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=10

# Runtime PM
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB autosuspend
USB_AUTOSUSPEND=1

# Battery thresholds (if supported)
START_CHARGE_THRESH_BAT0=40
STOP_CHARGE_THRESH_BAT0=80
EOF
    
    # Apply TLP settings
    sudo tlp start
}

# Create battery monitoring script
cat > ~/.local/bin/battery-monitor << 'EOF'
#!/bin/bash
# Z13 Battery Monitor

check_battery_health() {
    local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
    local status=$(cat /sys/class/power_supply/BAT0/status)
    local health=$(cat /sys/class/power_supply/BAT0/health 2>/dev/null || echo "Unknown")
    
    echo "Battery Status: $status"
    echo "Battery Capacity: $capacity%"
    echo "Battery Health: $health"
    
    # Estimate remaining time
    if [[ "$status" == "Discharging" ]]; then
        local power_now=$(cat /sys/class/power_supply/BAT0/power_now)
        local energy_now=$(cat /sys/class/power_supply/BAT0/energy_now)
        
        if [[ $power_now -gt 0 ]]; then
            local hours=$((energy_now / power_now))
            local minutes=$(( (energy_now * 60 / power_now) % 60 ))
            echo "Estimated time remaining: ${hours}h ${minutes}m"
        fi
    fi
}

optimize_for_battery() {
    echo "Optimizing for maximum battery life..."
    
    # Switch to efficient mode
    z13-tdp efficient
    
    # Reduce screen brightness
    echo 30 | sudo tee /sys/class/backlight/*/brightness 2>/dev/null || true
    
    # Enable WiFi power saving
    sudo iw dev wlan0 set power_save on
    
    # Stop unnecessary services
    systemctl --user stop evolution-data-server 2>/dev/null || true
    systemctl --user stop tracker-miner-fs 2>/dev/null || true
    
    echo "Battery optimization enabled"
}

case "$1" in
    "status")
        check_battery_health
        ;;
    "optimize")
        optimize_for_battery
        ;;
    *)
        echo "Usage: $0 {status|optimize}"
        exit 1
        ;;
esac
EOF

chmod +x ~/.local/bin/battery-monitor
```

## 📊 Performance Monitoring

### Comprehensive Performance Dashboard

```bash
# Create performance monitoring dashboard
cat > ~/.local/bin/performance-dashboard << 'EOF'
#!/bin/bash
# Z13 Performance Dashboard

show_performance_status() {
    clear
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                Z13 Performance Dashboard                      ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo
    
    # TDP Status
    echo "🔋 Power Management:"
    z13-tdp status | head -5
    echo
    
    # CPU Status
    echo "🖥️  CPU Status:"
    echo "  Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    echo "  Frequency: $(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}') MHz"
    echo "  Temperature: $(sensors 2>/dev/null | grep -i "Tctl\|Package" | head -1 | awk '{print $2}' || echo "N/A")"
    echo "  Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
    echo
    
    # Memory Status
    echo "🧠 Memory Status:"
    free -h | grep -E "Mem|Swap"
    echo
    
    # GPU Status
    echo "🎮 GPU Status:"
    echo "  Power Level: $(cat /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || echo "N/A")"
    echo "  Profile: $(cat /sys/class/drm/card0/device/pp_power_profile_mode 2>/dev/null | grep -E "^\s*[0-9]+\s*\*" | awk '{print $2}' || echo "N/A")"
    echo
    
    # Storage Status
    echo "💾 Storage Status:"
    df -h / | tail -1 | awk '{print "  Root: " $3 " used, " $4 " free (" $5 " used)"}'
    echo "  I/O: $(iostat -d 1 1 2>/dev/null | grep -E "nvme|sd" | head -1 | awk '{print $4 "KB/s read, " $5 "KB/s write"}' || echo "N/A")"
    echo
    
    # Network Status
    echo "🌐 Network Status:"
    local interface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -n "$interface" ]]; then
        echo "  Interface: $interface"
        echo "  Status: $(cat /sys/class/net/$interface/operstate 2>/dev/null || echo "N/A")"
        if [[ "$interface" =~ ^wl ]]; then
            echo "  WiFi Power Save: $(iw dev $interface get power_save 2>/dev/null | awk '{print $3}' || echo "N/A")"
        fi
    fi
    echo
    
    # System Load
    echo "⚡ System Load:"
    uptime | awk -F'load average:' '{print "  Load:" $2}'
    echo "  Processes: $(ps aux | wc -l) total"
    echo
}

# Main loop
while true; do
    show_performance_status
    echo "Press 'q' to quit, 'r' to refresh, or wait 5 seconds for auto-refresh..."
    
    read -t 5 -n 1 key
    case "$key" in
        q|Q)
            echo "Exiting performance dashboard..."
            exit 0
            ;;
        r|R)
            continue
            ;;
        *)
            continue
            ;;
    esac
done
EOF

chmod +x ~/.local/bin/performance-dashboard
```

### Benchmarking Tools

```bash
# Install benchmarking tools
install_benchmark_tools() {
    sudo pacman -S sysbench stress-ng unigine-heaven phoronix-test-suite
    
    # Install additional tools
    yay -S geekbench
}

# CPU benchmark
benchmark_cpu() {
    echo "Running CPU benchmark..."
    sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run
}

# Memory benchmark
benchmark_memory() {
    echo "Running memory benchmark..."
    sysbench memory --memory-total-size=10G --threads=$(nproc) run
}

# Storage benchmark
benchmark_storage() {
    echo "Running storage benchmark..."
    sysbench fileio --file-total-size=5G prepare
    sysbench fileio --file-total-size=5G --file-test-mode=rndrw --threads=4 run
    sysbench fileio cleanup
}

# GPU benchmark
benchmark_gpu() {
    echo "Running GPU benchmark..."
    echo "Launch Unigine Heaven manually for GPU testing"
    unigine-heaven
}

# Comprehensive benchmark
run_full_benchmark() {
    echo "Starting comprehensive Z13 benchmark..."
    
    # Create results directory
    mkdir -p ~/benchmark-results/$(date +%Y%m%d-%H%M%S)
    cd ~/benchmark-results/$(date +%Y%m%d-%H%M%S)
    
    # System info
    echo "System Information:" > system-info.txt
    uname -a >> system-info.txt
    lscpu >> system-info.txt
    free -h >> system-info.txt
    lspci | grep VGA >> system-info.txt
    
    # Run benchmarks
    echo "CPU Benchmark Results:" > cpu-benchmark.txt
    benchmark_cpu >> cpu-benchmark.txt
    
    echo "Memory Benchmark Results:" > memory-benchmark.txt
    benchmark_memory >> memory-benchmark.txt
    
    echo "Storage Benchmark Results:" > storage-benchmark.txt
    benchmark_storage >> storage-benchmark.txt
    
    echo "Benchmark completed. Results saved in: $(pwd)"
}
```

## 🎯 Workload-Specific Optimizations

### Development Workloads

```bash
# Optimize for software development
optimize_for_development() {
    # Balanced TDP for sustained performance
    z13-tdp balanced
    
    # Optimize for compilation workloads
    export MAKEFLAGS="-j$(nproc)"
    export CARGO_BUILD_JOBS=$(nproc)
    
    # Configure ccache for faster compilation
    export CCACHE_DIR="$HOME/.ccache"
    export CCACHE_MAXSIZE="5G"
    
    # Optimize memory for large projects
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.d/99-z13-dev.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.d/99-z13-dev.conf
    
    sudo sysctl -p /etc/sysctl.d/99-z13-dev.conf
}

# Docker optimization
optimize_docker() {
    # Configure Docker for better performance
    cat > /etc/docker/daemon.json << 'EOF'
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "default-runtime": "runc",
    "runtimes": {
        "runc": {
            "path": "runc"
        }
    },
    "exec-opts": ["native.cgroupdriver=systemd"],
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF
    
    sudo systemctl restart docker
}
```

### AI/ML Workloads

```bash
# Optimize for AI/ML workloads
optimize_for_ai_ml() {
    # High TDP for intensive computation
    z13-tdp ai
    
    # Maximize GPU memory allocation
    echo "Configure BIOS for maximum VRAM allocation (8-12GB recommended)"
    
    # Install ROCm for AMD GPU compute
    sudo pacman -S rocm-opencl-runtime rocm-cmake rocblas
    
    # Set environment variables for ROCm
    export HSA_OVERRIDE_GFX_VERSION=11.0.0
    export ROCM_PATH=/opt/rocm
    
    # Optimize memory for large datasets
    echo 'vm.overcommit_memory=1' | sudo tee -a /etc/sysctl.d/99-z13-ai.conf
    echo 'vm.overcommit_ratio=90' | sudo tee -a /etc/sysctl.d/99-z13-ai.conf
    
    sudo sysctl -p /etc/sysctl.d/99-z13-ai.conf
}

# PyTorch optimization
optimize_pytorch() {
    # Set PyTorch environment variables
    export TORCH_USE_CUDA_DSA=1
    export PYTORCH_HIP_ALLOC_CONF=max_split_size_mb:128
    
    # Install optimized PyTorch for ROCm
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.6
}
```

### Media/Content Creation

```bash
# Optimize for media workloads
optimize_for_media() {
    # Balanced performance for sustained workloads
    z13-tdp performance
    
    # Install media codecs and hardware acceleration
    sudo pacman -S ffmpeg x264 x265 libva-mesa-driver mesa-vdpau
    
    # Configure hardware acceleration
    export VAAPI_MPEG4_ENABLED=true
    export LIBVA_DRIVER_NAME=radeonsi
    
    # Optimize for video editing
    echo 'vm.dirty_background_ratio=5' | sudo tee -a /etc/sysctl.d/99-z13-media.conf
    echo 'vm.dirty_ratio=10' | sudo tee -a /etc/sysctl.d/99-z13-media.conf
    
    sudo sysctl -p /etc/sysctl.d/99-z13-media.conf
}
```

## 🔧 Advanced Tuning Techniques

### CPU Microcode and Firmware

```bash
# Update CPU microcode
update_microcode() {
    sudo pacman -S amd-ucode
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    echo "Microcode updated. Reboot required."
}

# Check microcode version
check_microcode() {
    dmesg | grep microcode
    cat /proc/cpuinfo | grep microcode | head -1
}
```

### Kernel Parameter Optimization

```bash
# Add performance-oriented kernel parameters
optimize_kernel_parameters() {
    local grub_params="amd_pstate=active processor.max_cstate=1 intel_idle.max_cstate=0 idle=poll mitigations=off"
    
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/&$grub_params /" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    echo "Kernel parameters updated. Reboot required for changes to take effect."
    echo "Added parameters: $grub_params"
}
```

### Custom Performance Profiles

```bash
# Create custom performance profiles
create_performance_profiles() {
    # Gaming profile
    cat > ~/.local/bin/profile-gaming << 'EOF'
#!/bin/bash
z13-tdp gaming
gaming-optimizer start
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
optimize_amd_gpu_gaming
EOF
    
    # Productivity profile
    cat > ~/.local/bin/profile-productivity << 'EOF'
#!/bin/bash
z13-tdp balanced
echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
configure_amd_pstate "balance_performance"
EOF
    
    # Battery profile
    cat > ~/.local/bin/profile-battery << 'EOF'
#!/bin/bash
z13-tdp efficient
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
configure_amd_pstate "power"
battery-monitor optimize
EOF
    
    chmod +x ~/.local/bin/profile-*
}
```

## 📈 Performance Validation

### Performance Testing Protocol

```bash
# Complete performance validation
validate_optimizations() {
    echo "=== Z13 Performance Validation ==="
    
    # Baseline measurements
    echo "1. Running baseline tests..."
    benchmark_cpu > baseline-cpu.txt
    benchmark_memory > baseline-memory.txt
    benchmark_storage > baseline-storage.txt
    
    # Temperature monitoring
    echo "2. Monitoring temperatures..."
    sensors > temperatures-idle.txt
    
    # Stress testing
    echo "3. Running stress tests..."
    stress-ng --cpu $(nproc) --timeout 60s &
    sleep 30
    sensors > temperatures-load.txt
    wait
    
    # Power consumption
    echo "4. Measuring power consumption..."
    powertop --time=30 > power-consumption.txt
    
    echo "Validation complete. Check generated files for results."
}
```

## 🎯 Quick Reference

### Essential Commands
```bash
# TDP Management
z13-tdp status          # Check current TDP
z13-tdp gaming          # Gaming mode
z13-tdp efficient       # Battery saving
z13-tdp custom 60       # Custom TDP

# Performance Monitoring
performance-dashboard   # Real-time dashboard
z13-performance-monitor status
htop                   # Process monitor
sensors                # Temperature monitor

# Optimization Scripts
gaming-optimizer start  # Enable gaming mode
battery-monitor optimize # Battery optimization
profile-gaming          # Gaming profile
profile-productivity    # Work profile
profile-battery         # Battery profile

# System Information
z13-health-monitor check # System health
z13-recovery hardware   # Hardware info
uname -a               # Kernel info
lscpu                  # CPU info
```

### Performance Targets

| Workload | TDP | Expected Performance | Battery Life |
|----------|-----|---------------------|--------------|
| **Web Browsing** | 7-15W | Smooth, responsive | 8-12 hours |
| **Development** | 25-45W | Fast compilation | 4-6 hours |
| **Gaming** | 65-93W | 60+ FPS (1080p) | 1.5-2.5 hours |
| **AI/ML** | 45-75W | GPU acceleration | 2-4 hours |
| **Media Editing** | 45-85W | Real-time preview | 2-3 hours |

Remember to monitor temperatures and adjust TDP accordingly to prevent thermal throttling!
