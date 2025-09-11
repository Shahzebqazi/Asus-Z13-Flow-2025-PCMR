# Filesystem Setup Module
# Handles ZFS, Btrfs, and ext4 filesystem creation

# Function to setup ZFS
setup_zfs() {
    print_header "Setting up ZFS Filesystem"
    
    # Check available memory
    local mem_gb=$(free -g | awk 'NR==2{print $2}')
    if [[ $mem_gb -lt 2 ]]; then
        print_error "ZFS requires at least 2GB RAM. Available: ${mem_gb}GB"
        return 1
    fi
    
    # Create swap
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"
    
    # Create ZFS pool
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
    print_status "ZFS filesystem created successfully"
}

# Function to setup Btrfs
setup_btrfs() {
    print_header "Setting up Btrfs Filesystem"
    
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
    print_status "Btrfs filesystem created successfully"
}

# Function to setup ext4
setup_ext4() {
    print_header "Setting up ext4 Filesystem"
    
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
    print_status "ext4 filesystem created successfully"
}

# Main filesystem setup function
filesystem_setup() {
    print_header "Filesystem Setup"
    
    # Try ZFS first
    if [[ "$FILESYSTEM" == "zfs" ]]; then
        if setup_zfs; then
            print_status "ZFS setup completed"
            return 0
        else
            print_warning "ZFS setup failed, trying Btrfs..."
            FILESYSTEM="btrfs"
        fi
    fi
    
    # Try Btrfs
    if [[ "$FILESYSTEM" == "btrfs" ]]; then
        if setup_btrfs; then
            print_status "Btrfs setup completed"
            return 0
        else
            print_warning "Btrfs setup failed, trying ext4..."
            FILESYSTEM="ext4"
        fi
    fi
    
    # Fallback to ext4
    if setup_ext4; then
        print_status "ext4 setup completed (fallback)"
        return 0
    else
        print_error "All filesystem setup attempts failed"
        exit 1
    fi
}
