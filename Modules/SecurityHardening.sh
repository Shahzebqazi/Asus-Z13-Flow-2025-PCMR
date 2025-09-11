#!/bin/bash
# Security Hardening Module
# Comprehensive security hardening for ASUS ROG Flow Z13 (2025)

security_hardening_setup() {
    PrintHeader "Security Hardening Configuration"
    
    if [[ "$ENABLE_SECURITY_HARDENING" != "true" ]]; then
        PrintStatus "Security hardening disabled in configuration, skipping..."
        return 0
    fi
    
    PrintStatus "Implementing comprehensive security hardening..."
    
    # Install security packages with verification
    InstallPackageGroupWithVerification apparmor apparmor-utils apparmor-profiles chroot
    InstallPackageGroupWithVerification ufw fail2ban rkhunter chkrootkit chroot
    InstallPackageGroupWithVerification audit lynis aide chroot
    
    # Configure AppArmor
    configure_apparmor
    
    # Configure firewall
    configure_firewall
    
    # Configure system auditing
    configure_auditing
    
    # Configure intrusion detection
    configure_intrusion_detection
    
    # Configure file integrity monitoring
    configure_file_integrity
    
    # Apply kernel hardening
    configure_kernel_hardening
    
    # Configure SSH hardening if SSH is installed
    configure_ssh_hardening
    
    PrintStatus "Security hardening configuration completed"
}

configure_apparmor() {
    PrintStatus "Configuring AppArmor security profiles..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Enable AppArmor in kernel parameters
if ! grep -q "apparmor=1" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&apparmor=1 security=apparmor /' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Enable AppArmor service
systemctl enable apparmor.service

# Load default profiles
apparmor_parser -r /etc/apparmor.d/usr.bin.firefox 2>/dev/null || true
apparmor_parser -r /etc/apparmor.d/usr.bin.thunderbird 2>/dev/null || true

# Create custom Z13-specific AppArmor profiles
mkdir -p /etc/apparmor.d/local

# Profile for TDP management tools
cat > /etc/apparmor.d/usr.local.bin.z13-tdp << 'PROFILE'
#include <tunables/global>

/usr/local/bin/z13-tdp {
  #include <abstractions/base>
  #include <abstractions/bash>
  
  capability sys_admin,
  capability dac_override,
  
  /usr/local/bin/z13-tdp r,
  /bin/bash ix,
  /usr/bin/ryzenadj rix,
  /sys/class/power_supply/** r,
  /proc/cpuinfo r,
  /var/log/z13-tdp.log w,
  /etc/z13/** r,
  
  # Allow reading system power information
  /sys/devices/system/cpu/cpu*/cpufreq/** r,
  /sys/class/thermal/thermal_zone*/temp r,
}
PROFILE

# Profile for power management
cat > /etc/apparmor.d/usr.local.bin.z13-power-manager << 'PROFILE'
#include <tunables/global>

/usr/local/bin/z13-power-manager {
  #include <abstractions/base>
  #include <abstractions/bash>
  
  capability sys_admin,
  capability net_admin,
  
  /usr/local/bin/z13-power-manager r,
  /bin/bash ix,
  /usr/bin/cpupower rix,
  /sys/class/power_supply/** rw,
  /sys/devices/system/cpu/** rw,
  /proc/sys/vm/** rw,
  /var/log/z13-power.log w,
}
PROFILE

# Load custom profiles
apparmor_parser -r /etc/apparmor.d/usr.local.bin.z13-tdp 2>/dev/null || true
apparmor_parser -r /etc/apparmor.d/usr.local.bin.z13-power-manager 2>/dev/null || true

PrintStatus "AppArmor profiles configured and loaded"
EOF
}

configure_firewall() {
    PrintStatus "Configuring UFW firewall..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Reset UFW to defaults
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing
ufw default deny forward

# Allow essential services
ufw allow out 53/udp    # DNS
ufw allow out 80/tcp    # HTTP
ufw allow out 443/tcp   # HTTPS
ufw allow out 123/udp   # NTP

# Allow local network communication (adjust range as needed)
ufw allow from 192.168.0.0/16
ufw allow from 10.0.0.0/8
ufw allow from 172.16.0.0/12

# Enable logging
ufw logging on

# Enable UFW
ufw --force enable

# Enable UFW service
systemctl enable ufw.service

PrintStatus "UFW firewall configured and enabled"
EOF
}

configure_auditing() {
    PrintStatus "Configuring system auditing..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Configure audit rules for security monitoring
cat > /etc/audit/rules.d/z13-security.rules << 'AUDIT_RULES'
# Z13 Security Audit Rules

# Monitor authentication events
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Monitor sudo usage
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# Monitor system configuration changes
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/systemd/ -p wa -k systemd_config
-w /etc/grub.d/ -p wa -k grub_config
-w /boot/grub/grub.cfg -p wa -k grub_config

# Monitor TDP and power management
-w /etc/z13/ -p wa -k z13_config
-w /usr/local/bin/z13-tdp -p x -k z13_tdp
-w /var/log/z13-tdp.log -p wa -k z13_logs

# Monitor kernel modules
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules

# Monitor file permission changes
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod

# Monitor network configuration
-w /etc/NetworkManager/ -p wa -k network_config
AUDIT_RULES

# Enable auditd service
systemctl enable auditd.service

PrintStatus "System auditing configured"
EOF
}

configure_intrusion_detection() {
    PrintStatus "Configuring intrusion detection..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Configure fail2ban for intrusion prevention
cat > /etc/fail2ban/jail.local << 'FAIL2BAN_CONFIG'
[DEFAULT]
# Ban time: 24 hours
bantime = 86400

# Find time: 10 minutes  
findtime = 600

# Max retry: 3 attempts
maxretry = 3

# Ignore local networks
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[systemd-ssh]
enabled = true
filter = systemd-ssh
logpath = /var/log/journal
maxretry = 3
bantime = 3600
FAIL2BAN_CONFIG

# Enable fail2ban service
systemctl enable fail2ban.service

# Configure rkhunter
cat > /etc/rkhunter.conf.local << 'RKHUNTER_CONFIG'
# Z13-specific rkhunter configuration
UPDATE_MIRRORS=1
MIRRORS_MODE=0
WEB_CMD=""

# Allow Z13-specific files
ALLOWHIDDENDIR=/etc/.java
ALLOWHIDDENFILE=/etc/.updated
ALLOWHIDDENFILE=/usr/share/man/man1/..1.gz

# Skip Z13-specific checks that may cause false positives
DISABLE_TESTS="suspscan hidden_procs deleted_files packet_cap_apps"

# Update frequency
CRON_DAILY_RUN="true"
CRON_DB_UPDATE="true"
REPORT_WARNINGS_ONLY="true"
RKHUNTER_CONFIG

PrintStatus "Intrusion detection configured"
EOF
}

configure_file_integrity() {
    PrintStatus "Configuring file integrity monitoring..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Configure AIDE for file integrity monitoring
cat > /etc/aide.conf << 'AIDE_CONFIG'
# Z13 AIDE Configuration

# Define rules
Binlib = p+i+n+u+g+s+b+m+c+md5+sha1+sha256
ConfFiles = p+i+n+u+g+s+b+m+c+md5+sha1+sha256
Logs = p+i+n+u+g+s+b+m+c+md5+sha1+sha256
Devices = p+i+n+u+g+s+b+c+md5+sha1+sha256
Databases = p+i+n+u+g+s+b+m+c+md5+sha1+sha256

# Directories to monitor
/boot Binlib
/bin Binlib
/sbin Binlib
/usr/bin Binlib
/usr/sbin Binlib
/usr/local/bin Binlib

/etc ConfFiles
/etc/z13 ConfFiles

# System files
/root Binlib
/lib Binlib
/lib64 Binlib
/usr/lib Binlib
/usr/lib64 Binlib

# Logs
/var/log Logs

# Exclude frequently changing files
!/var/log/.*
!/tmp/.*
!/proc/.*
!/sys/.*
!/dev/.*
!/run/.*
!/var/cache/.*
!/var/lib/pacman/.*
!/home/.*/.*
AIDE_CONFIG

# Initialize AIDE database
aide --init

# Move database to final location
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Create daily AIDE check service
cat > /etc/systemd/system/aide-check.service << 'AIDE_SERVICE'
[Unit]
Description=AIDE File Integrity Check
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/aide --check
StandardOutput=journal
StandardError=journal
AIDE_SERVICE

cat > /etc/systemd/system/aide-check.timer << 'AIDE_TIMER'
[Unit]
Description=Run AIDE check daily
Requires=aide-check.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
AIDE_TIMER

systemctl enable aide-check.timer

PrintStatus "File integrity monitoring configured"
EOF
}

configure_kernel_hardening() {
    PrintStatus "Applying kernel security hardening..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create kernel hardening configuration
cat > /etc/sysctl.d/99-z13-security.conf << 'SYSCTL_CONFIG'
# Z13 Kernel Security Hardening

# Network security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0

# IPv6 security
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Memory protection
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2

# File system security
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2

# Process security
kernel.core_uses_pid = 1
kernel.ctrl-alt-del = 0
SYSCTL_CONFIG

# Create module blacklist for security
cat > /etc/modprobe.d/z13-security-blacklist.conf << 'MODULE_BLACKLIST'
# Security-related module blacklist for Z13

# Disable uncommon network protocols
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true

# Disable uncommon filesystems
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true

# Disable firewire (potential DMA attack vector)
install firewire-core /bin/true
install firewire-ohci /bin/true
install firewire-sbp2 /bin/true

# Disable thunderbolt (if not needed)
# install thunderbolt /bin/true
MODULE_BLACKLIST

PrintStatus "Kernel hardening applied"
EOF
}

configure_ssh_hardening() {
    PrintStatus "Configuring SSH hardening (if SSH is installed)..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Only configure SSH if it's installed
if command -v sshd >/dev/null 2>&1; then
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Create hardened SSH configuration
    cat > /etc/ssh/sshd_config.d/z13-hardening.conf << 'SSH_CONFIG'
# Z13 SSH Hardening Configuration

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
MaxAuthTries 3
MaxSessions 2
MaxStartups 2

# Protocol settings
Protocol 2
Port 22
AddressFamily inet

# Encryption
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Timeouts
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30

# Logging
LogLevel VERBOSE
SyslogFacility AUTH

# Miscellaneous
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no
X11Forwarding no
PrintMotd no
Banner /etc/ssh/banner
SSH_CONFIG

    # Create SSH banner
    cat > /etc/ssh/banner << 'SSH_BANNER'
***************************************************************************
                    AUTHORIZED ACCESS ONLY
                    
This system is for authorized users only. All activity is monitored
and logged. Unauthorized access is prohibited and will be prosecuted
to the full extent of the law.

ASUS ROG Flow Z13 (2025) - Arch Linux System
***************************************************************************
SSH_BANNER

    PrintStatus "SSH hardening configured"
else
    PrintStatus "SSH not installed, skipping SSH hardening"
fi
EOF
}

# Function to create security monitoring script
create_security_monitoring() {
    PrintStatus "Creating security monitoring system..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create security monitoring script
cat > /usr/local/bin/z13-security-monitor << 'SECURITY_MONITOR'
#!/bin/bash
# Z13 Security Monitoring Script

LOG_FILE="/var/log/z13-security.log"
ALERT_THRESHOLD=5

log_security_event() {
    local event="$1"
    local severity="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$severity] $event" >> "$LOG_FILE"
}

check_failed_logins() {
    local failed_count=$(journalctl --since "1 hour ago" | grep "Failed password" | wc -l)
    if [[ $failed_count -gt $ALERT_THRESHOLD ]]; then
        log_security_event "High number of failed login attempts: $failed_count" "WARNING"
    fi
}

check_privilege_escalation() {
    local sudo_count=$(journalctl --since "1 hour ago" | grep "sudo:" | wc -l)
    if [[ $sudo_count -gt 20 ]]; then
        log_security_event "High number of sudo attempts: $sudo_count" "INFO"
    fi
}

check_system_integrity() {
    if command -v aide >/dev/null 2>&1; then
        if ! aide --check --quiet; then
            log_security_event "AIDE integrity check failed" "CRITICAL"
        fi
    fi
}

check_network_connections() {
    local suspicious_connections=$(netstat -tuln | grep -E ":(22|80|443|8080|3389)" | wc -l)
    if [[ $suspicious_connections -gt 10 ]]; then
        log_security_event "High number of network connections: $suspicious_connections" "INFO"
    fi
}

# Main monitoring loop
case "$1" in
    "check")
        check_failed_logins
        check_privilege_escalation
        check_system_integrity
        check_network_connections
        ;;
    "status")
        tail -20 "$LOG_FILE" 2>/dev/null || echo "No security events logged"
        ;;
    *)
        echo "Usage: $0 {check|status}"
        exit 1
        ;;
esac
SECURITY_MONITOR

chmod +x /usr/local/bin/z13-security-monitor

# Create systemd service for security monitoring
cat > /etc/systemd/system/z13-security-monitor.service << 'MONITOR_SERVICE'
[Unit]
Description=Z13 Security Monitoring
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-security-monitor check
StandardOutput=journal
StandardError=journal
MONITOR_SERVICE

cat > /etc/systemd/system/z13-security-monitor.timer << 'MONITOR_TIMER'
[Unit]
Description=Run Z13 security monitoring every hour
Requires=z13-security-monitor.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
MONITOR_TIMER

systemctl enable z13-security-monitor.timer

PrintStatus "Security monitoring system created"
EOF
}

# Export functions for use by main script
export -f security_hardening_setup
export -f configure_apparmor
export -f configure_firewall
export -f configure_auditing
export -f configure_intrusion_detection
export -f configure_file_integrity
export -f configure_kernel_hardening
export -f configure_ssh_hardening
export -f create_security_monitoring
