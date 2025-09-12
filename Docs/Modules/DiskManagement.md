# DiskManagement Module

- Function: `disk_management_setup`
- Responsibilities: Disk selection, detecting existing partitions, dual-boot modes, single-boot mode.
- Key behaviors:
  - Detects disks via `lsblk -d -n -o NAME,TYPE | awk '$2=="disk"{print $1}'` (includes NVMe)
  - GPT dual-boot preserves existing EFI; prompts for root/swap
  - New/single-boot formats EFI as FAT32 and mounts it to `/mnt/boot`
- Outputs: `DISK_DEVICE`, `EFI_PART`, `ROOT_PART`, `SWAP_PART`, `WINDOWS_EXISTS`
