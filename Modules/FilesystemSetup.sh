# Filesystem Setup Module
# Handles ZFS, Btrfs, and ext4 filesystem creation

# Function to setup ZFS
setup_zfs() {
    PrintHeader "Setting up ZFS Filesystem"
    
    # Check available memory
    local mem_gb=$(free -g | awk 'NR==2{print $2}')
    if [[ $mem_gb -lt 2 ]]; then
        PrintError "ZFS requires at least 2GB RAM. Available: ${mem_gb}GB"
        return 1
    fi
    
    # Create swap
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"
    
    # Load ZFS modules with error checking
    PrintStatus "Loading ZFS kernel modules..."
    if ! modprobe zfs; then
        PrintError "Failed to load ZFS kernel modules"
        return 1
    fi
    
    # Verify ZFS is available
    if ! command -v zpool >/dev/null 2>&1; then
        PrintError "ZFS utilities not available after module loading"
        return 1
    fi
    
    # Create ZFS pool
    PrintStatus "Creating ZFS pool..."
    zpool create -f -o ashift=12 -o autotrim=on zroot "$ROOT_PART"
    
    # Create ZFS datasets
    zfs create -o mountpoint=none zroot/ROOT
    zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/default
    zfs create -o mountpoint=/home zroot/home
    zfs create -o mountpoint=/var zroot/var
    zfs create -o mountpoint=/var/log zroot/var/log
    zfs create -o mountpoint=/var/cache zroot/var/cache
    zfs create -o mountpoint=/var/lib/pacman zroot/var/lib/pacman
    
    # Set ZFS properties
    zfs set compression=zstd zroot
    zfs set atime=off zroot
    zfs set relatime=on zroot
    zfs set xattr=sa zroot
    zfs set dnodesize=auto zroot
    
    # Mount ZFS
    zfs mount zroot/ROOT/default
    zfs mount -a
    
    # Create directories
    mkdir -p /mnt/{boot,home,var/log,var/cache,var/lib/pacman}
    
    # Mount EFI
    mount "$EFI_PART" /mnt/boot
    
    FILESYSTEM_CREATED="zfs"
    CURRENT_FILESYSTEM="zfs"
    PrintStatus "ZFS filesystem created successfully"
}

# Function to setup Btrfs
setup_btrfs() {
    PrintHeader "Setting up Btrfs Filesystem"
    
    # Create swap
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"
    
    # Format Btrfs
    mkfs.btrfs -f "$ROOT_PART"
    
    # Mount root
    mount "$ROOT_PART" /mnt
    
    # Create subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@snapshots
    
    # Unmount and remount with subvolumes
    umount /mnt
    
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@ "$ROOT_PART" /mnt
    mkdir -p /mnt/{boot,home,var,.snapshots}
    
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@home "$ROOT_PART" /mnt/home
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@var "$ROOT_PART" /mnt/var
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@snapshots "$ROOT_PART" /mnt/.snapshots
    
    # Mount EFI
    mount "$EFI_PART" /mnt/boot
    
    FILESYSTEM_CREATED="btrfs"
    CURRENT_FILESYSTEM="btrfs"
    PrintStatus "Btrfs filesystem created successfully"
}

# Function to setup ext4
setup_ext4() {
    PrintHeader "Setting up ext4 Filesystem"
    
    # Create swap
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"
    
    # Format ext4
    mkfs.ext4 -F "$ROOT_PART"
    
    # Mount filesystems
    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot
    mount "$EFI_PART" /mnt/boot
    
    FILESYSTEM_CREATED="ext4"
    CURRENT_FILESYSTEM="ext4"
    PrintStatus "ext4 filesystem created successfully"
}

# Main filesystem setup function
filesystem_setup() {
    PrintHeader "Filesystem Setup"
    
    # Try ZFS first
    if [[ "$FILESYSTEM" == "zfs" ]]; then
        if setup_zfs; then
            PrintStatus "ZFS setup completed"
            return 0
        else
            PrintWarning "ZFS setup failed, trying Btrfs..."
            FILESYSTEM="btrfs"
        fi
    fi
    
    # Try Btrfs
    if [[ "$FILESYSTEM" == "btrfs" ]]; then
        if setup_btrfs; then
            PrintStatus "Btrfs setup completed"
            return 0
        else
            PrintWarning "Btrfs setup failed, trying ext4..."
            FILESYSTEM="ext4"
        fi
    fi
    
    # Fallback to ext4
    if setup_ext4; then
        PrintStatus "ext4 setup completed (fallback)"
        return 0
    else
        PrintError "All filesystem setup attempts failed"
        exit 1
    fi
}
