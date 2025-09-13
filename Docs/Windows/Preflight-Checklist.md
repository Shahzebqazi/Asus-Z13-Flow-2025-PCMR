# Windows: Preflight-Checklist.ps1

## Purpose
Non-destructive preflight validation before creating the Arch USB or modifying partitions. This script performs comprehensive system checks to ensure the Windows environment is ready for Arch Linux dual-boot installation.

The user is recommended to run this script at the start and it should first ensure there is a system restore point and alert the user of all the changes that need to be made preflight.

after all the core items are completed on the checklist, the user is urged to run the checklist again to ensure they are ready to install archlinux.

## Prerequisites
- Run as Administrator
- Windows 11 with UEFI firmware
- Verify GPT partition table on OS disk

## Validation Checks

### System Requirements
- **Administrator Rights**: Verifies elevated privileges
- **UEFI/GPT**: Confirms OS disk uses GPT partition style (required for UEFI) is compliant. Refer to the EFI Arch linux Dual boot wiki article. ZFS requires a larger EFI partition than the stock EFI partition size. the efi partition by default is nvme0n1p1.
- **Disk**: Checks disk health status and warns if not optimal. Allows the user to resize the main partition, allocate unallocated memory, delete potential failed arch linux partitions, create a system restore point if one already does not exist. It is likely that dual boot users will resize the main windows partition for the EFI/Swap/System arch installation. Some users will simply remove the windows stock SSD and install linux on a new SSD. Some users might want to copy the stock windows installation for dual boot on a new larger SSD. 

### System State
- **BitLocker Status**: Detects if BitLocker is enabled on C: drive. Allows user to turn off bitlocker after asking for permission if Bitlocker is not already turned off.
- **Pending Reboot**: Checks for pending Windows updates requiring reboot. checks for armory crate and asus driver updates.
- **Fast Startup**: Detects if Fast Startup is enabled (can cause hibernation locks). if fast startup is not already disabled, asks the user whether they would like to disable it.

### Storage Requirements
- **ESP Size**: Validates EFI System Partition size (warns if < 260 MiB). Validates that the resizing will be sufficient for ZFS or other File Systems the user would like to install on arch.
- **Unallocated Space**: Checks for sufficient space for Arch installation (~25GB minimum). Creates a Swap file for all ram configs of the z13 2025 machines (32,64,128).
- **C: Drive Size**: Validates OS partition has enough space for shrinking

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `MinEspMiB` | int | 260 | Minimum acceptable ESP size in MiB |
| `MinShrinkRoomMiB` | int | 512 | Minimum shrink headroom required in MiB |

## Usage Examples

### Basic Check
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Preflight-Checklist.ps1
```

### Custom ESP Requirements
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Preflight-Checklist.ps1 -MinEspMiB 300 -MinShrinkRoomMiB 1024
```

## Exit Codes
- **0**: All checks passed (may have warnings)
- **1**: Critical failures detected (must be resolved before proceeding)

## Common Issues and Solutions

### BitLocker Enabled
**Issue**: "BitLocker is enabled: suspend protection before ESP changes"
**Solution**: 
```powershell
manage-bde -protectors -disable C: -RebootCount 1
```

### Fast Startup Enabled
**Issue**: "Fast Startup is enabled; disable it to avoid hibernation lock"
**Solution**:
```powershell
powercfg /h off
# Or disable via GUI: Power Options > Choose what the power buttons do > Uncheck "Turn on fast startup"
```

### Insufficient Unallocated Space
**Issue**: "Insufficient unallocated space for Arch Linux installation"
**Solution**: Use Disk Management to shrink existing partitions or free up space

### Pending Reboot
**Issue**: "A reboot is pending; reboot before proceeding"
**Solution**: Restart Windows and re-run the script

## Notes
- This script is non-destructive and safe to run multiple times
- Warnings do not prevent installation but should be addressed for optimal results
- The script provides detailed information about disk layout and available space

