# Windows: Ensure-ESP.ps1

## Purpose
Safely ensure a sufficiently sized EFI System Partition (ESP) for dual-boot installation without modifying the original ESP. This script implements a conservative approach that preserves the existing ESP as a fallback while creating a new, properly sized ESP.

## Prerequisites
- Run as Administrator
- Windows 11 with UEFI firmware
- GPT partition table on OS disk
- BitLocker suspended (if enabled)
- No pending reboots

## Safety Policy
- **Never modify original ESP**: The existing ESP is left completely untouched
- **Minimal OS impact**: Only shrinks C: drive by the specified amount
- **Safe creation**: Creates new ESP at disk end and populates via `bcdboot`
- **Fallback preservation**: Original ESP remains intact as recovery option

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `MinEspMiB` | int | 260 | Minimum acceptable ESP size in MiB |
| `NewEspMiB` | int | 300 | Size for new ESP in MiB |
| `ShrinkOsMiB` | int | 512 | Amount to shrink OS volume in MiB |
| `AllowBitLocker` | switch | false | Allow proceeding with BitLocker enabled |
| `SkipPendingRebootCheck` | switch | false | Skip pending reboot validation |

## Workflow
1. **Validation**: Checks administrator rights, disk health, and system state
2. **ESP Assessment**: Evaluates existing ESP size against minimum requirements
3. **Space Preparation**: Shrinks C: drive to create unallocated space at disk end
4. **ESP Creation**: Creates new ESP with specified size and assigns drive letter
5. **Formatting**: Formats new ESP as FAT32 with 'EFI' label
6. **Boot File Deployment**: Uses `bcdboot` to deploy Windows boot files to new ESP
7. **Content Migration**: Optionally copies non-Microsoft boot entries from old ESP

## Usage Examples

### Basic ESP Creation
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1
```

### Custom ESP Size
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1 -MinEspMiB 300 -NewEspMiB 400 -ShrinkOsMiB 1024
```

### With BitLocker Enabled
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1 -AllowBitLocker -MinEspMiB 260 -NewEspMiB 300 -ShrinkOsMiB 512
```

### Skip Reboot Check
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Ensure-ESP.ps1 -SkipPendingRebootCheck -MinEspMiB 260 -NewEspMiB 300 -ShrinkOsMiB 512
```

## Exit Codes
- **0**: ESP creation completed successfully
- **1**: Critical error occurred (check error messages)

## Common Issues and Solutions

### BitLocker Not Suspended
**Issue**: "BitLocker is enabled on C:. Suspend BitLocker..."
**Solution**: 
```powershell
manage-bde -protectors -disable C: -RebootCount 1
# Or use -AllowBitLocker parameter (not recommended)
```

### Pending Reboot
**Issue**: "A reboot is pending. Please reboot Windows and re-run this script."
**Solution**: 
- Restart Windows
- Re-run the script
- Or use `-SkipPendingRebootCheck` (not recommended)

### Insufficient Shrink Headroom
**Issue**: "Insufficient shrink headroom. Minimum supported size is X MiB."
**Solution**:
```powershell
# Disable hibernation
powercfg /h off

# Disable Fast Startup via GUI
# Power Options > Choose what the power buttons do > Uncheck "Turn on fast startup"

# Run Disk Cleanup
cleanmgr /sagerun:1

# Reboot and retry
```

### C: Drive Too Small
**Issue**: "C: would become too small. Reduce -ShrinkOsMiB or free space on C:."
**Solution**:
- Reduce the `-ShrinkOsMiB` parameter
- Free up space on C: drive
- Use Disk Cleanup to remove unnecessary files

### Failed to Create New ESP
**Issue**: "Failed to create new ESP: [error_message]"
**Solution**:
- Ensure there is unallocated space at disk end
- Check disk health status
- Verify no other processes are using the disk

### bcdboot Deployment Failed
**Issue**: "bcdboot failed to deploy boot files: [error_message]"
**Solution**:
- Ensure Windows boot files are intact
- Check that the new ESP is properly formatted
- Verify administrator privileges

## Technical Details

### ESP Requirements
- **Minimum Size**: 260 MiB (recommended by Arch Wiki)
- **File System**: FAT32
- **Label**: 'EFI'
- **GUID Type**: `{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}`

### Drive Letter Assignment
- Attempts automatic assignment during partition creation
- Falls back to manual assignment using drive letter 'S'
- Verifies assignment before proceeding with formatting

### Boot File Deployment
- Uses `bcdboot C:\Windows /s [drive]: /f UEFI`
- Deploys Windows boot manager and boot configuration data
- Ensures Windows can boot from the new ESP

## Notes
- This script is designed to be safe and non-destructive
- The original ESP is never modified and remains as a fallback
- Always test booting Windows after ESP creation
- Consider creating a system restore point before running
- The script provides detailed progress information throughout execution

