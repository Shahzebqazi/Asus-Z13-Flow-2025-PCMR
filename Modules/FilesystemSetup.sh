#!/bin/bash

# Core Filesystem Setup for stable branch

setup_ext4_filesystem() {
    PrintStatus "Setting up ext4 filesystem"
    
    # Unmount if already mounted
    umount "$ROOT_PART" 2>/dev/null || true
    
    mkfs.ext4 -F "$ROOT_PART" || HandleFatalError "Failed to create ext4 filesystem"
    mount "$ROOT_PART" /mnt || HandleFatalError "Failed to mount root partition"
    
    # Create boot directory
    mkdir -p /mnt/boot
    
    # Mount EFI partition if specified
    if [[ -n "$EFI_PART" ]]; then
        # Unmount if already mounted elsewhere
        umount "$EFI_PART" 2>/dev/null || true
        mount "$EFI_PART" /mnt/boot || HandleFatalError "Failed to mount EFI partition"
    fi
    
    # Handle swap (only if not already active)
    if [[ -n "$SWAP_PART" ]]; then
        if ! swapon --show | grep -q "$SWAP_PART"; then
            mkswap "$SWAP_PART" || HandleFatalError "Failed to create swap"
            swapon "$SWAP_PART" || HandleFatalError "Failed to activate swap"
        else
            PrintStatus "Swap already active on $SWAP_PART"
        fi
    fi
}

setup_zfs_filesystem() {
    PrintStatus "Setting up ZFS filesystem"
    
    # Validate that ZFS packages are available before proceeding
    local zfs_pkg="zfs-linux"
    if [[ "$USE_ZEN_KERNEL" == true ]]; then
        zfs_pkg="zfs-linux-zen"
    fi
    
    # Check if ZFS is already installed in live environment
    if ! command -v zpool >/dev/null 2>&1; then
        PrintStatus "Installing ZFS utilities in live environment"
        pacman -Sy --noconfirm $zfs_pkg zfs-utils || HandleFatalError "Failed to install ZFS packages in live environment"
    fi
    
    # Load ZFS module
    modprobe zfs || HandleFatalError "Failed to load ZFS module"
    
    # Validate root partition exists and is not in use
    [[ -b "$ROOT_PART" ]] || HandleFatalError "Root partition not found: $ROOT_PART"
    
    # Check if partition is already part of a ZFS pool
    if zpool status 2>/dev/null | grep -q "$ROOT_PART"; then
        PrintWarning "Partition $ROOT_PART is already part of a ZFS pool. Destroying existing pool..."
        local existing_pool=$(zpool status 2>/dev/null | grep -B5 "$ROOT_PART" | grep "pool:" | awk '{print $2}' | head -1)
        if [[ -n "$existing_pool" ]]; then
            zpool destroy -f "$existing_pool" || PrintWarning "Failed to destroy existing pool $existing_pool"
        fi
    fi
    
    # Create ZFS pool with optimized settings for Strix Halo
    PrintStatus "Creating ZFS pool 'zroot' with AMD Strix Halo optimizations"
    zpool create -f -o ashift=12 \
        -o autotrim=on \
        -O acltype=posixacl \
        -O relatime=on \
        -O xattr=sa \
        -O dnodesize=auto \
        -O normalization=formD \
        -O mountpoint=none \
        -O canmount=off \
        -O devices=off \
        -O compression=zstd \
        -O recordsize=1M \
        -R /mnt zroot "$ROOT_PART" || HandleFatalError "Failed to create ZFS pool"
    
    # Verify pool creation
    zpool status zroot >/dev/null 2>&1 || HandleFatalError "ZFS pool creation verification failed"
    PrintStatus "ZFS pool 'zroot' created successfully"
    
    # Create ZFS datasets
    PrintStatus "Creating ZFS datasets"
    zfs create -o mountpoint=none zroot/ROOT || HandleFatalError "Failed to create ROOT dataset"
    zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/default || HandleFatalError "Failed to create default dataset"
    zfs create -o mountpoint=/home zroot/home || HandleFatalError "Failed to create home dataset"
    zfs create -o mountpoint=/var/log zroot/var-log || HandleFatalError "Failed to create var-log dataset"
    zfs create -o mountpoint=/var/cache zroot/var-cache || HandleFatalError "Failed to create var-cache dataset"
    
    # Set bootfs property
    zpool set bootfs=zroot/ROOT/default zroot || HandleFatalError "Failed to set bootfs property"
    
    # Mount datasets
    PrintStatus "Mounting ZFS datasets"
    zfs mount zroot/ROOT/default || HandleFatalError "Failed to mount root dataset"
    zfs mount -a || HandleFatalError "Failed to mount ZFS datasets"
    
    # Create mountpoint for EFI
    mkdir -p /mnt/boot
    
    # Mount EFI partition first before setting up swap
    if [[ -n "$EFI_PART" ]]; then
        # Unmount if already mounted elsewhere
        umount "$EFI_PART" 2>/dev/null || true
        mount "$EFI_PART" /mnt/boot || HandleFatalError "Failed to mount EFI partition"
    fi
    
    # Setup swap if specified
    if [[ -n "$SWAP_PART" ]]; then
        if ! swapon --show | grep -q "$SWAP_PART"; then
            mkswap "$SWAP_PART" || HandleFatalError "Failed to create swap"
            swapon "$SWAP_PART" || HandleFatalError "Failed to activate swap"
        else
            PrintStatus "Swap already active on $SWAP_PART"
        fi
    fi
}

setup_btrfs_filesystem() {
    PrintStatus "Setting up Btrfs filesystem"
    
    # Create Btrfs filesystem
    mkfs.btrfs -f "$ROOT_PART" || HandleFatalError "Failed to create Btrfs filesystem"
    
    # Mount root to create subvolumes
    mount "$ROOT_PART" /mnt || HandleFatalError "Failed to mount Btrfs root"
    
    # Create subvolumes
    btrfs subvolume create /mnt/@ || HandleFatalError "Failed to create @ subvolume"
    btrfs subvolume create /mnt/@home || HandleFatalError "Failed to create @home subvolume"
    btrfs subvolume create /mnt/@var || HandleFatalError "Failed to create @var subvolume"
    btrfs subvolume create /mnt/@snapshots || HandleFatalError "Failed to create @snapshots subvolume"
    
    # Unmount and remount with proper subvolumes
    umount /mnt
    mount -o subvol=@,compress=zstd,noatime "$ROOT_PART" /mnt || HandleFatalError "Failed to mount @ subvolume"
    
    # Create directories and mount other subvolumes
    mkdir -p /mnt/{home,var,snapshots,boot}
    mount -o subvol=@home,compress=zstd,noatime "$ROOT_PART" /mnt/home || HandleFatalError "Failed to mount @home"
    mount -o subvol=@var,compress=zstd,noatime "$ROOT_PART" /mnt/var || HandleFatalError "Failed to mount @var"
    mount -o subvol=@snapshots,compress=zstd,noatime "$ROOT_PART" /mnt/snapshots || HandleFatalError "Failed to mount @snapshots"
    
    # Setup swap if specified
    if [[ -n "$SWAP_PART" ]]; then
        mkswap "$SWAP_PART" || HandleFatalError "Failed to create swap"
        swapon "$SWAP_PART" || HandleFatalError "Failed to activate swap"
    fi
    
    # Mount EFI partition
    if [[ -n "$EFI_PART" ]]; then
        mount "$EFI_PART" /mnt/boot || HandleFatalError "Failed to mount EFI partition"
    fi
}

filesystem_setup() {
    PrintHeader "Filesystem Setup"
    
    # Ensure partition variables are set
    if [[ -z "$ROOT_PART" ]]; then
        HandleFatalError "ROOT_PART not set. Run disk management first."
    fi

    case "$FILESYSTEM" in
        zfs|ZFS)
            PrintStatus "Using ZFS for root filesystem"
            setup_zfs_filesystem
            FILESYSTEM_CREATED="zfs"
            CURRENT_FILESYSTEM="zfs"
            ;;
        btrfs|BTRFS)
            PrintStatus "Using Btrfs for root filesystem"
            setup_btrfs_filesystem
            FILESYSTEM_CREATED="btrfs"
            CURRENT_FILESYSTEM="btrfs"
            ;;
        ext4|EXT4|*)
            PrintStatus "Using ext4 for root filesystem"
            setup_ext4_filesystem
            FILESYSTEM_CREATED="ext4"
            CURRENT_FILESYSTEM="ext4"
            ;;
    esac
    
    PrintStatus "Filesystem setup completed: $CURRENT_FILESYSTEM"
}
