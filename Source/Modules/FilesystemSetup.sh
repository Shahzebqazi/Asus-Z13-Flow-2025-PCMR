#!/bin/bash

# Core Filesystem Setup for stable branch

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
	PrintWarning "ZFS support requires the main installation script. Falling back to ext4."
	FILESYSTEM="ext4"
	setup_ext4_filesystem
}

setup_btrfs_filesystem() {
	PrintWarning "Btrfs support requires the main installation script. Falling back to ext4."
	FILESYSTEM="ext4"
	setup_ext4_filesystem
}


