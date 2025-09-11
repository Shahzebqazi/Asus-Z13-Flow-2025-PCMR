#!/bin/bash
# System Monitoring Module
# Comprehensive monitoring, health checks, and alerting for ASUS ROG Flow Z13 (2025)

system_monitoring_setup() {
    PrintHeader "System Monitoring Configuration"
    
    if [[ "$ENABLE_SYSTEM_MONITORING" != "true" ]]; then
        PrintStatus "System monitoring disabled in configuration, skipping..."
        return 0
    fi
    
    PrintStatus "Implementing comprehensive system monitoring..."
    
    # Install monitoring packages with verification
    InstallPackageGroupWithVerification htop btop iotop nethogs chroot
    InstallPackageGroupWithVerification sysstat lm_sensors smartmontools chroot
    InstallPackageGroupWithVerification collectd telegraf prometheus-node-exporter chroot
    
    # Configure system health monitoring
    configure_health_monitoring
    
    # Configure performance monitoring
    configure_performance_monitoring
    
    # Configure hardware monitoring
    configure_hardware_monitoring
    
    # Configure alerting system
    configure_alerting_system
    
    # Configure log monitoring
    configure_log_monitoring
    
    # Configure web dashboard
    configure_web_dashboard
    
    # Create monitoring services
    create_monitoring_services
    
    PrintStatus "System monitoring configuration completed"
}

configure_health_monitoring() {
    PrintStatus "Configuring system health monitoring..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create comprehensive health monitoring script
cat > /usr/local/bin/z13-health-monitor << 'HEALTH_MONITOR'
#!/bin/bash
# Z13 System Health Monitor

HEALTH_LOG="/var/log/z13-health.log"
METRICS_DIR="/var/lib/z13-monitoring"
ALERT_THRESHOLD_CPU=90
ALERT_THRESHOLD_MEMORY=90
ALERT_THRESHOLD_DISK=90
ALERT_THRESHOLD_TEMP=85

# Create metrics directory
mkdir -p "$METRICS_DIR"

log_health() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$HEALTH_LOG"
    
    # Also log to syslog
    logger -t "z13-health" "[$level] $message"
}

# Check CPU health
check_cpu_health() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local cpu_temp=$(sensors 2>/dev/null | grep -i "Tctl\|Package id 0" | head -1 | grep -o '+[0-9]*' | cut -c2- | head -1)
    local cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print int($4)}')
    
    # Store metrics
    echo "cpu_usage:$cpu_usage" > "$METRICS_DIR/cpu.txt"
    echo "cpu_temp:${cpu_temp:-0}" >> "$METRICS_DIR/cpu.txt"
    echo "cpu_freq:$cpu_freq" >> "$METRICS_DIR/cpu.txt"
    
    # Check thresholds
    if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l 2>/dev/null || echo 0) )); then
        log_health "WARNING" "High CPU usage: ${cpu_usage}%"
        return 1
    fi
    
    if [[ -n "$cpu_temp" ]] && (( cpu_temp > ALERT_THRESHOLD_TEMP )); then
        log_health "CRITICAL" "High CPU temperature: ${cpu_temp}°C"
        return 2
    fi
    
    log_health "INFO" "CPU health OK: ${cpu_usage}% usage, ${cpu_temp:-N/A}°C, ${cpu_freq}MHz"
    return 0
}

# Check memory health
check_memory_health() {
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
    local mem_usage=$((100 - (mem_available * 100 / mem_total)))
    local swap_total=$(grep SwapTotal /proc/meminfo | awk '{print int($2/1024)}')
    local swap_free=$(grep SwapFree /proc/meminfo | awk '{print int($2/1024)}')
    local swap_usage=0
    
    if [[ $swap_total -gt 0 ]]; then
        swap_usage=$(((swap_total - swap_free) * 100 / swap_total))
    fi
    
    # Store metrics
    echo "mem_total:$mem_total" > "$METRICS_DIR/memory.txt"
    echo "mem_usage:$mem_usage" >> "$METRICS_DIR/memory.txt"
    echo "swap_total:$swap_total" >> "$METRICS_DIR/memory.txt"
    echo "swap_usage:$swap_usage" >> "$METRICS_DIR/memory.txt"
    
    # Check thresholds
    if (( mem_usage > ALERT_THRESHOLD_MEMORY )); then
        log_health "WARNING" "High memory usage: ${mem_usage}%"
        return 1
    fi
    
    if (( swap_usage > 50 )); then
        log_health "WARNING" "High swap usage: ${swap_usage}%"
        return 1
    fi
    
    log_health "INFO" "Memory health OK: ${mem_usage}% RAM, ${swap_usage}% swap"
    return 0
}

# Check disk health
check_disk_health() {
    local alerts=0
    
    echo "# Disk Health Report" > "$METRICS_DIR/disk.txt"
    
    # Check disk usage
    df -h | grep -E '^/dev/' | while read -r filesystem size used avail percent mountpoint; do
        local usage_percent=$(echo "$percent" | tr -d '%')
        
        echo "disk_usage_${mountpoint//\//_}:$usage_percent" >> "$METRICS_DIR/disk.txt"
        
        if (( usage_percent > ALERT_THRESHOLD_DISK )); then
            log_health "WARNING" "High disk usage on $mountpoint: $percent"
            alerts=$((alerts + 1))
        fi
    done
    
    # Check SMART status
    local smart_devices=$(lsblk -d -n -o NAME | grep -E '^(sd|nvme)')
    for device in $smart_devices; do
        local smart_status=$(smartctl -H "/dev/$device" 2>/dev/null | grep "SMART overall-health" | awk '{print $6}')
        
        echo "smart_${device}:${smart_status:-UNKNOWN}" >> "$METRICS_DIR/disk.txt"
        
        if [[ "$smart_status" != "PASSED" ]] && [[ -n "$smart_status" ]]; then
            log_health "CRITICAL" "SMART health check failed for /dev/$device: $smart_status"
            alerts=$((alerts + 1))
        fi
    done
    
    if [[ $alerts -eq 0 ]]; then
        log_health "INFO" "Disk health OK"
        return 0
    else
        return 1
    fi
}

# Check network health
check_network_health() {
    local network_issues=0
    
    echo "# Network Health Report" > "$METRICS_DIR/network.txt"
    
    # Check network interfaces
    local interfaces=$(ip link show | grep -E '^[0-9]+:' | grep -v lo | awk -F': ' '{print $2}')
    
    for interface in $interfaces; do
        local status=$(ip link show "$interface" | grep -o "state [A-Z]*" | awk '{print $2}')
        echo "interface_${interface}:$status" >> "$METRICS_DIR/network.txt"
        
        if [[ "$status" != "UP" ]]; then
            log_health "WARNING" "Network interface $interface is $status"
            network_issues=$((network_issues + 1))
        fi
    done
    
    # Check internet connectivity
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "internet_connectivity:OK" >> "$METRICS_DIR/network.txt"
        log_health "INFO" "Internet connectivity OK"
    else
        echo "internet_connectivity:FAILED" >> "$METRICS_DIR/network.txt"
        log_health "WARNING" "Internet connectivity failed"
        network_issues=$((network_issues + 1))
    fi
    
    # Check DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        echo "dns_resolution:OK" >> "$METRICS_DIR/network.txt"
        log_health "INFO" "DNS resolution OK"
    else
        echo "dns_resolution:FAILED" >> "$METRICS_DIR/network.txt"
        log_health "WARNING" "DNS resolution failed"
        network_issues=$((network_issues + 1))
    fi
    
    if [[ $network_issues -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Check power and thermal health
check_power_thermal_health() {
    local power_issues=0
    
    echo "# Power & Thermal Health Report" > "$METRICS_DIR/power.txt"
    
    # Check power source
    local power_source="battery"
    if [ -f /sys/class/power_supply/ADP*/online ]; then
        local ac_online=$(cat /sys/class/power_supply/ADP*/online 2>/dev/null | head -1)
        if [ "$ac_online" = "1" ]; then
            power_source="ac"
        fi
    fi
    
    echo "power_source:$power_source" >> "$METRICS_DIR/power.txt"
    
    # Check battery level
    local battery_level=100
    if [ -f /sys/class/power_supply/BAT*/capacity ]; then
        battery_level=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
        echo "battery_level:$battery_level" >> "$METRICS_DIR/power.txt"
        
        if [[ $battery_level -lt 10 ]] && [[ "$power_source" == "battery" ]]; then
            log_health "CRITICAL" "Critical battery level: ${battery_level}%"
            power_issues=$((power_issues + 1))
        elif [[ $battery_level -lt 20 ]] && [[ "$power_source" == "battery" ]]; then
            log_health "WARNING" "Low battery level: ${battery_level}%"
            power_issues=$((power_issues + 1))
        fi
    fi
    
    # Check thermal zones
    local thermal_zones=$(find /sys/class/thermal/thermal_zone* -name temp 2>/dev/null)
    local max_temp=0
    
    for zone in $thermal_zones; do
        local temp=$(cat "$zone" 2>/dev/null)
        if [[ -n "$temp" ]]; then
            temp=$((temp / 1000))  # Convert from millidegrees
            if [[ $temp -gt $max_temp ]]; then
                max_temp=$temp
            fi
        fi
    done
    
    echo "max_temp:$max_temp" >> "$METRICS_DIR/power.txt"
    
    if [[ $max_temp -gt $ALERT_THRESHOLD_TEMP ]]; then
        log_health "CRITICAL" "High system temperature: ${max_temp}°C"
        power_issues=$((power_issues + 1))
    fi
    
    log_health "INFO" "Power: $power_source, Battery: ${battery_level}%, Max temp: ${max_temp}°C"
    
    if [[ $power_issues -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Generate health summary
generate_health_summary() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local summary_file="$METRICS_DIR/health_summary.json"
    
    cat > "$summary_file" << EOF
{
  "timestamp": "$timestamp",
  "system": "ASUS ROG Flow Z13 (2025)",
  "monitoring_version": "1.0.0",
  "health_checks": {
EOF
    
    # Add individual check results
    local checks=("cpu" "memory" "disk" "network" "power")
    local overall_status="OK"
    
    for i in "${!checks[@]}"; do
        local check="${checks[$i]}"
        local status="OK"
        
        # Determine status based on recent logs
        if grep -q "WARNING.*${check}" "$HEALTH_LOG" | tail -10; then
            status="WARNING"
            overall_status="WARNING"
        fi
        if grep -q "CRITICAL.*${check}" "$HEALTH_LOG" | tail -10; then
            status="CRITICAL"
            overall_status="CRITICAL"
        fi
        
        echo "    \"$check\": \"$status\"" >> "$summary_file"
        
        if [[ $i -lt $((${#checks[@]} - 1)) ]]; then
            echo "," >> "$summary_file"
        fi
    done
    
    cat >> "$summary_file" << EOF
  },
  "overall_status": "$overall_status"
}
EOF
    
    log_health "INFO" "Health summary generated: $overall_status"
    echo "$overall_status"
}

# Main health check function
main() {
    case "$1" in
        "check")
            log_health "INFO" "Starting comprehensive health check"
            
            local exit_code=0
            
            check_cpu_health || exit_code=1
            check_memory_health || exit_code=1
            check_disk_health || exit_code=1
            check_network_health || exit_code=1
            check_power_thermal_health || exit_code=1
            
            local overall_status=$(generate_health_summary)
            
            if [[ $exit_code -eq 0 ]]; then
                log_health "INFO" "All health checks passed"
            else
                log_health "WARNING" "Some health checks failed - check individual components"
            fi
            
            exit $exit_code
            ;;
        "status")
            if [[ -f "$METRICS_DIR/health_summary.json" ]]; then
                cat "$METRICS_DIR/health_summary.json" | python3 -m json.tool
            else
                echo "No health data available. Run 'z13-health-monitor check' first."
            fi
            ;;
        "metrics")
            echo "=== Current System Metrics ==="
            for metric_file in "$METRICS_DIR"/*.txt; do
                if [[ -f "$metric_file" ]]; then
                    echo "$(basename "$metric_file" .txt):"
                    cat "$metric_file"
                    echo ""
                fi
            done
            ;;
        *)
            echo "Usage: $0 {check|status|metrics}"
            exit 1
            ;;
    esac
}

main "$@"
HEALTH_MONITOR

chmod +x /usr/local/bin/z13-health-monitor

PrintStatus "System health monitoring configured"
EOF
}

configure_performance_monitoring() {
    PrintStatus "Configuring performance monitoring..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Configure collectd for detailed performance metrics
cat > /etc/collectd/collectd.conf << 'COLLECTD_CONFIG'
# Z13 Performance Monitoring Configuration

Hostname "z13-flow"
FQDNLookup true
BaseDir "/var/lib/collectd"
PluginDir "/usr/lib/collectd"
TypesDB "/usr/share/collectd/types.db"
Interval 10
MaxReadInterval 86400
Timeout 2
ReadThreads 5

# Logging
LoadPlugin logfile
<Plugin logfile>
    LogLevel info
    File "/var/log/collectd.log"
    Timestamp true
    PrintSeverity false
</Plugin>

# CPU monitoring
LoadPlugin cpu
<Plugin cpu>
    ReportByCpu true
    ReportByState true
    ValuesPercentage true
</Plugin>

# Memory monitoring
LoadPlugin memory
<Plugin memory>
    ValuesAbsolute true
    ValuesPercentage true
</Plugin>

# Disk monitoring
LoadPlugin disk
<Plugin disk>
    Disk "/^[hs]d[a-z]/"
    Disk "/^nvme/"
    IgnoreSelected false
    UdevNameAttr "DEVNAME"
</Plugin>

# Network monitoring
LoadPlugin interface
<Plugin interface>
    Interface "lo"
    Interface "/^eth/"
    Interface "/^wl/"
    IgnoreSelected false
</Plugin>

# Load average
LoadPlugin load

# Uptime
LoadPlugin uptime

# Thermal monitoring
LoadPlugin thermal
<Plugin thermal>
    ForceUseProcfs false
    Device "thermal_zone0"
    Device "thermal_zone1"
    IgnoreSelected false
</Plugin>

# Process monitoring
LoadPlugin processes
<Plugin processes>
    ProcessMatch "z13-tdp" "z13-tdp"
    ProcessMatch "z13-health" "z13-health"
    ProcessMatch "firefox" "firefox"
    ProcessMatch "chrome" "chrome"
    Process "systemd"
    Process "kthreadd"
</Plugin>

# Write to CSV files
LoadPlugin csv
<Plugin csv>
    DataDir "/var/lib/collectd/csv"
    StoreRates false
</Plugin>

# RRD database
LoadPlugin rrdtool
<Plugin rrdtool>
    DataDir "/var/lib/collectd/rrd"
    CacheTimeout 120
    CacheFlush 900
    WritesPerSecond 30
</Plugin>
COLLECTD_CONFIG

# Enable collectd service
systemctl enable collectd.service

PrintStatus "Performance monitoring (collectd) configured"
EOF
}

configure_hardware_monitoring() {
    PrintStatus "Configuring hardware monitoring..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Configure sensors for hardware monitoring
sensors-detect --auto

# Create hardware monitoring script
cat > /usr/local/bin/z13-hardware-monitor << 'HW_MONITOR'
#!/bin/bash
# Z13 Hardware Monitoring

HW_LOG="/var/log/z13-hardware.log"
HW_METRICS="/var/lib/z13-monitoring/hardware.txt"

log_hw() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HW_LOG"
}

monitor_sensors() {
    echo "# Hardware Sensor Data" > "$HW_METRICS"
    echo "timestamp:$(date '+%Y-%m-%d %H:%M:%S')" >> "$HW_METRICS"
    
    # CPU temperature
    if command -v sensors >/dev/null 2>&1; then
        local cpu_temp=$(sensors 2>/dev/null | grep -i "Tctl\|Package id 0" | head -1 | grep -o '+[0-9]*' | cut -c2-)
        if [[ -n "$cpu_temp" ]]; then
            echo "cpu_temp:$cpu_temp" >> "$HW_METRICS"
            log_hw "CPU temperature: ${cpu_temp}°C"
        fi
        
        # Fan speeds
        local fan_speeds=$(sensors 2>/dev/null | grep -i "fan" | awk '{print $2}' | tr '\n' ' ')
        if [[ -n "$fan_speeds" ]]; then
            echo "fan_speeds:$fan_speeds" >> "$HW_METRICS"
            log_hw "Fan speeds: $fan_speeds RPM"
        fi
    fi
    
    # GPU information
    if command -v lspci >/dev/null 2>&1; then
        local gpu_info=$(lspci | grep -i "vga\|display" | head -1)
        echo "gpu_info:$gpu_info" >> "$HW_METRICS"
    fi
    
    # Storage health
    local storage_devices=$(lsblk -d -n -o NAME | grep -E '^(sd|nvme)')
    for device in $storage_devices; do
        if command -v smartctl >/dev/null 2>&1; then
            local smart_temp=$(smartctl -A "/dev/$device" 2>/dev/null | grep -i "temperature" | awk '{print $10}' | head -1)
            if [[ -n "$smart_temp" ]]; then
                echo "storage_temp_${device}:$smart_temp" >> "$HW_METRICS"
            fi
        fi
    done
    
    # Power consumption (if available)
    if [ -d /sys/class/power_supply/BAT* ]; then
        local power_now=$(cat /sys/class/power_supply/BAT*/power_now 2>/dev/null | head -1)
        if [[ -n "$power_now" ]]; then
            local power_watts=$((power_now / 1000000))
            echo "power_consumption:$power_watts" >> "$HW_METRICS"
            log_hw "Power consumption: ${power_watts}W"
        fi
    fi
}

case "$1" in
    "monitor")
        monitor_sensors
        ;;
    "status")
        if [[ -f "$HW_METRICS" ]]; then
            echo "Latest hardware metrics:"
            cat "$HW_METRICS"
        else
            echo "No hardware metrics available"
        fi
        ;;
    *)
        echo "Usage: $0 {monitor|status}"
        exit 1
        ;;
esac
HW_MONITOR

chmod +x /usr/local/bin/z13-hardware-monitor

PrintStatus "Hardware monitoring configured"
EOF
}

configure_alerting_system() {
    PrintStatus "Configuring alerting system..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create alerting system
cat > /usr/local/bin/z13-alert-manager << 'ALERT_MANAGER'
#!/bin/bash
# Z13 Alert Manager

ALERT_LOG="/var/log/z13-alerts.log"
ALERT_CONFIG="/etc/z13/alerts.conf"
NOTIFICATION_SENT="/tmp/z13-last-notification"

# Default alert configuration
create_default_alert_config() {
    mkdir -p "$(dirname "$ALERT_CONFIG")"
    
    cat > "$ALERT_CONFIG" << 'ALERT_CONFIG_CONTENT'
# Z13 Alert Configuration

# Alert thresholds
CPU_THRESHOLD=90
MEMORY_THRESHOLD=90
DISK_THRESHOLD=90
TEMP_THRESHOLD=85
BATTERY_CRITICAL=10
BATTERY_LOW=20

# Notification settings
ENABLE_DESKTOP_NOTIFICATIONS=true
ENABLE_LOG_ALERTS=true
ENABLE_EMAIL_ALERTS=false
EMAIL_ADDRESS=""

# Notification cooldown (seconds)
NOTIFICATION_COOLDOWN=300
ALERT_CONFIG_CONTENT
}

# Load alert configuration
load_alert_config() {
    if [[ -f "$ALERT_CONFIG" ]]; then
        source "$ALERT_CONFIG"
    else
        create_default_alert_config
        source "$ALERT_CONFIG"
    fi
}

# Send desktop notification
send_desktop_notification() {
    local severity="$1"
    local title="$2"
    local message="$3"
    
    if [[ "$ENABLE_DESKTOP_NOTIFICATIONS" == "true" ]]; then
        # Find active user session
        local active_user=$(who | grep -E "\(:[0-9]+\)" | head -1 | awk '{print $1}')
        if [[ -n "$active_user" ]]; then
            local display=$(who | grep "$active_user" | grep -o ":[0-9]*" | head -1)
            if [[ -n "$display" ]]; then
                sudo -u "$active_user" DISPLAY="$display" notify-send \
                    --urgency="$severity" \
                    --icon="dialog-warning" \
                    "$title" \
                    "$message" 2>/dev/null || true
            fi
        fi
    fi
}

# Send email notification
send_email_notification() {
    local subject="$1"
    local body="$2"
    
    if [[ "$ENABLE_EMAIL_ALERTS" == "true" ]] && [[ -n "$EMAIL_ADDRESS" ]]; then
        echo "$body" | mail -s "$subject" "$EMAIL_ADDRESS" 2>/dev/null || true
    fi
}

# Log alert
log_alert() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$ALERT_LOG"
    
    if [[ "$ENABLE_LOG_ALERTS" == "true" ]]; then
        logger -t "z13-alert" "[$level] $message"
    fi
}

# Check if notification cooldown is active
check_cooldown() {
    local alert_type="$1"
    local cooldown_file="${NOTIFICATION_SENT}.${alert_type}"
    
    if [[ -f "$cooldown_file" ]]; then
        local last_notification=$(cat "$cooldown_file")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_notification))
        
        if [[ $time_diff -lt $NOTIFICATION_COOLDOWN ]]; then
            return 1  # Still in cooldown
        fi
    fi
    
    echo "$(date +%s)" > "$cooldown_file"
    return 0  # Not in cooldown
}

# Process alert
process_alert() {
    local severity="$1"
    local component="$2"
    local message="$3"
    local value="$4"
    
    local alert_title="Z13 System Alert"
    local alert_message="$component: $message (Value: $value)"
    
    # Log the alert
    log_alert "$severity" "$alert_message"
    
    # Check cooldown
    if check_cooldown "$component"; then
        # Send notifications
        case "$severity" in
            "CRITICAL")
                send_desktop_notification "critical" "$alert_title - CRITICAL" "$alert_message"
                send_email_notification "CRITICAL: $alert_title" "$alert_message"
                ;;
            "WARNING")
                send_desktop_notification "normal" "$alert_title - WARNING" "$alert_message"
                ;;
            "INFO")
                send_desktop_notification "low" "$alert_title - INFO" "$alert_message"
                ;;
        esac
    fi
}

# Monitor system and generate alerts
monitor_and_alert() {
    load_alert_config
    
    # Get current metrics
    local metrics_dir="/var/lib/z13-monitoring"
    
    # Check CPU
    if [[ -f "$metrics_dir/cpu.txt" ]]; then
        local cpu_usage=$(grep "cpu_usage:" "$metrics_dir/cpu.txt" | cut -d':' -f2)
        local cpu_temp=$(grep "cpu_temp:" "$metrics_dir/cpu.txt" | cut -d':' -f2)
        
        if [[ -n "$cpu_usage" ]] && (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
            process_alert "WARNING" "CPU" "High CPU usage detected" "${cpu_usage}%"
        fi
        
        if [[ -n "$cpu_temp" ]] && (( cpu_temp > TEMP_THRESHOLD )); then
            process_alert "CRITICAL" "CPU" "High CPU temperature detected" "${cpu_temp}°C"
        fi
    fi
    
    # Check Memory
    if [[ -f "$metrics_dir/memory.txt" ]]; then
        local mem_usage=$(grep "mem_usage:" "$metrics_dir/memory.txt" | cut -d':' -f2)
        
        if [[ -n "$mem_usage" ]] && (( mem_usage > MEMORY_THRESHOLD )); then
            process_alert "WARNING" "Memory" "High memory usage detected" "${mem_usage}%"
        fi
    fi
    
    # Check Power
    if [[ -f "$metrics_dir/power.txt" ]]; then
        local battery_level=$(grep "battery_level:" "$metrics_dir/power.txt" | cut -d':' -f2)
        local power_source=$(grep "power_source:" "$metrics_dir/power.txt" | cut -d':' -f2)
        
        if [[ -n "$battery_level" ]] && [[ "$power_source" == "battery" ]]; then
            if (( battery_level <= BATTERY_CRITICAL )); then
                process_alert "CRITICAL" "Battery" "Critical battery level" "${battery_level}%"
            elif (( battery_level <= BATTERY_LOW )); then
                process_alert "WARNING" "Battery" "Low battery level" "${battery_level}%"
            fi
        fi
    fi
}

case "$1" in
    "monitor")
        monitor_and_alert
        ;;
    "test")
        load_alert_config
        process_alert "INFO" "Test" "Alert system test" "OK"
        ;;
    "config")
        if [[ -f "$ALERT_CONFIG" ]]; then
            echo "Current alert configuration:"
            cat "$ALERT_CONFIG"
        else
            echo "No alert configuration found. Creating default..."
            create_default_alert_config
            echo "Default configuration created at: $ALERT_CONFIG"
        fi
        ;;
    "status")
        echo "Recent alerts:"
        tail -10 "$ALERT_LOG" 2>/dev/null || echo "No alerts logged"
        ;;
    *)
        echo "Usage: $0 {monitor|test|config|status}"
        exit 1
        ;;
esac
ALERT_MANAGER

chmod +x /usr/local/bin/z13-alert-manager

PrintStatus "Alerting system configured"
EOF
}

configure_log_monitoring() {
    PrintStatus "Configuring log monitoring..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create log monitoring script
cat > /usr/local/bin/z13-log-monitor << 'LOG_MONITOR'
#!/bin/bash
# Z13 Log Monitor - Watch for critical system events

LOG_MONITOR_LOG="/var/log/z13-log-monitor.log"
WATCHED_LOGS=(
    "/var/log/kern.log"
    "/var/log/syslog"
    "/var/log/auth.log"
    "/var/log/z13-tdp.log"
    "/var/log/z13-health.log"
)

# Critical patterns to watch for
CRITICAL_PATTERNS=(
    "kernel panic"
    "out of memory"
    "segfault"
    "hardware error"
    "thermal throttling"
    "critical temperature"
    "disk error"
    "filesystem error"
)

# Warning patterns
WARNING_PATTERNS=(
    "failed login"
    "authentication failure"
    "permission denied"
    "connection refused"
    "timeout"
    "retry limit exceeded"
)

log_event() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_MONITOR_LOG"
}

# Monitor logs for patterns
monitor_logs() {
    log_event "INFO" "Starting log monitoring"
    
    # Use journalctl for systemd logs
    journalctl -f --since "1 minute ago" | while read -r line; do
        # Check for critical patterns
        for pattern in "${CRITICAL_PATTERNS[@]}"; do
            if echo "$line" | grep -qi "$pattern"; then
                log_event "CRITICAL" "Critical pattern detected: $pattern in: $line"
                /usr/local/bin/z13-alert-manager process_alert "CRITICAL" "System" "Critical log pattern detected: $pattern" "$line"
            fi
        done
        
        # Check for warning patterns
        for pattern in "${WARNING_PATTERNS[@]}"; do
            if echo "$line" | grep -qi "$pattern"; then
                log_event "WARNING" "Warning pattern detected: $pattern in: $line"
            fi
        done
    done &
    
    # Monitor specific log files
    for logfile in "${WATCHED_LOGS[@]}"; do
        if [[ -f "$logfile" ]]; then
            tail -f "$logfile" 2>/dev/null | while read -r line; do
                # Process log line for patterns
                for pattern in "${CRITICAL_PATTERNS[@]}"; do
                    if echo "$line" | grep -qi "$pattern"; then
                        log_event "CRITICAL" "Critical pattern in $logfile: $pattern"
                    fi
                done
            done &
        fi
    done
    
    log_event "INFO" "Log monitoring active"
    wait
}

case "$1" in
    "start")
        monitor_logs
        ;;
    "status")
        echo "Recent log monitoring events:"
        tail -20 "$LOG_MONITOR_LOG" 2>/dev/null || echo "No log monitoring events"
        ;;
    *)
        echo "Usage: $0 {start|status}"
        exit 1
        ;;
esac
LOG_MONITOR

chmod +x /usr/local/bin/z13-log-monitor

PrintStatus "Log monitoring configured"
EOF
}

configure_web_dashboard() {
    PrintStatus "Configuring web monitoring dashboard..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create simple web dashboard
mkdir -p /var/www/z13-monitoring

cat > /var/www/z13-monitoring/index.html << 'DASHBOARD_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Z13 System Monitoring Dashboard</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            margin-bottom: 20px;
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .metric-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 15px;
            color: #333;
        }
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
        .metric-unit {
            font-size: 14px;
            color: #666;
        }
        .status-ok { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-critical { color: #dc3545; }
        .progress-bar {
            width: 100%;
            height: 20px;
            background-color: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 10px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #28a745 0%, #ffc107 70%, #dc3545 90%);
            transition: width 0.3s ease;
        }
        .log-section {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .log-entry {
            padding: 8px;
            border-left: 4px solid #667eea;
            margin-bottom: 8px;
            background-color: #f8f9fa;
            font-family: monospace;
            font-size: 12px;
        }
        .refresh-button {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖥️ ASUS ROG Flow Z13 (2025) Monitoring</h1>
            <p>Real-time system health and performance metrics</p>
        </div>
        
        <button class="refresh-button" onclick="refreshData()">🔄 Refresh Data</button>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-title">CPU Usage</div>
                <div class="metric-value" id="cpu-usage">--</div>
                <div class="metric-unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="cpu-progress" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">Memory Usage</div>
                <div class="metric-value" id="memory-usage">--</div>
                <div class="metric-unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="memory-progress" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">CPU Temperature</div>
                <div class="metric-value" id="cpu-temp">--</div>
                <div class="metric-unit">°C</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">Battery Level</div>
                <div class="metric-value" id="battery-level">--</div>
                <div class="metric-unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="battery-progress" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">Power Source</div>
                <div class="metric-value" id="power-source">--</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">System Status</div>
                <div class="metric-value" id="system-status">--</div>
            </div>
        </div>
        
        <div class="log-section">
            <h3>Recent System Events</h3>
            <div id="log-entries">
                <div class="log-entry">Loading system logs...</div>
            </div>
        </div>
    </div>
    
    <script>
        async function fetchMetrics() {
            try {
                const response = await fetch('/api/metrics');
                const data = await response.json();
                updateDashboard(data);
            } catch (error) {
                console.error('Failed to fetch metrics:', error);
                // Use mock data for demonstration
                updateDashboard({
                    cpu_usage: Math.floor(Math.random() * 100),
                    memory_usage: Math.floor(Math.random() * 100),
                    cpu_temp: Math.floor(Math.random() * 50 + 30),
                    battery_level: Math.floor(Math.random() * 100),
                    power_source: Math.random() > 0.5 ? 'AC' : 'Battery',
                    system_status: 'OK'
                });
            }
        }
        
        function updateDashboard(data) {
            document.getElementById('cpu-usage').textContent = data.cpu_usage || '--';
            document.getElementById('cpu-progress').style.width = (data.cpu_usage || 0) + '%';
            
            document.getElementById('memory-usage').textContent = data.memory_usage || '--';
            document.getElementById('memory-progress').style.width = (data.memory_usage || 0) + '%';
            
            document.getElementById('cpu-temp').textContent = data.cpu_temp || '--';
            document.getElementById('battery-level').textContent = data.battery_level || '--';
            document.getElementById('battery-progress').style.width = (data.battery_level || 0) + '%';
            
            document.getElementById('power-source').textContent = data.power_source || '--';
            
            const statusElement = document.getElementById('system-status');
            const status = data.system_status || 'Unknown';
            statusElement.textContent = status;
            statusElement.className = 'metric-value status-' + status.toLowerCase();
        }
        
        function refreshData() {
            fetchMetrics();
        }
        
        // Auto-refresh every 30 seconds
        setInterval(fetchMetrics, 30000);
        
        // Initial load
        fetchMetrics();
    </script>
</body>
</html>
DASHBOARD_HTML

# Create API endpoint script
cat > /var/www/z13-monitoring/api.sh << 'API_SCRIPT'
#!/bin/bash
# Simple API for Z13 monitoring dashboard

METRICS_DIR="/var/lib/z13-monitoring"

generate_metrics_json() {
    echo "Content-Type: application/json"
    echo ""
    
    echo "{"
    
    # CPU metrics
    if [[ -f "$METRICS_DIR/cpu.txt" ]]; then
        local cpu_usage=$(grep "cpu_usage:" "$METRICS_DIR/cpu.txt" | cut -d':' -f2 | tr -d ' ')
        local cpu_temp=$(grep "cpu_temp:" "$METRICS_DIR/cpu.txt" | cut -d':' -f2 | tr -d ' ')
        echo "  \"cpu_usage\": ${cpu_usage:-0},"
        echo "  \"cpu_temp\": ${cpu_temp:-0},"
    else
        echo "  \"cpu_usage\": 0,"
        echo "  \"cpu_temp\": 0,"
    fi
    
    # Memory metrics
    if [[ -f "$METRICS_DIR/memory.txt" ]]; then
        local memory_usage=$(grep "mem_usage:" "$METRICS_DIR/memory.txt" | cut -d':' -f2 | tr -d ' ')
        echo "  \"memory_usage\": ${memory_usage:-0},"
    else
        echo "  \"memory_usage\": 0,"
    fi
    
    # Power metrics
    if [[ -f "$METRICS_DIR/power.txt" ]]; then
        local battery_level=$(grep "battery_level:" "$METRICS_DIR/power.txt" | cut -d':' -f2 | tr -d ' ')
        local power_source=$(grep "power_source:" "$METRICS_DIR/power.txt" | cut -d':' -f2 | tr -d ' ')
        echo "  \"battery_level\": ${battery_level:-100},"
        echo "  \"power_source\": \"${power_source:-AC}\","
    else
        echo "  \"battery_level\": 100,"
        echo "  \"power_source\": \"AC\","
    fi
    
    # System status
    if [[ -f "$METRICS_DIR/health_summary.json" ]]; then
        local system_status=$(grep "overall_status" "$METRICS_DIR/health_summary.json" | cut -d'"' -f4)
        echo "  \"system_status\": \"${system_status:-OK}\""
    else
        echo "  \"system_status\": \"OK\""
    fi
    
    echo "}"
}

case "$REQUEST_URI" in
    "/api/metrics")
        generate_metrics_json
        ;;
    *)
        echo "Content-Type: text/html"
        echo ""
        cat /var/www/z13-monitoring/index.html
        ;;
esac
API_SCRIPT

chmod +x /var/www/z13-monitoring/api.sh

PrintStatus "Web monitoring dashboard configured at /var/www/z13-monitoring/"
EOF
}

create_monitoring_services() {
    PrintStatus "Creating monitoring services..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create health monitoring service
cat > /etc/systemd/system/z13-health-monitor.service << 'HEALTH_SERVICE'
[Unit]
Description=Z13 System Health Monitor
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-health-monitor check
StandardOutput=journal
StandardError=journal
HEALTH_SERVICE

cat > /etc/systemd/system/z13-health-monitor.timer << 'HEALTH_TIMER'
[Unit]
Description=Run Z13 health monitoring every 5 minutes
Requires=z13-health-monitor.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
HEALTH_TIMER

# Create hardware monitoring service
cat > /etc/systemd/system/z13-hardware-monitor.service << 'HW_SERVICE'
[Unit]
Description=Z13 Hardware Monitor
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-hardware-monitor monitor
StandardOutput=journal
StandardError=journal
HW_SERVICE

cat > /etc/systemd/system/z13-hardware-monitor.timer << 'HW_TIMER'
[Unit]
Description=Run Z13 hardware monitoring every 2 minutes
Requires=z13-hardware-monitor.service

[Timer]
OnCalendar=*:0/2
Persistent=true

[Install]
WantedBy=timers.target
HW_TIMER

# Create alert monitoring service
cat > /etc/systemd/system/z13-alert-monitor.service << 'ALERT_SERVICE'
[Unit]
Description=Z13 Alert Monitor
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-alert-manager monitor
StandardOutput=journal
StandardError=journal
ALERT_SERVICE

cat > /etc/systemd/system/z13-alert-monitor.timer << 'ALERT_TIMER'
[Unit]
Description=Run Z13 alert monitoring every minute
Requires=z13-alert-monitor.service

[Timer]
OnCalendar=*:0/1
Persistent=true

[Install]
WantedBy=timers.target
ALERT_TIMER

# Enable all monitoring services
systemctl enable z13-health-monitor.timer
systemctl enable z13-hardware-monitor.timer
systemctl enable z13-alert-monitor.timer

# Create monitoring status script
cat > /usr/local/bin/z13-monitoring-status << 'STATUS_SCRIPT'
#!/bin/bash
# Z13 Monitoring Status Overview

echo "=== Z13 System Monitoring Status ==="
echo "Generated: $(date)"
echo ""

echo "Service Status:"
systemctl is-active z13-health-monitor.timer && echo "✓ Health monitoring: Active" || echo "✗ Health monitoring: Inactive"
systemctl is-active z13-hardware-monitor.timer && echo "✓ Hardware monitoring: Active" || echo "✗ Hardware monitoring: Inactive"
systemctl is-active z13-alert-monitor.timer && echo "✓ Alert monitoring: Active" || echo "✗ Alert monitoring: Inactive"
systemctl is-active collectd.service && echo "✓ Performance monitoring (collectd): Active" || echo "✗ Performance monitoring: Inactive"

echo ""
echo "Recent Health Status:"
/usr/local/bin/z13-health-monitor status 2>/dev/null || echo "No health data available"

echo ""
echo "Recent Alerts:"
tail -5 /var/log/z13-alerts.log 2>/dev/null || echo "No alerts logged"

echo ""
echo "System Resources:"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
echo "Memory: $(free -h | grep "Mem:" | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"

echo ""
echo "Dashboard: http://localhost:8080 (if web server configured)"
STATUS_SCRIPT

chmod +x /usr/local/bin/z13-monitoring-status

PrintStatus "Monitoring services created and enabled"
EOF
}

# Export functions for use by main script
export -f system_monitoring_setup
export -f configure_health_monitoring
export -f configure_performance_monitoring
export -f configure_hardware_monitoring
export -f configure_alerting_system
export -f configure_log_monitoring
export -f configure_web_dashboard
export -f create_monitoring_services
