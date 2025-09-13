#!/bin/bash

# Core Disk Management for stable branch
# Sets up disk variables and prompts for Fresh vs Dual-boot

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1"; exit 1; }
}

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

# Enhanced EFI partition detection with multiple methods
detect_efi_partitions() {
	local disk_device="$1"
	local efi_candidates=()
	
	PrintStatus "Detecting EFI System Partitions on $disk_device..."
	
	# Method 1: Check by partition type GUID (most reliable)
	while IFS= read -r line; do
		local part_name=$(echo "$line" | awk '{print $1}')
		local part_type=$(echo "$line" | awk '{print $2}')
		if [[ "$part_type" =~ ^[cC]12[aA]7328-[fF]81[fF]-11[dD]2-[bB][aA]4[bB]-00[aA]0[cC]93[eE][cC]93[bB]$ ]]; then
			efi_candidates+=("/dev/$part_name")
		fi
	done < <(lsblk -rno NAME,PARTTYPE "$disk_device" 2>/dev/null || true)
	
	# Method 2: Check by filesystem type (fallback)
	if [[ ${#efi_candidates[@]} -eq 0 ]]; then
		PrintStatus "No EFI partitions found by GUID, checking by filesystem type..."
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
		done < <(lsblk -rno NAME,FSTYPE "$disk_device" 2>/dev/null || true)
	fi
	
	# Method 3: Check by mount point (last resort)
	if [[ ${#efi_candidates[@]} -eq 0 ]]; then
		PrintStatus "No EFI partitions found by filesystem, checking by mount point..."
		while IFS= read -r line; do
			local part_name=$(echo "$line" | awk '{print $1}')
			local mount_point=$(echo "$line" | awk '{print $2}')
			if [[ "$mount_point" =~ ^/boot/efi$|^/boot$ ]]; then
				efi_candidates+=("/dev/$part_name")
			fi
		done < <(lsblk -rno NAME,MOUNTPOINT "$disk_device" 2>/dev/null || true)
	fi
	
	echo "${efi_candidates[@]}"
}

# Validate EFI partition is usable
validate_efi_partition() {
	local efi_part="$1"
	
	PrintStatus "Validating EFI partition: $efi_part"
	
	# Check if partition exists
	[[ -b "$efi_part" ]] || return 1
	
	# Check if it's actually FAT32
	local fs_type=$(lsblk -rno FSTYPE "$efi_part" 2>/dev/null | head -1)
	if [[ ! "$fs_type" =~ ^(vfat|fat32)$ ]]; then
		PrintWarning "EFI partition $efi_part has unexpected filesystem: $fs_type"
		return 1
	fi
	
	# Check if it's mountable
	local temp_mount="/tmp/efi_validation_$$"
	mkdir -p "$temp_mount"
	if mount "$efi_part" "$temp_mount" 2>/dev/null; then
		# Check for EFI directory structure
		if [[ -d "$temp_mount/EFI" ]]; then
			PrintStatus "EFI partition validated successfully: $efi_part"
			umount "$efi_part" 2>/dev/null || true
			rmdir "$temp_mount" 2>/dev/null || true
			return 0
		else
			PrintWarning "EFI partition $efi_part missing EFI directory"
		fi
		umount "$efi_part" 2>/dev/null || true
	else
		PrintWarning "Cannot mount EFI partition $efi_part"
	fi
	rmdir "$temp_mount" 2>/dev/null || true
	return 1
}

# Check if EFI partition needs resizing for ZFS
check_efi_size_for_zfs() {
	local efi_part="$1"
	local current_size_mb=$(lsblk -b "$efi_part" -o SIZE --noheadings 2>/dev/null | head -1)
	current_size_mb=$((current_size_mb / 1024 / 1024))
	
	# ZFS requires larger EFI partition due to multiple boot environments
	local recommended_size_mb=512
	
	if [[ $current_size_mb -lt $recommended_size_mb ]]; then
		PrintWarning "EFI partition size ($current_size_mb MB) may be insufficient for ZFS dual-boot"
		PrintStatus "Recommended size: ${recommended_size_mb} MB for ZFS with multiple boot environments"
		echo ""
		echo "Options:"
		echo "  1) Continue with current size (may cause issues with ZFS snapshots/boot environments)"
		echo "  2) Resize EFI partition to ${recommended_size_mb} MB (requires free space after EFI partition)"
		echo "  3) Abort and resize manually"
		
		while true; do
			read -p "Choose option (1-3): " choice < "$TTY_INPUT" || true
			case "$choice" in
				1)
					PrintStatus "Continuing with current EFI size"
					return 0
					;;
				2)
					resize_efi_partition "$efi_part" "$recommended_size_mb"
					return $?
					;;
				3)
					HandleFatalError "Please resize EFI partition manually and restart"
					;;
				*)
					echo "Invalid choice. Please enter 1, 2, or 3."
					;;
			esac
		done
	else
		PrintStatus "EFI partition size ($current_size_mb MB) is adequate for ZFS"
		return 0
	fi
}

# Resize EFI partition (requires free space after it)
resize_efi_partition() {
	local efi_part="$1"
	local target_size_mb="$2"
	local disk_device="$2"
	
	PrintStatus "Resizing EFI partition to ${target_size_mb} MB..."
	
	# Get current partition number
	local part_num=$(echo "$efi_part" | sed 's/.*p\([0-9]*\)$/\1/')
	
	# Check if there's free space after the EFI partition
	local next_part_start=$(sgdisk -i "$part_num" "$disk_device" 2>/dev/null | grep "Last sector" | awk '{print $3}')
	local disk_end=$(sgdisk -E "$disk_device" 2>/dev/null)
	
	if [[ $next_part_start -gt 0 && $((next_part_start - 1)) -gt $((target_size_mb * 1024 * 1024 / 512)) ]]; then
		# Resize the partition
		sgdisk -d "$part_num" "$disk_device" || return 1
		sgdisk -n "$part_num:0:+${target_size_mb}M" -t "$part_num:EF00" -c "$part_num:EFI System" "$disk_device" || return 1
		partprobe "$disk_device"
		sleep 2
		PrintStatus "EFI partition resized successfully"
		return 0
	else
		PrintError "Not enough free space after EFI partition to resize"
		return 1
	fi
}

prepare_partitions() {
	if [[ "$DUAL_BOOT_MODE" == "new" ]]; then
		PrintStatus "Partitioning disk for fresh install"
		require_cmd sgdisk
		require_cmd partprobe
		
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
		
		# Determine EFI size based on filesystem choice
		local efi_size="300M"
		if [[ "$FILESYSTEM" == "zfs" || "$FILESYSTEM" == "ZFS" ]]; then
			efi_size="512M"
			PrintStatus "Using larger EFI partition (512MB) for ZFS support"
		fi
		
		PrintStatus "Creating EFI System Partition ($efi_size)"
		sgdisk -n 1:0:+$efi_size -t 1:EF00 -c 1:"EFI System" "$DISK_DEVICE" || HandleFatalError "Failed to create EFI partition"
		
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
		PrintStatus "This will preserve your existing Windows installation and EFI partition"
		echo ""
		
		# Enhanced EFI partition detection
		local efi_candidates=($(detect_efi_partitions "$DISK_DEVICE"))
		
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
				local mount=$(lsblk -rno MOUNTPOINT "$part" 2>/dev/null | head -1)
				echo "  $((i+1))) $part (${size:-unknown size}) ${mount:+[mounted at $mount]}"
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
		
		# Validate the selected EFI partition
		if ! validate_efi_partition "$EFI_PART"; then
			PrintError "Selected EFI partition $EFI_PART is not usable"
			HandleFatalError "Please ensure Windows is properly installed with a valid EFI partition"
		fi
		
		# Check EFI size for ZFS if applicable
		if [[ "$FILESYSTEM" == "zfs" || "$FILESYSTEM" == "ZFS" ]]; then
			check_efi_size_for_zfs "$EFI_PART"
		fi
		
		echo ""
		echo "Existing partitions on $DISK_DEVICE:"
		print_disks
		echo ""
		echo "You need to specify where to install Arch Linux:"
		echo "  - Choose an unallocated space or existing partition to replace"
		echo "  - The EFI partition ($EFI_PART) will be shared with Windows"
		echo "  - GRUB will be installed to the EFI partition for dual-boot support"
		echo ""
		
		while true; do
			read -p "Enter Linux root partition (e.g., /dev/nvme0n1p5): " ROOT_PART < "$TTY_INPUT" || true
			if [[ -b "$ROOT_PART" ]]; then
				# Check if it's the EFI partition
				if [[ "$ROOT_PART" == "$EFI_PART" ]]; then
					echo "Error: Cannot use EFI partition as root partition"
					continue
				fi
				break
			else
				echo "Invalid partition. Please enter a valid block device."
			fi
		done
		
		echo ""
		read -p "Enter swap partition (optional, blank to skip): " SWAP_PART < "$TTY_INPUT" || true
		if [[ -n "$SWAP_PART" ]]; then
			if [[ ! -b "$SWAP_PART" ]]; then
				HandleValidationError "Invalid swap partition: $SWAP_PART"
			fi
			if [[ "$SWAP_PART" == "$EFI_PART" ]]; then
				HandleValidationError "Cannot use EFI partition as swap"
			fi
			if [[ "$SWAP_PART" == "$ROOT_PART" ]]; then
				HandleValidationError "Cannot use root partition as swap"
			fi
		fi
		
		PrintStatus "Dual-boot configuration:"
		PrintStatus "  EFI partition: $EFI_PART (shared with Windows)"
		PrintStatus "  Root partition: $ROOT_PART"
		[[ -n "$SWAP_PART" ]] && PrintStatus "  Swap partition: $SWAP_PART"
	fi
}

format_partitions() {
	PrintStatus "Formatting partitions"
	if [[ "$DUAL_BOOT_MODE" == "new" ]]; then
		mkfs.fat -F32 "$EFI_PART"
	else
		PrintStatus "Preserving existing EFI System Partition at $EFI_PART"
	fi
	PrintStatus "Stable policy: using ext4 for root filesystem"
	mkfs.ext4 -F "$ROOT_PART"
	if [[ -n "$SWAP_PART" ]]; then mkswap "$SWAP_PART" ; fi
}

mount_partitions() {
	PrintStatus "Mounting partitions"
	mount "$ROOT_PART" /mnt
	mkdir -p /mnt/boot
	if [[ "$DUAL_BOOT_MODE" == "new" ]]; then
		# Fresh install: mount ESP at /boot (systemd-boot flow)
		mount "$EFI_PART" /mnt/boot
	else
		# Dual-boot: mount ESP at /boot/EFI (GRUB flow keeps /boot on root FS)
		mkdir -p /mnt/boot/EFI
		mount "$EFI_PART" /mnt/boot/EFI
	fi
	if [[ -n "$SWAP_PART" ]]; then swapon "$SWAP_PART" ; fi
}

# Entry called by main script
DiskManagement_setup() {
	select_install_type
	select_disk
	confirm_destructive_action
	prepare_partitions
	format_partitions
	mount_partitions
}

# Backward-compatible lowercase name if main uses that
 disk_management_setup() { DiskManagement_setup "$@"; }