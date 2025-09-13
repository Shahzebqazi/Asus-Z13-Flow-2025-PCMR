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

prepare_partitions() {
	if [[ "$DUAL_BOOT_MODE" == "new" ]]; then
		PrintStatus "Partitioning disk for fresh install"
		require_cmd sgdisk
		require_cmd partprobe
		# Wipe and create GPT with ESP + root + swap
		sgdisk --zap-all "$DISK_DEVICE"
		partprobe "$DISK_DEVICE"
		sleep 1
		sgdisk -n 1:0:+300M -t 1:EF00 -c 1:"EFI System" "$DISK_DEVICE"
		sgdisk -n 2:0:-8G   -t 2:8300 -c 2:"Linux Root" "$DISK_DEVICE"
		sgdisk -n 3:0:0     -t 3:8200 -c 3:"Linux Swap" "$DISK_DEVICE"
		partprobe "$DISK_DEVICE"
		sleep 1
		EFI_PART="${DISK_DEVICE}p1"; ROOT_PART="${DISK_DEVICE}p2"; SWAP_PART="${DISK_DEVICE}p3"
		[[ -e "$EFI_PART" ]] || EFI_PART="${DISK_DEVICE}1"
		[[ -e "$ROOT_PART" ]] || ROOT_PART="${DISK_DEVICE}2"
		[[ -e "$SWAP_PART" ]] || SWAP_PART="${DISK_DEVICE}3"
	else
		PrintStatus "Setting up for dual-boot (GPT)"
		# Detect ESP and pick/create root partition interactively
		EFI_PART=$(lsblk -rno NAME,PARTTYPE "/dev/$(basename "$DISK_DEVICE")" | awk '/c12a7328-f81f-11d2-ba4b-00a0c93ec93b/{print $1; exit}')
		if [[ -n "$EFI_PART" ]]; then EFI_PART="/dev/$EFI_PART"; fi
		if [[ -z "$EFI_PART" ]]; then HandleFatalError "No EFI partition found. Prepare Windows ESP first."; fi
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


