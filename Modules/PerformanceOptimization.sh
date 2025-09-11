#!/bin/bash
# Performance Optimization Module
# Advanced performance tuning for ASUS ROG Flow Z13 (2025) - AMD Strix Halo

performance_optimization_setup() {
    PrintHeader "Performance Optimization Configuration"
    
    if [[ "$ENABLE_PERFORMANCE_OPTIMIZATION" != "true" ]]; then
        PrintStatus "Performance optimization disabled in configuration, skipping..."
        return 0
    fi
    
    PrintStatus "Implementing comprehensive performance optimizations..."
    
    # Install performance monitoring and tuning packages
    InstallPackageGroupWithVerification cpupower thermald irqbalance chroot
    InstallPackageGroupWithVerification powertop iotop htop btop chroot
    InstallPackageGroupWithVerification perf sysstat numactl chroot
    InstallPackageGroupWithVerification tuned gamemode lib32-gamemode chroot
    
    # Configure CPU performance
    configure_cpu_optimization
    
    # Configure memory optimization
    configure_memory_optimization
    
    # Configure I/O optimization
    configure_io_optimization
    
    # Configure GPU optimization
    configure_gpu_optimization
    
    # Configure system-wide performance profiles
    configure_performance_profiles
    
    # Configure gaming optimizations
    configure_gaming_optimization
    
    # Configure thermal management
    configure_thermal_optimization
    
    # Create performance monitoring system
    create_performance_monitoring
    
    PrintStatus "Performance optimization configuration completed"
}

configure_cpu_optimization() {
    PrintStatus "Configuring CPU performance optimization..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create CPU performance configuration
cat > /etc/systemd/system/z13-cpu-performance.service << 'CPU_SERVICE'
[Unit]
Description=Z13 CPU Performance Optimization
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/z13-cpu-optimizer
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
CPU_SERVICE

# Create CPU optimizer script
cat > /usr/local/bin/z13-cpu-optimizer << 'CPU_OPTIMIZER'
#!/bin/bash
# Z13 CPU Performance Optimizer

LOG_FILE="/var/log/z13-performance.log"

log_performance() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Detect CPU capabilities
detect_cpu_features() {
    local features=""
    
    # Check for AMD Strix Halo specific features
    if grep -q "AuthenticAMD" /proc/cpuinfo; then
        features+="AMD "
        
        # Check for specific AMD features
        if grep -q "avx2" /proc/cpuinfo; then
            features+="AVX2 "
        fi
        if grep -q "fma" /proc/cpuinfo; then
            features+="FMA "
        fi
        if grep -q "rdrand" /proc/cpuinfo; then
            features+="RDRAND "
        fi
    fi
    
    log_performance "CPU features detected: $features"
    echo "$features"
}

# Configure CPU governor based on power source
configure_cpu_governor() {
    local power_source="battery"
    
    # Check if on AC power
    if [ -f /sys/class/power_supply/ADP*/online ]; then
        local ac_online=$(cat /sys/class/power_supply/ADP*/online 2>/dev/null | head -1)
        if [ "$ac_online" = "1" ]; then
            power_source="ac"
        fi
    fi
    
    # Set governor based on power source
    if [ "$power_source" = "ac" ]; then
        # AC power - use performance governor
        cpupower frequency-set -g performance
        log_performance "Set CPU governor to performance (AC power)"
    else
        # Battery power - use powersave governor
        cpupower frequency-set -g powersave
        log_performance "Set CPU governor to powersave (battery power)"
    fi
}

# Configure CPU frequency scaling
configure_cpu_scaling() {
    # Set scaling parameters for AMD Strix Halo
    echo 10 > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold 2>/dev/null || true
    echo 5 > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor 2>/dev/null || true
    
    # Configure AMD P-State driver if available
    if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        local driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null)
        if [ "$driver" = "amd-pstate" ] || [ "$driver" = "amd-pstate-epp" ]; then
            # Configure AMD P-State EPP (Energy Performance Preference)
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
                if [ -f "$cpu" ]; then
                    echo "balance_performance" > "$cpu" 2>/dev/null || true
                fi
            done
            log_performance "Configured AMD P-State EPP to balance_performance"
        fi
    fi
}

# Configure CPU cache optimization
configure_cpu_cache() {
    # Enable CPU cache prefetching optimizations
    if [ -f /sys/devices/system/cpu/cpu0/cache/index*/prefetch_distance ]; then
        for cache in /sys/devices/system/cpu/cpu*/cache/index*/prefetch_distance; do
            echo 64 > "$cache" 2>/dev/null || true
        done
        log_performance "Configured CPU cache prefetch distance"
    fi
}

# Configure IRQ affinity for better performance
configure_irq_affinity() {
    # Enable irqbalance for automatic IRQ distribution
    systemctl enable irqbalance.service
    
    # Configure irqbalance for gaming/performance
    cat > /etc/sysconfig/irqbalance << 'IRQ_CONFIG'
# IRQ balance configuration for Z13 performance
IRQBALANCE_ARGS="--policyscript=/usr/local/bin/z13-irq-policy"
IRQ_CONFIG

    # Create IRQ policy script
    cat > /usr/local/bin/z13-irq-policy << 'IRQ_POLICY'
#!/bin/bash
# Z13 IRQ affinity policy for performance

# Get CPU count
CPU_COUNT=$(nproc)

# Assign network IRQs to specific cores
case "$1" in
    "network")
        # Assign network IRQs to cores 0-3 for low latency
        echo "mask 0f"
        ;;
    "storage")
        # Assign storage IRQs to cores 4-7
        echo "mask f0"
        ;;
    *)
        # Default: let irqbalance decide
        echo "ignore"
        ;;
esac
IRQ_POLICY

    chmod +x /usr/local/bin/z13-irq-policy
    log_performance "Configured IRQ affinity optimization"
}

# Main optimization execution
main() {
    log_performance "Starting CPU performance optimization"
    
    detect_cpu_features
    configure_cpu_governor
    configure_cpu_scaling
    configure_cpu_cache
    configure_irq_affinity
    
    log_performance "CPU performance optimization completed"
}

main "$@"
CPU_OPTIMIZER

chmod +x /usr/local/bin/z13-cpu-optimizer

# Enable the service
systemctl enable z13-cpu-performance.service

PrintStatus "CPU performance optimization configured"
EOF
}

configure_memory_optimization() {
    PrintStatus "Configuring memory optimization..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create memory optimization configuration
cat > /etc/sysctl.d/99-z13-memory.conf << 'MEMORY_CONFIG'
# Z13 Memory Performance Optimization

# Virtual memory tuning for 32GB+ systems
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# Memory allocation optimization
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.min_free_kbytes = 131072

# Transparent Huge Pages optimization for Strix Halo
vm.nr_hugepages = 0
kernel.mm.transparent_hugepage.enabled = madvise
kernel.mm.transparent_hugepage.defrag = madvise

# Memory compaction
vm.compaction_proactiveness = 20
vm.watermark_boost_factor = 15000
vm.watermark_scale_factor = 10

# NUMA optimization (if applicable)
kernel.numa_balancing = 1
kernel.numa_balancing_scan_delay_ms = 1000
kernel.numa_balancing_scan_period_min_ms = 1000
kernel.numa_balancing_scan_period_max_ms = 60000

# Memory zone optimization
vm.zone_reclaim_mode = 0
vm.lowmem_reserve_ratio = 256 256 32 0 0

# Page allocation optimization
vm.percpu_pagelist_fraction = 0
vm.page_cluster = 3
MEMORY_CONFIG

# Create memory monitoring script
cat > /usr/local/bin/z13-memory-monitor << 'MEMORY_MONITOR'
#!/bin/bash
# Z13 Memory Performance Monitor

LOG_FILE="/var/log/z13-memory.log"

log_memory() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_memory_pressure() {
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local mem_usage=$((100 - (mem_available * 100 / mem_total)))
    
    if [ $mem_usage -gt 90 ]; then
        log_memory "HIGH MEMORY PRESSURE: ${mem_usage}% used"
        # Trigger memory cleanup
        echo 3 > /proc/sys/vm/drop_caches
        log_memory "Dropped caches to free memory"
    elif [ $mem_usage -gt 80 ]; then
        log_memory "MODERATE MEMORY PRESSURE: ${mem_usage}% used"
    fi
}

check_swap_usage() {
    local swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    if [ $swap_total -gt 0 ]; then
        local swap_used=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        local swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2}')
        local swap_usage=$((100 - (swap_free * 100 / swap_total)))
        
        if [ $swap_usage -gt 50 ]; then
            log_memory "HIGH SWAP USAGE: ${swap_usage}% used"
        fi
    fi
}

optimize_memory() {
    # Compact memory if fragmentation is high
    echo 1 > /proc/sys/vm/compact_memory 2>/dev/null || true
    
    # Sync and drop caches if memory pressure is high
    local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_usage=$((100 - (mem_available * 100 / mem_total)))
    
    if [ $mem_usage -gt 85 ]; then
        sync
        echo 1 > /proc/sys/vm/drop_caches
        log_memory "Dropped page cache due to high memory usage"
    fi
}

case "$1" in
    "check")
        check_memory_pressure
        check_swap_usage
        ;;
    "optimize")
        optimize_memory
        ;;
    "status")
        echo "Memory Status:"
        free -h
        echo ""
        echo "Recent memory events:"
        tail -10 "$LOG_FILE" 2>/dev/null || echo "No memory events logged"
        ;;
    *)
        echo "Usage: $0 {check|optimize|status}"
        exit 1
        ;;
esac
MEMORY_MONITOR

chmod +x /usr/local/bin/z13-memory-monitor

PrintStatus "Memory optimization configured"
EOF
}

configure_io_optimization() {
    PrintStatus "Configuring I/O optimization..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create I/O optimization script
cat > /usr/local/bin/z13-io-optimizer << 'IO_OPTIMIZER'
#!/bin/bash
# Z13 I/O Performance Optimizer

LOG_FILE="/var/log/z13-io.log"

log_io() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Detect storage devices and optimize schedulers
optimize_io_schedulers() {
    for device in /sys/block/*/queue/scheduler; do
        local block_device=$(echo $device | cut -d'/' -f4)
        local device_path="/dev/$block_device"
        
        # Skip loop and virtual devices
        if [[ $block_device =~ ^(loop|ram|dm-) ]]; then
            continue
        fi
        
        # Detect device type
        local is_ssd=false
        local is_nvme=false
        
        if [[ $block_device =~ ^nvme ]]; then
            is_nvme=true
            is_ssd=true
        elif [ -f "/sys/block/$block_device/queue/rotational" ]; then
            local rotational=$(cat "/sys/block/$block_device/queue/rotational")
            if [ "$rotational" = "0" ]; then
                is_ssd=true
            fi
        fi
        
        # Set optimal scheduler
        local optimal_scheduler="mq-deadline"
        
        if $is_nvme; then
            optimal_scheduler="none"
        elif $is_ssd; then
            optimal_scheduler="mq-deadline"
        else
            optimal_scheduler="bfq"
        fi
        
        # Check if scheduler is available
        if grep -q "$optimal_scheduler" "$device"; then
            echo "$optimal_scheduler" > "$device"
            log_io "Set $optimal_scheduler scheduler for $block_device"
        fi
        
        # Optimize queue parameters
        local queue_dir="/sys/block/$block_device/queue"
        
        if $is_ssd; then
            # SSD optimizations
            echo 0 > "$queue_dir/add_random" 2>/dev/null || true
            echo 256 > "$queue_dir/nr_requests" 2>/dev/null || true
            echo 0 > "$queue_dir/rq_affinity" 2>/dev/null || true
        else
            # HDD optimizations
            echo 1 > "$queue_dir/add_random" 2>/dev/null || true
            echo 128 > "$queue_dir/nr_requests" 2>/dev/null || true
            echo 1 > "$queue_dir/rq_affinity" 2>/dev/null || true
        fi
        
        # Set read-ahead for better sequential performance
        if $is_ssd; then
            echo 128 > "$queue_dir/read_ahead_kb" 2>/dev/null || true
        else
            echo 512 > "$queue_dir/read_ahead_kb" 2>/dev/null || true
        fi
    done
}

# Configure filesystem mount options for performance
optimize_filesystem_options() {
    # Create optimized fstab entries for common filesystems
    if grep -q "ext4" /proc/mounts; then
        log_io "Detected ext4 filesystem - recommending performance mount options"
        # Note: This would be applied during mount in fstab
        # noatime,commit=60,barrier=0 for ext4 performance
    fi
    
    if grep -q "btrfs" /proc/mounts; then
        log_io "Detected btrfs filesystem - recommending performance mount options"
        # Note: noatime,compress=zstd,space_cache=v2 for btrfs performance
    fi
    
    if grep -q "zfs" /proc/mounts; then
        log_io "Detected ZFS filesystem - optimizing ZFS parameters"
        # ZFS-specific optimizations would be handled by ZFS module
    fi
}

# Optimize I/O for gaming and high-performance workloads
configure_gaming_io() {
    # Increase I/O priority for gaming processes
    cat > /etc/systemd/system/z13-gaming-io.service << 'GAMING_IO_SERVICE'
[Unit]
Description=Z13 Gaming I/O Optimization
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/z13-gaming-io-setup
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
GAMING_IO_SERVICE

    cat > /usr/local/bin/z13-gaming-io-setup << 'GAMING_IO_SETUP'
#!/bin/bash
# Gaming I/O optimization setup

# Increase I/O bandwidth for gaming
echo 10 > /proc/sys/vm/dirty_background_ratio 2>/dev/null || true
echo 20 > /proc/sys/vm/dirty_ratio 2>/dev/null || true
echo 1500 > /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null || true
echo 1500 > /proc/sys/vm/dirty_expire_centisecs 2>/dev/null || true

# Optimize for low-latency I/O
echo 1 > /proc/sys/vm/page-cluster 2>/dev/null || true

echo "Gaming I/O optimization applied"
GAMING_IO_SETUP

    chmod +x /usr/local/bin/z13-gaming-io-setup
    systemctl enable z13-gaming-io.service
}

# Main I/O optimization
main() {
    log_io "Starting I/O performance optimization"
    
    optimize_io_schedulers
    optimize_filesystem_options
    configure_gaming_io
    
    log_io "I/O performance optimization completed"
}

main "$@"
IO_OPTIMIZER

chmod +x /usr/local/bin/z13-io-optimizer

# Create I/O optimization service
cat > /etc/systemd/system/z13-io-optimization.service << 'IO_SERVICE'
[Unit]
Description=Z13 I/O Performance Optimization
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/z13-io-optimizer
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
IO_SERVICE

systemctl enable z13-io-optimization.service

PrintStatus "I/O optimization configured"
EOF
}

configure_gpu_optimization() {
    PrintStatus "Configuring GPU optimization..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create GPU optimization script
cat > /usr/local/bin/z13-gpu-optimizer << 'GPU_OPTIMIZER'
#!/bin/bash
# Z13 GPU Performance Optimizer (AMD Strix Halo)

LOG_FILE="/var/log/z13-gpu.log"

log_gpu() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Configure AMD GPU performance
configure_amd_gpu() {
    # Check if AMD GPU is present
    if lspci | grep -i "amd.*vga\|amd.*display" >/dev/null; then
        log_gpu "AMD GPU detected - configuring performance settings"
        
        # Set GPU performance mode
        if [ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
            echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
            log_gpu "Set GPU to high performance mode"
        fi
        
        # Configure GPU memory clock
        if [ -f /sys/class/drm/card0/device/pp_dpm_mclk ]; then
            # Enable highest memory clock state
            local max_state=$(cat /sys/class/drm/card0/device/pp_dpm_mclk | tail -1 | cut -d: -f1)
            echo "$max_state" > /sys/class/drm/card0/device/pp_dpm_mclk 2>/dev/null || true
            log_gpu "Set GPU memory clock to maximum state: $max_state"
        fi
        
        # Configure GPU core clock
        if [ -f /sys/class/drm/card0/device/pp_dpm_sclk ]; then
            # Enable highest core clock state
            local max_state=$(cat /sys/class/drm/card0/device/pp_dpm_sclk | tail -1 | cut -d: -f1)
            echo "$max_state" > /sys/class/drm/card0/device/pp_dpm_sclk 2>/dev/null || true
            log_gpu "Set GPU core clock to maximum state: $max_state"
        fi
    fi
}

# Configure GPU power management
configure_gpu_power() {
    # Set GPU power profile for performance
    if [ -f /sys/class/drm/card0/device/pp_power_profile_mode ]; then
        # Set to 3D_FULL_SCREEN profile for gaming
        echo "1" > /sys/class/drm/card0/device/pp_power_profile_mode 2>/dev/null || true
        log_gpu "Set GPU power profile to 3D_FULL_SCREEN"
    fi
    
    # Configure GPU fan curve for better cooling
    if [ -f /sys/class/drm/card0/device/hwmon/hwmon*/pwm1_enable ]; then
        echo "1" > /sys/class/drm/card0/device/hwmon/hwmon*/pwm1_enable 2>/dev/null || true
        log_gpu "Enabled manual GPU fan control"
    fi
}

# Configure VRAM allocation for Strix Halo
configure_vram_allocation() {
    # Strix Halo can allocate significant system RAM as VRAM
    # This is typically configured in BIOS, but we can optimize for it
    
    local total_mem=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    log_gpu "Total system memory: ${total_mem}MB"
    
    # Recommend VRAM allocation based on total memory
    if [ $total_mem -gt 32000 ]; then
        log_gpu "High memory system detected - recommend 8-12GB VRAM allocation in BIOS"
    elif [ $total_mem -gt 16000 ]; then
        log_gpu "Medium memory system detected - recommend 4-6GB VRAM allocation in BIOS"
    else
        log_gpu "Low memory system detected - recommend 2-4GB VRAM allocation in BIOS"
    fi
}

# Main GPU optimization
main() {
    log_gpu "Starting GPU performance optimization"
    
    configure_amd_gpu
    configure_gpu_power
    configure_vram_allocation
    
    log_gpu "GPU performance optimization completed"
}

main "$@"
GPU_OPTIMIZER

chmod +x /usr/local/bin/z13-gpu-optimizer

PrintStatus "GPU optimization configured"
EOF
}

configure_performance_profiles() {
    PrintStatus "Configuring system-wide performance profiles..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Install and configure tuned for performance profiles
systemctl enable tuned.service

# Create custom Z13 performance profiles
mkdir -p /etc/tuned/z13-performance
cat > /etc/tuned/z13-performance/tuned.conf << 'PERFORMANCE_PROFILE'
[main]
summary=Z13 High Performance Profile
include=throughput-performance

[cpu]
governor=performance
energy_perf_bias=performance
min_perf_pct=80

[sysctl]
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
kernel.sched_min_granularity_ns=10000000
kernel.sched_wakeup_granularity_ns=15000000

[disk]
readahead=4096
PERFORMANCE_PROFILE

mkdir -p /etc/tuned/z13-balanced
cat > /etc/tuned/z13-balanced/tuned.conf << 'BALANCED_PROFILE'
[main]
summary=Z13 Balanced Performance Profile
include=balanced

[cpu]
governor=ondemand
energy_perf_bias=normal
min_perf_pct=20

[sysctl]
vm.swappiness=30
vm.dirty_ratio=10
vm.dirty_background_ratio=5

[disk]
readahead=2048
BALANCED_PROFILE

mkdir -p /etc/tuned/z13-powersave
cat > /etc/tuned/z13-powersave/tuned.conf << 'POWERSAVE_PROFILE'
[main]
summary=Z13 Power Save Profile
include=powersave

[cpu]
governor=powersave
energy_perf_bias=powersave
min_perf_pct=5

[sysctl]
vm.swappiness=60
vm.dirty_ratio=5
vm.dirty_background_ratio=2

[disk]
readahead=1024
POWERSAVE_PROFILE

# Set default profile to balanced
tuned-adm profile z13-balanced

PrintStatus "Performance profiles configured"
EOF
}

configure_gaming_optimization() {
    PrintStatus "Configuring gaming-specific optimizations..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Configure gamemode for gaming optimization
cat > /etc/gamemode.ini << 'GAMEMODE_CONFIG'
[general]
renice=10
ioprio=1
inhibit_screensaver=1
softrealtime=on
reaper_freq=5

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high

[cpu]
pin_cores=0-3
park_cores=4-7
cpu_governor=performance
cpu_min_freq=2000000

[custom]
start=z13-gaming-start
end=z13-gaming-end
GAMEMODE_CONFIG

# Create gaming optimization scripts
cat > /usr/local/bin/z13-gaming-start << 'GAMING_START'
#!/bin/bash
# Z13 Gaming Session Start

LOG_FILE="/var/log/z13-gaming.log"

log_gaming() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_gaming "Gaming session started"

# Switch to performance profile
tuned-adm profile z13-performance

# Set high TDP if on AC power
if [ -f /sys/class/power_supply/ADP*/online ]; then
    local ac_online=$(cat /sys/class/power_supply/ADP*/online 2>/dev/null | head -1)
    if [ "$ac_online" = "1" ]; then
        /usr/local/bin/z13-tdp gaming
        log_gaming "Set gaming TDP profile"
    fi
fi

# Optimize GPU
/usr/local/bin/z13-gpu-optimizer

# Set CPU to performance mode
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null

# Increase I/O priority
echo 1 > /proc/sys/vm/page-cluster
echo 15 > /proc/sys/vm/dirty_background_ratio
echo 25 > /proc/sys/vm/dirty_ratio

log_gaming "Gaming optimizations applied"
GAMING_START

cat > /usr/local/bin/z13-gaming-end << 'GAMING_END'
#!/bin/bash
# Z13 Gaming Session End

LOG_FILE="/var/log/z13-gaming.log"

log_gaming() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_gaming "Gaming session ended"

# Switch back to balanced profile
tuned-adm profile z13-balanced

# Reset TDP to balanced
/usr/local/bin/z13-tdp balanced

# Reset CPU governor to ondemand
echo ondemand | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null

# Reset I/O settings
echo 3 > /proc/sys/vm/page-cluster
echo 5 > /proc/sys/vm/dirty_background_ratio
echo 10 > /proc/sys/vm/dirty_ratio

log_gaming "Gaming optimizations reset"
GAMING_END

chmod +x /usr/local/bin/z13-gaming-start
chmod +x /usr/local/bin/z13-gaming-end

PrintStatus "Gaming optimization configured"
EOF
}

configure_thermal_optimization() {
    PrintStatus "Configuring thermal management optimization..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Configure thermald for intelligent thermal management
systemctl enable thermald.service

# Create Z13-specific thermal configuration
cat > /etc/thermald/thermal-conf.xml << 'THERMAL_CONFIG'
<?xml version="1.0"?>
<ThermalConfiguration>
  <Platform>
    <Name>ASUS ROG Flow Z13 2025</Name>
    <ProductName>*Z13*</ProductName>
    <Preference>QUIET</Preference>
    <ThermalZones>
      <ThermalZone>
        <Type>cpu</Type>
        <TripPoints>
          <TripPoint>
            <SensorType>cpu</SensorType>
            <Temperature>70000</Temperature>
            <type>passive</type>
            <CoolingDevice>
              <index>1</index>
              <type>intel_pstate</type>
              <influence>100</influence>
              <SamplingPeriod>1</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <TripPoint>
            <SensorType>cpu</SensorType>
            <Temperature>85000</Temperature>
            <type>passive</type>
            <CoolingDevice>
              <index>2</index>
              <type>Processor</type>
              <influence>100</influence>
              <SamplingPeriod>1</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>
    </ThermalZones>
  </Platform>
</ThermalConfiguration>
THERMAL_CONFIG

PrintStatus "Thermal management optimization configured"
EOF
}

create_performance_monitoring() {
    PrintStatus "Creating performance monitoring system..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create comprehensive performance monitoring script
cat > /usr/local/bin/z13-performance-monitor << 'PERF_MONITOR'
#!/bin/bash
# Z13 Performance Monitoring System

LOG_FILE="/var/log/z13-performance-monitor.log"
METRICS_FILE="/var/log/z13-metrics.log"

log_perf() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

collect_metrics() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local cpu_temp=$(sensors 2>/dev/null | grep -i "core 0" | awk '{print $3}' | cut -d'+' -f2 | cut -d'°' -f1 | head -1)
    local cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')
    
    # Memory metrics
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
    local mem_usage=$((100 - (mem_available * 100 / mem_total)))
    
    # I/O metrics
    local io_read=$(iostat -d 1 1 2>/dev/null | grep -v "^$" | tail -1 | awk '{print $3}')
    local io_write=$(iostat -d 1 1 2>/dev/null | grep -v "^$" | tail -1 | awk '{print $4}')
    
    # Power metrics
    local power_source="battery"
    if [ -f /sys/class/power_supply/ADP*/online ]; then
        local ac_online=$(cat /sys/class/power_supply/ADP*/online 2>/dev/null | head -1)
        if [ "$ac_online" = "1" ]; then
            power_source="ac"
        fi
    fi
    
    # Log metrics
    echo "$timestamp,CPU:${cpu_usage}%,TEMP:${cpu_temp}C,FREQ:${cpu_freq}MHz,MEM:${mem_usage}%,IO_R:${io_read},IO_W:${io_write},POWER:$power_source" >> "$METRICS_FILE"
}

analyze_performance() {
    echo "=== Z13 Performance Analysis ==="
    echo "Generated: $(date)"
    echo ""
    
    # CPU analysis
    echo "CPU Performance:"
    local avg_cpu=$(tail -100 "$METRICS_FILE" 2>/dev/null | cut -d',' -f2 | cut -d':' -f2 | cut -d'%' -f1 | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print "N/A"}')
    echo "  Average CPU Usage: ${avg_cpu}%"
    
    local max_temp=$(tail -100 "$METRICS_FILE" 2>/dev/null | cut -d',' -f3 | cut -d':' -f2 | cut -d'C' -f1 | sort -n | tail -1)
    echo "  Maximum Temperature: ${max_temp}°C"
    
    # Memory analysis
    echo ""
    echo "Memory Performance:"
    local avg_mem=$(tail -100 "$METRICS_FILE" 2>/dev/null | cut -d',' -f5 | cut -d':' -f2 | cut -d'%' -f1 | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print "N/A"}')
    echo "  Average Memory Usage: ${avg_mem}%"
    
    # Power analysis
    echo ""
    echo "Power Analysis:"
    local ac_count=$(tail -100 "$METRICS_FILE" 2>/dev/null | cut -d',' -f7 | grep -c "POWER:ac")
    local battery_count=$(tail -100 "$METRICS_FILE" 2>/dev/null | cut -d',' -f7 | grep -c "POWER:battery")
    echo "  AC Power: $ac_count samples"
    echo "  Battery Power: $battery_count samples"
    
    # Performance recommendations
    echo ""
    echo "Recommendations:"
    if (( $(echo "$avg_cpu > 80" | bc -l 2>/dev/null || echo 0) )); then
        echo "  - High CPU usage detected. Consider closing unnecessary applications."
    fi
    if (( $(echo "$max_temp > 80" | bc -l 2>/dev/null || echo 0) )); then
        echo "  - High temperatures detected. Check thermal throttling and cooling."
    fi
    if (( $(echo "$avg_mem > 85" | bc -l 2>/dev/null || echo 0) )); then
        echo "  - High memory usage detected. Consider increasing swap or closing applications."
    fi
}

case "$1" in
    "collect")
        collect_metrics
        ;;
    "analyze")
        analyze_performance
        ;;
    "status")
        echo "Recent performance metrics:"
        tail -10 "$METRICS_FILE" 2>/dev/null | column -t -s',' || echo "No metrics available"
        ;;
    *)
        echo "Usage: $0 {collect|analyze|status}"
        exit 1
        ;;
esac
PERF_MONITOR

chmod +x /usr/local/bin/z13-performance-monitor

# Create performance monitoring service and timer
cat > /etc/systemd/system/z13-performance-collect.service << 'PERF_SERVICE'
[Unit]
Description=Z13 Performance Metrics Collection
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-performance-monitor collect
StandardOutput=journal
StandardError=journal
PERF_SERVICE

cat > /etc/systemd/system/z13-performance-collect.timer << 'PERF_TIMER'
[Unit]
Description=Collect Z13 performance metrics every 5 minutes
Requires=z13-performance-collect.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
PERF_TIMER

systemctl enable z13-performance-collect.timer

PrintStatus "Performance monitoring system created"
EOF
}

# Export functions for use by main script
export -f performance_optimization_setup
export -f configure_cpu_optimization
export -f configure_memory_optimization
export -f configure_io_optimization
export -f configure_gpu_optimization
export -f configure_performance_profiles
export -f configure_gaming_optimization
export -f configure_thermal_optimization
export -f create_performance_monitoring
