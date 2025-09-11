#!/bin/bash
# Backup and Recovery Module
# Comprehensive backup, snapshot, and disaster recovery system for ASUS ROG Flow Z13 (2025)

backup_recovery_setup() {
    PrintHeader "Backup and Recovery System Configuration"
    
    if [[ "$ENABLE_BACKUP_RECOVERY" != "true" ]]; then
        PrintStatus "Backup and recovery disabled in configuration, skipping..."
        return 0
    fi
    
    PrintStatus "Implementing comprehensive backup and recovery system..."
    
    # Install backup and recovery packages
    InstallPackageGroupWithVerification rsync borgbackup timeshift chroot
    InstallPackageGroupWithVerification snapper btrfs-progs zfs-utils chroot
    InstallPackageGroupWithVerification restic duplicity rclone chroot
    
    # Configure filesystem-specific snapshots
    configure_filesystem_snapshots
    
    # Configure automated backups
    configure_automated_backups
    
    # Configure system recovery
    configure_system_recovery
    
    # Configure disaster recovery
    configure_disaster_recovery
    
    # Create backup monitoring
    configure_backup_monitoring
    
    # Create recovery tools
    create_recovery_tools
    
    PrintStatus "Backup and recovery system configuration completed"
}

configure_filesystem_snapshots() {
    PrintStatus "Configuring filesystem snapshots..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Detect current filesystem and configure appropriate snapshot system
CURRENT_FS=$(findmnt -n -o FSTYPE /)

case "$CURRENT_FS" in
    "zfs")
        configure_zfs_snapshots
        ;;
    "btrfs")
        configure_btrfs_snapshots
        ;;
    "ext4")
        configure_timeshift_snapshots
        ;;
    *)
        PrintWarning "Unsupported filesystem for snapshots: $CURRENT_FS"
        configure_timeshift_snapshots  # Fallback
        ;;
esac

configure_zfs_snapshots() {
    PrintStatus "Configuring ZFS snapshots..."
    
    # Create ZFS snapshot script
    cat > /usr/local/bin/z13-zfs-snapshot << 'ZFS_SNAPSHOT'
#!/bin/bash
# Z13 ZFS Snapshot Manager

SNAPSHOT_LOG="/var/log/z13-snapshots.log"
ZFS_DATASET="zroot/ROOT/default"

log_snapshot() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SNAPSHOT_LOG"
}

create_snapshot() {
    local snapshot_type="$1"
    local description="$2"
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local snapshot_name="${ZFS_DATASET}@${snapshot_type}-${timestamp}"
    
    if zfs snapshot "$snapshot_name"; then
        log_snapshot "Created $snapshot_type snapshot: $snapshot_name - $description"
        
        # Set snapshot properties
        zfs set z13:type="$snapshot_type" "$snapshot_name"
        zfs set z13:description="$description" "$snapshot_name"
        zfs set z13:created="$(date)" "$snapshot_name"
        
        echo "$snapshot_name"
        return 0
    else
        log_snapshot "Failed to create $snapshot_type snapshot: $snapshot_name"
        return 1
    fi
}

list_snapshots() {
    local snapshot_type="$1"
    
    if [[ -n "$snapshot_type" ]]; then
        zfs list -t snapshot -o name,z13:type,z13:description,z13:created -H | grep "$snapshot_type"
    else
        zfs list -t snapshot -o name,z13:type,z13:description,z13:created -H
    fi
}

delete_old_snapshots() {
    local snapshot_type="$1"
    local keep_count="$2"
    
    local snapshots=($(zfs list -t snapshot -o name -H | grep "@${snapshot_type}-" | sort -r | tail -n +$((keep_count + 1))))
    
    for snapshot in "${snapshots[@]}"; do
        if zfs destroy "$snapshot"; then
            log_snapshot "Deleted old $snapshot_type snapshot: $snapshot"
        else
            log_snapshot "Failed to delete old $snapshot_type snapshot: $snapshot"
        fi
    done
}

rollback_snapshot() {
    local snapshot_name="$1"
    
    if [[ -z "$snapshot_name" ]]; then
        echo "Error: Snapshot name required"
        return 1
    fi
    
    echo "WARNING: This will rollback the system to snapshot: $snapshot_name"
    echo "All changes made after this snapshot will be lost!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        if zfs rollback "$snapshot_name"; then
            log_snapshot "Successfully rolled back to snapshot: $snapshot_name"
            echo "Rollback successful. Please reboot the system."
            return 0
        else
            log_snapshot "Failed to rollback to snapshot: $snapshot_name"
            return 1
        fi
    else
        echo "Rollback cancelled."
        return 1
    fi
}

case "$1" in
    "create")
        create_snapshot "$2" "$3"
        ;;
    "list")
        list_snapshots "$2"
        ;;
    "cleanup")
        delete_old_snapshots "auto" 10
        delete_old_snapshots "manual" 5
        delete_old_snapshots "pre-update" 3
        ;;
    "rollback")
        rollback_snapshot "$2"
        ;;
    *)
        echo "Usage: $0 {create|list|cleanup|rollback} [type] [description]"
        echo "Types: auto, manual, pre-update, pre-install"
        exit 1
        ;;
esac
ZFS_SNAPSHOT

    chmod +x /usr/local/bin/z13-zfs-snapshot
    
    # Create automatic snapshot timer
    cat > /etc/systemd/system/z13-zfs-auto-snapshot.service << 'ZFS_AUTO_SERVICE'
[Unit]
Description=Z13 ZFS Automatic Snapshot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-zfs-snapshot create auto "Automatic snapshot"
ExecStartPost=/usr/local/bin/z13-zfs-snapshot cleanup
StandardOutput=journal
StandardError=journal
ZFS_AUTO_SERVICE

    cat > /etc/systemd/system/z13-zfs-auto-snapshot.timer << 'ZFS_AUTO_TIMER'
[Unit]
Description=Create ZFS snapshots every 4 hours
Requires=z13-zfs-auto-snapshot.service

[Timer]
OnCalendar=0/4:00:00
Persistent=true

[Install]
WantedBy=timers.target
ZFS_AUTO_TIMER

    systemctl enable z13-zfs-auto-snapshot.timer
    log_snapshot "ZFS snapshot system configured"
}

configure_btrfs_snapshots() {
    PrintStatus "Configuring Btrfs snapshots with Snapper..."
    
    # Configure snapper for root filesystem
    snapper -c root create-config /
    
    # Configure snapper settings
    cat > /etc/snapper/configs/root << 'SNAPPER_CONFIG'
# Z13 Snapper Configuration for root filesystem

SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS=""
SYNC_ACL="no"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="10"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="24"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="4"
TIMELINE_LIMIT_MONTHLY="12"
TIMELINE_LIMIT_YEARLY="2"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
SNAPPER_CONFIG

    # Enable snapper services
    systemctl enable snapper-timeline.timer
    systemctl enable snapper-cleanup.timer
    
    # Create snapper wrapper script
    cat > /usr/local/bin/z13-btrfs-snapshot << 'BTRFS_SNAPSHOT'
#!/bin/bash
# Z13 Btrfs Snapshot Manager (Snapper wrapper)

case "$1" in
    "create")
        local description="$2"
        snapper -c root create --description "$description"
        ;;
    "list")
        snapper -c root list
        ;;
    "cleanup")
        snapper -c root cleanup number
        snapper -c root cleanup timeline
        ;;
    "rollback")
        local snapshot_num="$2"
        if [[ -z "$snapshot_num" ]]; then
            echo "Error: Snapshot number required"
            exit 1
        fi
        echo "WARNING: This will rollback the system to snapshot $snapshot_num"
        read -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            snapper -c root undochange "$snapshot_num..0"
        fi
        ;;
    *)
        echo "Usage: $0 {create|list|cleanup|rollback} [description|snapshot_num]"
        exit 1
        ;;
esac
BTRFS_SNAPSHOT

    chmod +x /usr/local/bin/z13-btrfs-snapshot
    PrintStatus "Btrfs snapshots configured with Snapper"
}

configure_timeshift_snapshots() {
    PrintStatus "Configuring Timeshift snapshots..."
    
    # Configure Timeshift
    mkdir -p /etc/timeshift
    cat > /etc/timeshift/timeshift.json << 'TIMESHIFT_CONFIG'
{
  "backup_device_uuid" : "",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "false",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "true",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "/home/*/.cache/**",
    "/home/*/.local/share/Trash/**",
    "/home/*/.thumbnails/**",
    "/var/cache/**",
    "/var/log/**",
    "/tmp/**"
  ],
  "exclude_apps" : []
}
TIMESHIFT_CONFIG

    # Create Timeshift wrapper script
    cat > /usr/local/bin/z13-timeshift-snapshot << 'TIMESHIFT_SNAPSHOT'
#!/bin/bash
# Z13 Timeshift Snapshot Manager

case "$1" in
    "create")
        local description="$2"
        timeshift --create --comments "$description"
        ;;
    "list")
        timeshift --list
        ;;
    "cleanup")
        timeshift --delete-all --older-than 30d
        ;;
    "rollback")
        local snapshot_name="$2"
        if [[ -z "$snapshot_name" ]]; then
            echo "Error: Snapshot name required"
            exit 1
        fi
        echo "WARNING: This will rollback the system to snapshot $snapshot_name"
        read -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            timeshift --restore --snapshot "$snapshot_name"
        fi
        ;;
    *)
        echo "Usage: $0 {create|list|cleanup|rollback} [description|snapshot_name]"
        exit 1
        ;;
esac
TIMESHIFT_SNAPSHOT

    chmod +x /usr/local/bin/z13-timeshift-snapshot
    
    # Enable Timeshift cron job
    systemctl enable cronie.service
    PrintStatus "Timeshift snapshots configured"
}

PrintStatus "Filesystem snapshots configured for $CURRENT_FS"
EOF
}

configure_automated_backups() {
    PrintStatus "Configuring automated backup system..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create comprehensive backup script
cat > /usr/local/bin/z13-backup-manager << 'BACKUP_MANAGER'
#!/bin/bash
# Z13 Comprehensive Backup Manager

BACKUP_LOG="/var/log/z13-backup.log"
BACKUP_CONFIG="/etc/z13/backup.conf"
BACKUP_BASE_DIR="/var/backups/z13"

# Default backup configuration
create_default_backup_config() {
    mkdir -p "$(dirname "$BACKUP_CONFIG")"
    
    cat > "$BACKUP_CONFIG" << 'BACKUP_CONFIG_CONTENT'
# Z13 Backup Configuration

# Backup destinations
LOCAL_BACKUP_DIR="/var/backups/z13"
REMOTE_BACKUP_ENABLED=false
REMOTE_BACKUP_HOST=""
REMOTE_BACKUP_USER=""
REMOTE_BACKUP_PATH=""

# Backup settings
BACKUP_COMPRESSION=true
BACKUP_ENCRYPTION=false
BACKUP_RETENTION_DAYS=30
BACKUP_VERIFY=true

# What to backup
BACKUP_SYSTEM_CONFIG=true
BACKUP_USER_DATA=true
BACKUP_APPLICATION_DATA=true
BACKUP_LOGS=false

# Backup paths
SYSTEM_PATHS="/etc /usr/local /opt"
USER_PATHS="/home"
APPLICATION_PATHS="/var/lib"
LOG_PATHS="/var/log"

# Exclusions
EXCLUDE_PATTERNS="
*.tmp
*.cache
*/.cache/*
*/Cache/*
*/cache/*
*/.thumbnails/*
*/Trash/*
*.iso
*.img
"
BACKUP_CONFIG_CONTENT
}

log_backup() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$BACKUP_LOG"
}

load_backup_config() {
    if [[ -f "$BACKUP_CONFIG" ]]; then
        source "$BACKUP_CONFIG"
    else
        create_default_backup_config
        source "$BACKUP_CONFIG"
    fi
}

create_backup_archive() {
    local backup_name="$1"
    local backup_paths="$2"
    local backup_dir="$3"
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local archive_name="${backup_name}-${timestamp}.tar"
    
    mkdir -p "$backup_dir"
    
    # Create exclusion file
    local exclude_file="/tmp/z13-backup-exclude.txt"
    echo "$EXCLUDE_PATTERNS" | grep -v "^$" > "$exclude_file"
    
    # Add compression if enabled
    local tar_opts="--create --file=${backup_dir}/${archive_name}"
    if [[ "$BACKUP_COMPRESSION" == "true" ]]; then
        tar_opts+=" --gzip"
        archive_name="${archive_name}.gz"
    fi
    
    # Add exclusions
    tar_opts+=" --exclude-from=$exclude_file"
    
    log_backup "INFO" "Creating backup: $backup_name"
    
    if tar $tar_opts $backup_paths 2>>"$BACKUP_LOG"; then
        log_backup "INFO" "Backup created successfully: ${backup_dir}/${archive_name}"
        
        # Verify backup if enabled
        if [[ "$BACKUP_VERIFY" == "true" ]]; then
            if tar --test-label --file="${backup_dir}/${archive_name}" >/dev/null 2>&1; then
                log_backup "INFO" "Backup verification passed: ${archive_name}"
            else
                log_backup "ERROR" "Backup verification failed: ${archive_name}"
                return 1
            fi
        fi
        
        echo "${backup_dir}/${archive_name}"
        return 0
    else
        log_backup "ERROR" "Backup creation failed: $backup_name"
        return 1
    fi
    
    rm -f "$exclude_file"
}

backup_system_config() {
    log_backup "INFO" "Starting system configuration backup"
    
    local backup_path=$(create_backup_archive "system-config" "$SYSTEM_PATHS" "$LOCAL_BACKUP_DIR/system")
    
    if [[ $? -eq 0 ]]; then
        log_backup "INFO" "System configuration backup completed: $backup_path"
        return 0
    else
        log_backup "ERROR" "System configuration backup failed"
        return 1
    fi
}

backup_user_data() {
    log_backup "INFO" "Starting user data backup"
    
    local backup_path=$(create_backup_archive "user-data" "$USER_PATHS" "$LOCAL_BACKUP_DIR/users")
    
    if [[ $? -eq 0 ]]; then
        log_backup "INFO" "User data backup completed: $backup_path"
        return 0
    else
        log_backup "ERROR" "User data backup failed"
        return 1
    fi
}

backup_application_data() {
    log_backup "INFO" "Starting application data backup"
    
    local backup_path=$(create_backup_archive "app-data" "$APPLICATION_PATHS" "$LOCAL_BACKUP_DIR/applications")
    
    if [[ $? -eq 0 ]]; then
        log_backup "INFO" "Application data backup completed: $backup_path"
        return 0
    else
        log_backup "ERROR" "Application data backup failed"
        return 1
    fi
}

cleanup_old_backups() {
    log_backup "INFO" "Cleaning up old backups (older than $BACKUP_RETENTION_DAYS days)"
    
    find "$LOCAL_BACKUP_DIR" -type f -name "*.tar*" -mtime +$BACKUP_RETENTION_DAYS -delete
    
    log_backup "INFO" "Old backup cleanup completed"
}

sync_remote_backup() {
    if [[ "$REMOTE_BACKUP_ENABLED" == "true" ]] && [[ -n "$REMOTE_BACKUP_HOST" ]]; then
        log_backup "INFO" "Syncing backups to remote location: $REMOTE_BACKUP_HOST"
        
        rsync -avz --delete "$LOCAL_BACKUP_DIR/" \
            "${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST}:${REMOTE_BACKUP_PATH}/" \
            >> "$BACKUP_LOG" 2>&1
        
        if [[ $? -eq 0 ]]; then
            log_backup "INFO" "Remote backup sync completed"
        else
            log_backup "ERROR" "Remote backup sync failed"
            return 1
        fi
    fi
}

full_backup() {
    log_backup "INFO" "Starting full system backup"
    
    load_backup_config
    
    local backup_success=true
    
    if [[ "$BACKUP_SYSTEM_CONFIG" == "true" ]]; then
        backup_system_config || backup_success=false
    fi
    
    if [[ "$BACKUP_USER_DATA" == "true" ]]; then
        backup_user_data || backup_success=false
    fi
    
    if [[ "$BACKUP_APPLICATION_DATA" == "true" ]]; then
        backup_application_data || backup_success=false
    fi
    
    cleanup_old_backups
    sync_remote_backup
    
    if [[ "$backup_success" == "true" ]]; then
        log_backup "INFO" "Full system backup completed successfully"
        return 0
    else
        log_backup "ERROR" "Full system backup completed with errors"
        return 1
    fi
}

list_backups() {
    echo "=== Z13 System Backups ==="
    echo ""
    
    for category in system users applications; do
        local backup_dir="$LOCAL_BACKUP_DIR/$category"
        if [[ -d "$backup_dir" ]]; then
            echo "[$category backups]"
            ls -lh "$backup_dir"/*.tar* 2>/dev/null | awk '{print $9, $5, $6, $7, $8}' || echo "No backups found"
            echo ""
        fi
    done
}

restore_backup() {
    local backup_file="$1"
    local restore_path="$2"
    
    if [[ -z "$backup_file" ]] || [[ ! -f "$backup_file" ]]; then
        echo "Error: Backup file not found: $backup_file"
        return 1
    fi
    
    if [[ -z "$restore_path" ]]; then
        restore_path="/"
    fi
    
    echo "WARNING: This will restore files from backup: $backup_file"
    echo "Restore destination: $restore_path"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        log_backup "INFO" "Starting restore from: $backup_file to: $restore_path"
        
        if tar --extract --file="$backup_file" --directory="$restore_path" 2>>"$BACKUP_LOG"; then
            log_backup "INFO" "Restore completed successfully"
            echo "Restore completed successfully"
            return 0
        else
            log_backup "ERROR" "Restore failed"
            echo "Restore failed - check log for details"
            return 1
        fi
    else
        echo "Restore cancelled"
        return 1
    fi
}

case "$1" in
    "full")
        full_backup
        ;;
    "system")
        load_backup_config
        backup_system_config
        ;;
    "users")
        load_backup_config
        backup_user_data
        ;;
    "apps")
        load_backup_config
        backup_application_data
        ;;
    "list")
        list_backups
        ;;
    "restore")
        restore_backup "$2" "$3"
        ;;
    "cleanup")
        load_backup_config
        cleanup_old_backups
        ;;
    "config")
        if [[ -f "$BACKUP_CONFIG" ]]; then
            echo "Current backup configuration:"
            cat "$BACKUP_CONFIG"
        else
            echo "Creating default backup configuration..."
            create_default_backup_config
            echo "Configuration created at: $BACKUP_CONFIG"
        fi
        ;;
    *)
        echo "Usage: $0 {full|system|users|apps|list|restore|cleanup|config}"
        echo ""
        echo "Commands:"
        echo "  full     - Complete system backup"
        echo "  system   - Backup system configuration only"
        echo "  users    - Backup user data only"
        echo "  apps     - Backup application data only"
        echo "  list     - List available backups"
        echo "  restore  - Restore from backup file"
        echo "  cleanup  - Remove old backups"
        echo "  config   - Show/create backup configuration"
        exit 1
        ;;
esac
BACKUP_MANAGER

chmod +x /usr/local/bin/z13-backup-manager

# Create automated backup service
cat > /etc/systemd/system/z13-automated-backup.service << 'AUTO_BACKUP_SERVICE'
[Unit]
Description=Z13 Automated Backup
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-backup-manager full
StandardOutput=journal
StandardError=journal
AUTO_BACKUP_SERVICE

cat > /etc/systemd/system/z13-automated-backup.timer << 'AUTO_BACKUP_TIMER'
[Unit]
Description=Run Z13 automated backup daily at 2 AM
Requires=z13-automated-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
AUTO_BACKUP_TIMER

systemctl enable z13-automated-backup.timer

PrintStatus "Automated backup system configured"
EOF
}

configure_system_recovery() {
    PrintStatus "Configuring system recovery tools..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create system recovery script
cat > /usr/local/bin/z13-recovery << 'RECOVERY_SCRIPT'
#!/bin/bash
# Z13 System Recovery Tool

RECOVERY_LOG="/var/log/z13-recovery.log"
RECOVERY_CONFIG="/etc/z13/recovery.conf"

log_recovery() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$RECOVERY_LOG"
}

create_recovery_media() {
    local device="$1"
    local iso_path="$2"
    
    if [[ -z "$device" ]] || [[ -z "$iso_path" ]]; then
        echo "Usage: create_recovery_media <device> <iso_path>"
        return 1
    fi
    
    echo "WARNING: This will erase all data on $device"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        log_recovery "Creating recovery media on $device from $iso_path"
        
        if dd if="$iso_path" of="$device" bs=4M status=progress oflag=sync; then
            log_recovery "Recovery media created successfully"
            echo "Recovery media created successfully"
            return 0
        else
            log_recovery "Failed to create recovery media"
            echo "Failed to create recovery media"
            return 1
        fi
    else
        echo "Operation cancelled"
        return 1
    fi
}

emergency_repair() {
    echo "=== Z13 Emergency Repair Mode ==="
    echo ""
    echo "Available repair options:"
    echo "1. Check filesystem integrity"
    echo "2. Repair bootloader"
    echo "3. Reset network configuration"
    echo "4. Restore from snapshot"
    echo "5. Restore from backup"
    echo "6. System log analysis"
    echo "7. Hardware diagnostics"
    echo ""
    
    read -p "Select repair option (1-7): " option
    
    case "$option" in
        1)
            repair_filesystem
            ;;
        2)
            repair_bootloader
            ;;
        3)
            reset_network_config
            ;;
        4)
            restore_from_snapshot
            ;;
        5)
            restore_from_backup
            ;;
        6)
            analyze_system_logs
            ;;
        7)
            run_hardware_diagnostics
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

repair_filesystem() {
    echo "Checking filesystem integrity..."
    log_recovery "Starting filesystem integrity check"
    
    # Check root filesystem
    local root_device=$(findmnt -n -o SOURCE /)
    echo "Checking root filesystem: $root_device"
    
    if fsck -f "$root_device"; then
        log_recovery "Filesystem check completed successfully"
        echo "Filesystem check completed successfully"
    else
        log_recovery "Filesystem errors detected and repaired"
        echo "Filesystem errors were found and repaired"
        echo "You may need to reboot the system"
    fi
}

repair_bootloader() {
    echo "Repairing bootloader..."
    log_recovery "Starting bootloader repair"
    
    # Check if we're using GRUB
    if command -v grub-install >/dev/null 2>&1; then
        # Find EFI partition
        local efi_partition=$(lsblk -rno NAME,PARTTYPE | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | cut -d' ' -f1 | head -1)
        
        if [[ -n "$efi_partition" ]]; then
            echo "Reinstalling GRUB to EFI partition: /dev/$efi_partition"
            
            # Mount EFI partition if not mounted
            if ! mountpoint -q /boot/efi; then
                mkdir -p /boot/efi
                mount "/dev/$efi_partition" /boot/efi
            fi
            
            # Reinstall GRUB
            if grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB; then
                grub-mkconfig -o /boot/grub/grub.cfg
                log_recovery "GRUB bootloader repaired successfully"
                echo "GRUB bootloader repaired successfully"
            else
                log_recovery "Failed to repair GRUB bootloader"
                echo "Failed to repair GRUB bootloader"
            fi
        else
            echo "EFI partition not found"
        fi
    else
        echo "GRUB not found - bootloader repair not available"
    fi
}

reset_network_config() {
    echo "Resetting network configuration..."
    log_recovery "Resetting network configuration"
    
    # Backup current configuration
    cp -r /etc/NetworkManager /etc/NetworkManager.backup.$(date +%Y%m%d-%H%M%S)
    
    # Reset NetworkManager configuration
    systemctl stop NetworkManager
    rm -rf /etc/NetworkManager/system-connections/*
    systemctl start NetworkManager
    
    log_recovery "Network configuration reset completed"
    echo "Network configuration reset completed"
    echo "You may need to reconfigure your network connections"
}

restore_from_snapshot() {
    echo "Available snapshots:"
    
    # Detect filesystem and show appropriate snapshots
    local current_fs=$(findmnt -n -o FSTYPE /)
    
    case "$current_fs" in
        "zfs")
            /usr/local/bin/z13-zfs-snapshot list
            echo ""
            read -p "Enter snapshot name to restore: " snapshot_name
            /usr/local/bin/z13-zfs-snapshot rollback "$snapshot_name"
            ;;
        "btrfs")
            /usr/local/bin/z13-btrfs-snapshot list
            echo ""
            read -p "Enter snapshot number to restore: " snapshot_num
            /usr/local/bin/z13-btrfs-snapshot rollback "$snapshot_num"
            ;;
        *)
            /usr/local/bin/z13-timeshift-snapshot list
            echo ""
            read -p "Enter snapshot name to restore: " snapshot_name
            /usr/local/bin/z13-timeshift-snapshot rollback "$snapshot_name"
            ;;
    esac
}

restore_from_backup() {
    echo "Available backups:"
    /usr/local/bin/z13-backup-manager list
    echo ""
    read -p "Enter full path to backup file: " backup_file
    read -p "Enter restore destination (default: /): " restore_path
    
    /usr/local/bin/z13-backup-manager restore "$backup_file" "$restore_path"
}

analyze_system_logs() {
    echo "=== System Log Analysis ==="
    echo ""
    
    echo "Recent critical errors:"
    journalctl --priority=crit --since "24 hours ago" --no-pager | tail -20
    echo ""
    
    echo "Recent kernel messages:"
    dmesg | tail -20
    echo ""
    
    echo "Failed systemd services:"
    systemctl --failed --no-pager
    echo ""
    
    echo "Disk usage:"
    df -h
    echo ""
    
    echo "Memory usage:"
    free -h
}

run_hardware_diagnostics() {
    echo "=== Hardware Diagnostics ==="
    echo ""
    
    echo "CPU information:"
    lscpu | head -10
    echo ""
    
    echo "Memory information:"
    lsmem 2>/dev/null || echo "Memory information not available"
    echo ""
    
    echo "Storage devices:"
    lsblk
    echo ""
    
    echo "SMART status:"
    for device in $(lsblk -d -n -o NAME | grep -E '^(sd|nvme)'); do
        echo "Device: /dev/$device"
        smartctl -H "/dev/$device" 2>/dev/null || echo "SMART not available"
        echo ""
    done
    
    echo "Network interfaces:"
    ip link show
    echo ""
    
    echo "Temperature sensors:"
    sensors 2>/dev/null || echo "Temperature sensors not available"
}

case "$1" in
    "emergency")
        emergency_repair
        ;;
    "create-media")
        create_recovery_media "$2" "$3"
        ;;
    "filesystem")
        repair_filesystem
        ;;
    "bootloader")
        repair_bootloader
        ;;
    "network")
        reset_network_config
        ;;
    "snapshot")
        restore_from_snapshot
        ;;
    "backup")
        restore_from_backup
        ;;
    "logs")
        analyze_system_logs
        ;;
    "hardware")
        run_hardware_diagnostics
        ;;
    *)
        echo "Z13 System Recovery Tool"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  emergency           - Interactive emergency repair menu"
        echo "  create-media        - Create recovery USB media"
        echo "  filesystem          - Check and repair filesystem"
        echo "  bootloader          - Repair GRUB bootloader"
        echo "  network             - Reset network configuration"
        echo "  snapshot            - Restore from snapshot"
        echo "  backup              - Restore from backup"
        echo "  logs                - Analyze system logs"
        echo "  hardware            - Run hardware diagnostics"
        exit 1
        ;;
esac
RECOVERY_SCRIPT

chmod +x /usr/local/bin/z13-recovery

PrintStatus "System recovery tools configured"
EOF
}

configure_disaster_recovery() {
    PrintStatus "Configuring disaster recovery procedures..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create disaster recovery documentation
mkdir -p /usr/share/doc/z13-recovery

cat > /usr/share/doc/z13-recovery/disaster-recovery-guide.md << 'DISASTER_RECOVERY_GUIDE'
# Z13 Disaster Recovery Guide

## Overview
This guide provides step-by-step procedures for recovering your ASUS ROG Flow Z13 (2025) system from various disaster scenarios.

## Prerequisites
- Z13 Recovery USB media (created with `z13-recovery create-media`)
- Recent system backups (automatically created by z13-backup-manager)
- System snapshots (automatically created by snapshot system)

## Recovery Scenarios

### 1. Boot Failure
**Symptoms:** System won't boot, GRUB errors, kernel panic

**Recovery Steps:**
1. Boot from Z13 Recovery USB
2. Run: `z13-recovery bootloader`
3. If that fails, run: `z13-recovery emergency`
4. Select option 2 (Repair bootloader)

### 2. Filesystem Corruption
**Symptoms:** File system errors, data corruption, read-only filesystem

**Recovery Steps:**
1. Boot from Z13 Recovery USB
2. Run: `z13-recovery filesystem`
3. If severe corruption, restore from snapshot:
   - Run: `z13-recovery snapshot`
   - Select most recent clean snapshot

### 3. System Configuration Issues
**Symptoms:** System boots but services fail, network issues, login problems

**Recovery Steps:**
1. Boot to single-user mode
2. Run: `z13-recovery emergency`
3. Select appropriate repair option
4. Or restore system configuration backup:
   ```bash
   z13-backup-manager restore /var/backups/z13/system/system-config-YYYYMMDD-HHMMSS.tar.gz /
   ```

### 4. Complete System Loss
**Symptoms:** Hard drive failure, accidental deletion, hardware replacement

**Recovery Steps:**
1. Install fresh Arch Linux system using Z13 installer
2. Restore from most recent full backup:
   ```bash
   z13-backup-manager restore /path/to/backup/full-backup.tar.gz /
   ```
3. Reconfigure bootloader and regenerate initramfs

### 5. Hardware Failure
**Symptoms:** Hardware errors, overheating, component failure

**Recovery Steps:**
1. Run hardware diagnostics:
   ```bash
   z13-recovery hardware
   ```
2. Check system logs:
   ```bash
   z13-recovery logs
   ```
3. If thermal issues, check TDP configuration:
   ```bash
   z13-tdp status
   ```

## Emergency Boot Options

### Recovery USB Boot
1. Insert Z13 Recovery USB
2. Boot and select "Emergency Recovery"
3. Access to all Z13 recovery tools

### Single User Mode
1. At GRUB menu, press 'e' to edit
2. Add 'single' to kernel parameters
3. Boot to single-user mode
4. Run recovery commands as root

### Live Environment
1. Boot from Arch Linux ISO
2. Mount existing system:
   ```bash
   mount /dev/nvme0n1p2 /mnt
   arch-chroot /mnt
   ```
3. Access all recovery tools

## Backup Verification
Before disaster strikes, regularly verify backups:

```bash
# List all backups
z13-backup-manager list

# Test backup integrity
tar -tzf /var/backups/z13/system/system-config-latest.tar.gz

# Verify snapshots
z13-zfs-snapshot list  # or z13-btrfs-snapshot list
```

## Prevention Tips
1. Enable automatic snapshots before system updates
2. Regularly test recovery procedures
3. Keep recovery USB updated
4. Monitor system health with z13-health-monitor
5. Address warnings before they become critical

## Emergency Contacts
- System logs: /var/log/z13-*.log
- Recovery documentation: /usr/share/doc/z13-recovery/
- Configuration backup: /var/backups/z13/system/
- Snapshots: Use z13-*-snapshot list commands

Remember: Always test recovery procedures in a safe environment before relying on them in an emergency.
DISASTER_RECOVERY_GUIDE

# Create disaster recovery checklist
cat > /usr/share/doc/z13-recovery/recovery-checklist.txt << 'RECOVERY_CHECKLIST'
Z13 Disaster Recovery Checklist

□ PREPARATION (Do this NOW, before problems occur)
  □ Create recovery USB media
  □ Verify backup system is working
  □ Test snapshot creation and restoration
  □ Document system configuration
  □ Note important file locations
  □ Record hardware specifications

□ IMMEDIATE RESPONSE (When disaster strikes)
  □ Don't panic - assess the situation calmly
  □ Document error messages and symptoms
  □ Try simple solutions first (reboot, check connections)
  □ Boot from recovery media if system won't start
  □ Check system logs for clues

□ RECOVERY PROCESS
  □ Identify the type of failure
  □ Choose appropriate recovery method
  □ Create additional backup before attempting recovery
  □ Follow step-by-step procedures
  □ Test system thoroughly after recovery
  □ Update documentation with lessons learned

□ POST-RECOVERY
  □ Verify all systems are working
  □ Update backups and snapshots
  □ Review what caused the problem
  □ Improve prevention measures
  □ Update recovery procedures if needed
RECOVERY_CHECKLIST

PrintStatus "Disaster recovery procedures documented"
EOF
}

configure_backup_monitoring() {
    PrintStatus "Configuring backup monitoring..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create backup monitoring script
cat > /usr/local/bin/z13-backup-monitor << 'BACKUP_MONITOR'
#!/bin/bash
# Z13 Backup Monitoring System

MONITOR_LOG="/var/log/z13-backup-monitor.log"
BACKUP_STATUS_FILE="/var/lib/z13-monitoring/backup-status.txt"

log_monitor() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG"
}

check_backup_health() {
    local issues=0
    
    echo "# Backup Health Report" > "$BACKUP_STATUS_FILE"
    echo "timestamp:$(date '+%Y-%m-%d %H:%M:%S')" >> "$BACKUP_STATUS_FILE"
    
    # Check if backup directory exists and is writable
    local backup_dir="/var/backups/z13"
    if [[ -d "$backup_dir" ]] && [[ -w "$backup_dir" ]]; then
        echo "backup_dir_status:OK" >> "$BACKUP_STATUS_FILE"
        log_monitor "INFO: Backup directory accessible"
    else
        echo "backup_dir_status:ERROR" >> "$BACKUP_STATUS_FILE"
        log_monitor "ERROR: Backup directory not accessible: $backup_dir"
        issues=$((issues + 1))
    fi
    
    # Check recent backup age
    local latest_backup=$(find "$backup_dir" -name "*.tar*" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    if [[ -n "$latest_backup" ]]; then
        local backup_age=$(( $(date +%s) - $(stat -c %Y "$latest_backup") ))
        local backup_age_hours=$((backup_age / 3600))
        
        echo "latest_backup:$latest_backup" >> "$BACKUP_STATUS_FILE"
        echo "backup_age_hours:$backup_age_hours" >> "$BACKUP_STATUS_FILE"
        
        if [[ $backup_age_hours -gt 48 ]]; then
            log_monitor "WARNING: Latest backup is $backup_age_hours hours old"
            echo "backup_freshness:WARNING" >> "$BACKUP_STATUS_FILE"
            issues=$((issues + 1))
        elif [[ $backup_age_hours -gt 24 ]]; then
            log_monitor "INFO: Latest backup is $backup_age_hours hours old"
            echo "backup_freshness:INFO" >> "$BACKUP_STATUS_FILE"
        else
            echo "backup_freshness:OK" >> "$BACKUP_STATUS_FILE"
        fi
    else
        log_monitor "ERROR: No backups found"
        echo "backup_freshness:ERROR" >> "$BACKUP_STATUS_FILE"
        issues=$((issues + 1))
    fi
    
    # Check backup service status
    if systemctl is-active z13-automated-backup.timer >/dev/null 2>&1; then
        echo "backup_service_status:OK" >> "$BACKUP_STATUS_FILE"
        log_monitor "INFO: Backup service is active"
    else
        echo "backup_service_status:ERROR" >> "$BACKUP_STATUS_FILE"
        log_monitor "ERROR: Backup service is not active"
        issues=$((issues + 1))
    fi
    
    # Check disk space for backups
    local backup_disk_usage=$(df "$backup_dir" | tail -1 | awk '{print $5}' | tr -d '%')
    echo "backup_disk_usage:$backup_disk_usage" >> "$BACKUP_STATUS_FILE"
    
    if [[ $backup_disk_usage -gt 90 ]]; then
        log_monitor "CRITICAL: Backup disk usage is $backup_disk_usage%"
        echo "backup_disk_space:CRITICAL" >> "$BACKUP_STATUS_FILE"
        issues=$((issues + 1))
    elif [[ $backup_disk_usage -gt 80 ]]; then
        log_monitor "WARNING: Backup disk usage is $backup_disk_usage%"
        echo "backup_disk_space:WARNING" >> "$BACKUP_STATUS_FILE"
        issues=$((issues + 1))
    else
        echo "backup_disk_space:OK" >> "$BACKUP_STATUS_FILE"
    fi
    
    # Check snapshot health (filesystem dependent)
    local current_fs=$(findmnt -n -o FSTYPE /)
    case "$current_fs" in
        "zfs")
            local snapshot_count=$(zfs list -t snapshot | wc -l)
            echo "snapshot_count:$snapshot_count" >> "$BACKUP_STATUS_FILE"
            if [[ $snapshot_count -gt 0 ]]; then
                echo "snapshot_status:OK" >> "$BACKUP_STATUS_FILE"
            else
                echo "snapshot_status:WARNING" >> "$BACKUP_STATUS_FILE"
                log_monitor "WARNING: No ZFS snapshots found"
                issues=$((issues + 1))
            fi
            ;;
        "btrfs")
            local snapshot_count=$(snapper -c root list | wc -l)
            echo "snapshot_count:$snapshot_count" >> "$BACKUP_STATUS_FILE"
            if [[ $snapshot_count -gt 1 ]]; then  # More than header line
                echo "snapshot_status:OK" >> "$BACKUP_STATUS_FILE"
            else
                echo "snapshot_status:WARNING" >> "$BACKUP_STATUS_FILE"
                log_monitor "WARNING: No Btrfs snapshots found"
                issues=$((issues + 1))
            fi
            ;;
        *)
            # Check Timeshift snapshots
            if command -v timeshift >/dev/null 2>&1; then
                local snapshot_count=$(timeshift --list | grep -c "snapshot")
                echo "snapshot_count:$snapshot_count" >> "$BACKUP_STATUS_FILE"
                if [[ $snapshot_count -gt 0 ]]; then
                    echo "snapshot_status:OK" >> "$BACKUP_STATUS_FILE"
                else
                    echo "snapshot_status:WARNING" >> "$BACKUP_STATUS_FILE"
                    log_monitor "WARNING: No Timeshift snapshots found"
                    issues=$((issues + 1))
                fi
            else
                echo "snapshot_status:N/A" >> "$BACKUP_STATUS_FILE"
            fi
            ;;
    esac
    
    # Overall status
    if [[ $issues -eq 0 ]]; then
        echo "overall_backup_status:OK" >> "$BACKUP_STATUS_FILE"
        log_monitor "INFO: All backup health checks passed"
    else
        echo "overall_backup_status:WARNING" >> "$BACKUP_STATUS_FILE"
        log_monitor "WARNING: $issues backup health issues detected"
    fi
    
    return $issues
}

generate_backup_report() {
    echo "=== Z13 Backup System Report ==="
    echo "Generated: $(date)"
    echo ""
    
    if [[ -f "$BACKUP_STATUS_FILE" ]]; then
        echo "Backup Status:"
        cat "$BACKUP_STATUS_FILE" | grep -v "^#" | while IFS=':' read -r key value; do
            echo "  $key: $value"
        done
    else
        echo "No backup status available. Run 'z13-backup-monitor check' first."
    fi
    
    echo ""
    echo "Recent Backup Activity:"
    tail -10 "/var/log/z13-backup.log" 2>/dev/null || echo "No backup activity logged"
    
    echo ""
    echo "Backup Storage Usage:"
    du -sh /var/backups/z13/* 2>/dev/null || echo "No backup data found"
}

case "$1" in
    "check")
        check_backup_health
        ;;
    "report")
        generate_backup_report
        ;;
    "status")
        if [[ -f "$BACKUP_STATUS_FILE" ]]; then
            echo "Current backup status:"
            grep "overall_backup_status:" "$BACKUP_STATUS_FILE" | cut -d':' -f2
        else
            echo "No backup status available"
        fi
        ;;
    *)
        echo "Usage: $0 {check|report|status}"
        exit 1
        ;;
esac
BACKUP_MONITOR

chmod +x /usr/local/bin/z13-backup-monitor

# Create backup monitoring service
cat > /etc/systemd/system/z13-backup-monitor.service << 'BACKUP_MONITOR_SERVICE'
[Unit]
Description=Z13 Backup Health Monitor
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/z13-backup-monitor check
StandardOutput=journal
StandardError=journal
BACKUP_MONITOR_SERVICE

cat > /etc/systemd/system/z13-backup-monitor.timer << 'BACKUP_MONITOR_TIMER'
[Unit]
Description=Run Z13 backup monitoring every 6 hours
Requires=z13-backup-monitor.service

[Timer]
OnCalendar=0/6:00:00
Persistent=true

[Install]
WantedBy=timers.target
BACKUP_MONITOR_TIMER

systemctl enable z13-backup-monitor.timer

PrintStatus "Backup monitoring configured"
EOF
}

create_recovery_tools() {
    PrintStatus "Creating additional recovery tools..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Create unified recovery management script
cat > /usr/local/bin/z13-recovery-manager << 'RECOVERY_MANAGER'
#!/bin/bash
# Z13 Recovery Management Tool - Unified interface for all recovery operations

show_recovery_menu() {
    clear
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                Z13 Recovery Management System                 ║"
    echo "║              ASUS ROG Flow Z13 (2025) Recovery               ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                                                               ║"
    echo "║  BACKUP & SNAPSHOTS                                           ║"
    echo "║    1. Create system snapshot                                  ║"
    echo "║    2. List available snapshots                                ║"
    echo "║    3. Create full system backup                               ║"
    echo "║    4. List available backups                                  ║"
    echo "║                                                               ║"
    echo "║  RECOVERY & RESTORE                                           ║"
    echo "║    5. Restore from snapshot                                   ║"
    echo "║    6. Restore from backup                                     ║"
    echo "║    7. Emergency system repair                                 ║"
    echo "║    8. Repair bootloader                                       ║"
    echo "║                                                               ║"
    echo "║  SYSTEM ANALYSIS                                              ║"
    echo "║    9. System health check                                     ║"
    echo "║   10. Hardware diagnostics                                    ║"
    echo "║   11. Analyze system logs                                     ║"
    echo "║   12. Backup system status                                    ║"
    echo "║                                                               ║"
    echo "║  MAINTENANCE                                                  ║"
    echo "║   13. Cleanup old snapshots/backups                          ║"
    echo "║   14. Create recovery USB                                     ║"
    echo "║   15. View recovery documentation                             ║"
    echo "║                                                               ║"
    echo "║    0. Exit                                                    ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

handle_menu_choice() {
    local choice="$1"
    
    case "$choice" in
        1)
            echo "Creating system snapshot..."
            create_snapshot_interactive
            ;;
        2)
            echo "Available snapshots:"
            list_snapshots_interactive
            ;;
        3)
            echo "Creating full system backup..."
            z13-backup-manager full
            ;;
        4)
            echo "Available backups:"
            z13-backup-manager list
            ;;
        5)
            echo "Restoring from snapshot..."
            restore_snapshot_interactive
            ;;
        6)
            echo "Restoring from backup..."
            restore_backup_interactive
            ;;
        7)
            echo "Starting emergency repair..."
            z13-recovery emergency
            ;;
        8)
            echo "Repairing bootloader..."
            z13-recovery bootloader
            ;;
        9)
            echo "Running system health check..."
            z13-health-monitor check
            z13-health-monitor status
            ;;
        10)
            echo "Running hardware diagnostics..."
            z13-recovery hardware
            ;;
        11)
            echo "Analyzing system logs..."
            z13-recovery logs
            ;;
        12)
            echo "Checking backup system status..."
            z13-backup-monitor report
            ;;
        13)
            echo "Cleaning up old snapshots and backups..."
            cleanup_old_data
            ;;
        14)
            echo "Creating recovery USB..."
            create_recovery_usb_interactive
            ;;
        15)
            echo "Viewing recovery documentation..."
            view_recovery_docs
            ;;
        0)
            echo "Exiting recovery manager..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
}

create_snapshot_interactive() {
    read -p "Enter snapshot description: " description
    
    # Detect filesystem and create appropriate snapshot
    local current_fs=$(findmnt -n -o FSTYPE /)
    case "$current_fs" in
        "zfs")
            z13-zfs-snapshot create manual "$description"
            ;;
        "btrfs")
            z13-btrfs-snapshot create "$description"
            ;;
        *)
            z13-timeshift-snapshot create "$description"
            ;;
    esac
}

list_snapshots_interactive() {
    local current_fs=$(findmnt -n -o FSTYPE /)
    case "$current_fs" in
        "zfs")
            z13-zfs-snapshot list
            ;;
        "btrfs")
            z13-btrfs-snapshot list
            ;;
        *)
            z13-timeshift-snapshot list
            ;;
    esac
}

restore_snapshot_interactive() {
    echo "Available snapshots:"
    list_snapshots_interactive
    echo ""
    
    local current_fs=$(findmnt -n -o FSTYPE /)
    case "$current_fs" in
        "zfs")
            read -p "Enter ZFS snapshot name to restore: " snapshot_name
            z13-zfs-snapshot rollback "$snapshot_name"
            ;;
        "btrfs")
            read -p "Enter Btrfs snapshot number to restore: " snapshot_num
            z13-btrfs-snapshot rollback "$snapshot_num"
            ;;
        *)
            read -p "Enter Timeshift snapshot name to restore: " snapshot_name
            z13-timeshift-snapshot rollback "$snapshot_name"
            ;;
    esac
}

restore_backup_interactive() {
    echo "Available backups:"
    z13-backup-manager list
    echo ""
    
    read -p "Enter full path to backup file: " backup_file
    read -p "Enter restore destination (default: /): " restore_path
    restore_path=${restore_path:-/}
    
    z13-backup-manager restore "$backup_file" "$restore_path"
}

cleanup_old_data() {
    echo "Cleaning up old snapshots..."
    local current_fs=$(findmnt -n -o FSTYPE /)
    case "$current_fs" in
        "zfs")
            z13-zfs-snapshot cleanup
            ;;
        "btrfs")
            snapper -c root cleanup number
            snapper -c root cleanup timeline
            ;;
        *)
            # Timeshift cleanup is handled automatically
            echo "Timeshift cleanup is automatic"
            ;;
    esac
    
    echo "Cleaning up old backups..."
    z13-backup-manager cleanup
}

create_recovery_usb_interactive() {
    echo "Available USB devices:"
    lsblk -d -n -p -o NAME,SIZE,MODEL | grep -E "(sd|nvme)" | grep -v "$(findmnt -n -o SOURCE /)"
    echo ""
    
    read -p "Enter device path (e.g., /dev/sdb): " device
    read -p "Enter path to Arch Linux ISO: " iso_path
    
    if [[ -f "$iso_path" ]]; then
        z13-recovery create-media "$device" "$iso_path"
    else
        echo "ISO file not found: $iso_path"
    fi
}

view_recovery_docs() {
    if command -v less >/dev/null 2>&1; then
        less /usr/share/doc/z13-recovery/disaster-recovery-guide.md
    else
        cat /usr/share/doc/z13-recovery/disaster-recovery-guide.md
    fi
}

# Main interactive loop
main_interactive() {
    while true; do
        show_recovery_menu
        read -p "Enter your choice (0-15): " choice
        echo ""
        
        handle_menu_choice "$choice"
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Command line interface
case "$1" in
    "menu"|"")
        main_interactive
        ;;
    "status")
        echo "=== Z13 Recovery System Status ==="
        echo ""
        echo "Snapshot System:"
        list_snapshots_interactive | wc -l | xargs echo "  Available snapshots:"
        echo ""
        echo "Backup System:"
        z13-backup-monitor status
        echo ""
        echo "System Health:"
        z13-health-monitor status | grep "overall_status" || echo "  Status: Unknown"
        ;;
    *)
        echo "Z13 Recovery Management Tool"
        echo ""
        echo "Usage: $0 [menu|status]"
        echo ""
        echo "  menu    - Interactive recovery menu (default)"
        echo "  status  - Show recovery system status"
        ;;
esac
RECOVERY_MANAGER

chmod +x /usr/local/bin/z13-recovery-manager

# Create desktop shortcut for recovery manager
mkdir -p /usr/share/applications
cat > /usr/share/applications/z13-recovery-manager.desktop << 'RECOVERY_DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Z13 Recovery Manager
Comment=Comprehensive recovery and backup management for Z13
Exec=sudo z13-recovery-manager menu
Icon=system-software-update
Terminal=true
Categories=System;Settings;
Keywords=recovery;backup;snapshot;restore;
RECOVERY_DESKTOP

PrintStatus "Recovery tools created"
EOF
}

# Export functions for use by main script
export -f backup_recovery_setup
export -f configure_filesystem_snapshots
export -f configure_automated_backups
export -f configure_system_recovery
export -f configure_disaster_recovery
export -f configure_backup_monitoring
export -f create_recovery_tools
