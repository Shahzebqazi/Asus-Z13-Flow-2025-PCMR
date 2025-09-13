#!/bin/bash

# Core Disk Management for stable branch
# Sets up disk variables and prompts for Fresh vs Dual-boot

# Removed require_cmd - using inline command checks instead

print_disks() {
    echo "NAME                                   SIZE  TYPE  FSTYPE  CLASS        MOUNTPOINT"
    echo "-------------------------------------------------------------------------------------"
    # Use lsblk key="val" pairs to reduce parsing ambiguity
    lsblk -rp -o NAME,SIZE,TYPE,FSTYPE,PARTTYPE,MOUNTPOINT | while IFS= read -r line; do
        # Fields are space-separated and safe with -p; extract with awk
        name=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        type=$(echo "$line" | awk '{print $3}')
        fstype=$(echo "$line" | awk '{print $4}')
        parttype=$(echo "$line" | awk '{print $5}')
        mnt=$(echo "$line" | awk '{print $6}')

        class=""
        pt=$(echo "$parttype" | tr '[:upper:]' '[:lower:]')
        case "$pt" in
            c12a7328-f81f-11d2-ba4b-00a0c93ec93b) class="EFI" ;;
            e3c9e316-0b5c-4db8-817d-f92df00215ae) class="MSR" ;;
            ebd0a0a2-b9e5-4433-87c0-68b6b72699c7) class="Windows-Data" ;;
            0fc63daf-8483-4772-8e79-3d69d8477de4) class="Linux-Filesystem" ;;
            0657fd6d-a4ab-43c4-84e5-0933c84b4f4f) class="Linux-Swap" ;;
            21686148-6449-6e6f-744e-656564454649) class="BIOS-Boot" ;;
            *) class="" ;;
        esac

        if [[ -z "$class" && "$type" == "part" ]]; then
            case "$fstype" in
                ntfs) class="Windows-NTFS" ;;
                vfat|fat32|fat) class="EFI-or-FAT" ;;
                ext4|btrfs|xfs) class="Linux-FS" ;;
                swap) class="Linux-Swap" ;;
                *) class="Unknown" ;;
            esac
        fi

        printf "  %-38s %-5s %-5s %-7s %-12s %s\n" "$name" "$size" "$type" "${fstype:--}" "$class" "${mnt:-}"
    done
}

select_install_type() {
    if [[ -n "$DUAL_BOOT_MODE" ]]; then
        PrintStatus "Install type preselected: $DUAL_BOOT_MODE"
        return
    fi
    echo "Select installation type:"
    echo "  1) Fresh install (use entire disk)"
    echo "  2) Dual-boot with Windows (preserve existing Windows)"
    local choice
    while true; do
        read -p "Enter choice (1-2): " choice < "$TTY_INPUT" || true
        case "$choice" in
            1)
                DUAL_BOOT_MODE="new"
                break
                ;;
            2)
                DUAL_BOOT_MODE="gpt"
                break
                ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

select_disk() {
    echo "Available disks (with partition classification):"
    print_disks
    echo ""
    if [[ "$DUAL_BOOT_MODE" == "new" ]]; then
        echo "Target disk = physical drive that will be wiped and repartitioned for Arch."
    else
        echo "Target disk = physical drive containing Windows (we will preserve Windows and ESP)."
    fi
    while true; do
        read -p "Enter target disk (e.g., /dev/nvme0n1): " DISK_DEVICE < "$TTY_INPUT" || true
        if [[ -b "$DISK_DEVICE" ]]; then
            break
        else
            echo "Not a valid block device."
        fi
    done
}

confirm_destructive_action() {
    echo "WARNING: This will modify disk partitions on $DISK_DEVICE."
    read -p "Type 'YES' to continue: " confirm < "$TTY_INPUT" || true
    [[ "$confirm" == "YES" ]] || HandleFatalError "User aborted at disk confirmation"
}

validate_partition_exists() {
    local partition="$1"
    local description="$2"
    local max_attempts=10
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if [[ -b "$partition" ]]; then
            PrintStatus "$description partition validated: $partition"
            return 0
        fi
        ((attempt++))
        PrintStatus "Waiting for $description partition to appear... (attempt $attempt/$max_attempts)"
        sleep 1
        partprobe "$DISK_DEVICE" 2>/dev/null || true
    done
    
    HandleFatalError "$description partition not found: $partition"
}

prepare_partitions() {
    if [[ "$DUAL_BOOT_MODE" == "new" ]]; then
        PrintStatus "Partitioning disk for fresh install"
        
        # Check required commands
        for cmd in sgdisk partprobe; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                HandleFatalError "Required command not found: $cmd"
            fi
        done
        
        # Validate disk exists and is not mounted
        [[ -b "$DISK_DEVICE" ]] || HandleFatalError "Disk device not found: $DISK_DEVICE"
        
        # Check if disk is in use
        if lsblk "$DISK_DEVICE" | grep -q "MOUNTPOINT"; then
            local mounted_parts=$(lsblk "$DISK_DEVICE" -o NAME,MOUNTPOINT | grep -v "^$DISK_DEVICE" | grep -v "^\s*$" | wc -l)
            if [[ $mounted_parts -gt 0 ]]; then
                PrintWarning "Disk $DISK_DEVICE has mounted partitions. Attempting to unmount..."
                umount -R "${DISK_DEVICE}"* 2>/dev/null || true
            fi
        fi
        
        # Wipe and create GPT with ESP + root + swap
        PrintStatus "Wiping disk and creating new partition table"
        sgdisk --zap-all "$DISK_DEVICE" || HandleFatalError "Failed to wipe disk"
        partprobe "$DISK_DEVICE"
        sleep 2
        
        PrintStatus "Creating EFI System Partition (300MB)"
        sgdisk -n 1:0:+300M -t 1:EF00 -c 1:"EFI System" "$DISK_DEVICE" || HandleFatalError "Failed to create EFI partition"
        
        PrintStatus "Creating Linux Root Partition"
        sgdisk -n 2:0:-8G -t 2:8300 -c 2:"Linux Root" "$DISK_DEVICE" || HandleFatalError "Failed to create root partition"
        
        PrintStatus "Creating Linux Swap Partition (8GB)"
        sgdisk -n 3:0:0 -t 3:8200 -c 3:"Linux Swap" "$DISK_DEVICE" || HandleFatalError "Failed to create swap partition"
        
        partprobe "$DISK_DEVICE"
        sleep 2
        
        # Determine partition naming scheme
        if [[ "$DISK_DEVICE" =~ nvme ]]; then
            EFI_PART="${DISK_DEVICE}p1"
            ROOT_PART="${DISK_DEVICE}p2"
            SWAP_PART="${DISK_DEVICE}p3"
        else
            EFI_PART="${DISK_DEVICE}1"
            ROOT_PART="${DISK_DEVICE}2"
            SWAP_PART="${DISK_DEVICE}3"
        fi
        
        # Validate all partitions exist
        validate_partition_exists "$EFI_PART" "EFI"
        validate_partition_exists "$ROOT_PART" "Root"
        validate_partition_exists "$SWAP_PART" "Swap"
    else
        PrintStatus "Setting up for dual-boot (GPT)"
        # Detect ESP with better error handling
        PrintStatus "Detecting existing EFI System Partition..."
        local efi_candidates=()
        
        # Use lsblk to find EFI partitions
        while IFS= read -r line; do
            local part_name=$(echo "$line" | awk '{print $1}')
            local part_type=$(echo "$line" | awk '{print $2}')
            if [[ "$part_type" =~ ^[cC]12[aA]7328-[fF]81[fF]-11[dD]2-[bB][aA]4[bB]-00[aA]0[cC]93[eE][cC]93[bB]$ ]]; then
                efi_candidates+=("/dev/$part_name")
            fi
        done < <(lsblk -rno NAME,PARTTYPE "$DISK_DEVICE" 2>/dev/null || true)
        
        # Fallback: check by filesystem type
        if [[ ${#efi_candidates[@]} -eq 0 ]]; then
            while IFS= read -r line; do
                local part_name=$(echo "$line" | awk '{print $1}')
                local fs_type=$(echo "$line" | awk '{print $2}')
                if [[ "$fs_type" =~ ^(vfat|fat32)$ ]]; then
                    local part_size=$(lsblk -b "/dev/$part_name" -o SIZE --noheadings 2>/dev/null | head -1)
                    local size_mb=$((part_size / 1024 / 1024))
                    # Assume FAT32 partitions >50MB are likely ESP
                    if [[ $size_mb -gt 50 ]]; then
                        efi_candidates+=("/dev/$part_name")
                    fi
                fi
            done < <(lsblk -rno NAME,FSTYPE "$DISK_DEVICE" 2>/dev/null || true)
        fi
        
        if [[ ${#efi_candidates[@]} -eq 0 ]]; then
            HandleFatalError "No EFI System Partition found on $DISK_DEVICE. For dual-boot, Windows must be installed first with a proper ESP."
        elif [[ ${#efi_candidates[@]} -eq 1 ]]; then
            EFI_PART="${efi_candidates[0]}"
            PrintStatus "Found EFI partition: $EFI_PART"
        else
            PrintStatus "Multiple EFI partitions found:"
            for i in "${!efi_candidates[@]}"; do
                local part="${efi_candidates[$i]}"
                local size=$(lsblk -h "$part" -o SIZE --noheadings 2>/dev/null | head -1)
                echo "  $((i+1))) $part (${size:-unknown size})"
            done
            while true; do
                read -p "Select EFI partition (1-${#efi_candidates[@]}): " choice < "$TTY_INPUT" || true
                if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#efi_candidates[@]} ]]; then
                    EFI_PART="${efi_candidates[$((choice-1))]}"
                    PrintStatus "Selected EFI partition: $EFI_PART"
                    break
                else
                    echo "Invalid choice. Please enter a number between 1 and ${#efi_candidates[@]}"
                fi
            done
        fi
        echo "Existing partitions on $DISK_DEVICE:"; print_disks
        while true; do
            read -p "Enter Linux root partition (e.g., /dev/nvme0n1p5): " ROOT_PART < "$TTY_INPUT" || true
            [[ -b "$ROOT_PART" ]] && break || echo "Invalid partition"
        done
        read -p "Enter swap partition (optional, blank to skip): " SWAP_PART < "$TTY_INPUT" || true
        if [[ -n "$SWAP_PART" && ! -b "$SWAP_PART" ]]; then
            HandleValidationError "Invalid swap partition"
        fi
    fi
}

format_partitions() {
    PrintStatus "Formatting partitions"
    if [[ "$DUAL_BOOT_MODE" == "new" ]]; then
        PrintStatus "Formatting EFI partition"
        mkfs.fat -F32 "$EFI_PART" || HandleFatalError "Failed to format EFI partition"
    else
        PrintStatus "Preserving existing EFI System Partition at $EFI_PART"
    fi
    
    # Note: Root filesystem formatting and swap setup is handled by FilesystemSetup.sh
    PrintStatus "Root partition and swap will be formatted by filesystem setup module"
}

mount_partitions() {
    PrintStatus "Partition setup complete"
    
    # Note: All mounting is handled by FilesystemSetup.sh which understands different filesystem types
    PrintStatus "Partition mounting will be handled by filesystem setup module"
}

# Entry called by main script
disk_management_setup() {
    PrintHeader "Disk Management"
    select_install_type
    select_disk
    confirm_destructive_action
    prepare_partitions
    format_partitions
    mount_partitions
    PrintStatus "Disk management completed"
}
