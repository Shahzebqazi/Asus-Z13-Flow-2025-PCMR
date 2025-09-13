# Windows: Create-Partitions.ps1

## Purpose
Create Linux root and swap partitions from unallocated disk space for Arch Linux dual-boot installation. This script safely creates the necessary partitions without modifying existing Windows partitions.

## Prerequisites
- Run as Administrator
- GPT partition table on target disk
- Sufficient unallocated space on target disk
- Healthy disk status

## Safety Policy
- **Non-destructive**: Only creates new partitions in unallocated space
- **No Windows modification**: Never modifies existing Windows partitions
- **Validation first**: Validates all operations before execution
- **Rollback capability**: Provides cleanup on failure

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `DiskNumber` | int | Required | Target disk number (e.g., 0 for first disk) |
| `RootSizeGB` | int | 50 | Size of root partition in GB |
| `SwapSizeGB` | int | 8 | Size of swap partition in GB |
| `DryRun` | switch | false | Show what would be created without executing |
| `Force` | switch | false | Skip confirmation prompt |

## Usage Examples

### Basic Partition Creation
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Partitions.ps1 -DiskNumber 0
```

### Custom Partition Sizes
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Partitions.ps1 -DiskNumber 0 -RootSizeGB 100 -SwapSizeGB 16
```

### Dry Run (Preview Only)
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Partitions.ps1 -DiskNumber 0 -DryRun
```

### Force Mode (No Confirmation)
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Partitions.ps1 -DiskNumber 0 -Force
```

### Large Installation
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Partitions.ps1 -DiskNumber 0 -RootSizeGB 200 -SwapSizeGB 32 -Force
```

## Workflow
1. **Validation**: Checks administrator rights and disk health
2. **Disk Analysis**: Analyzes unallocated space on target disk
3. **Space Verification**: Ensures sufficient space for both partitions
4. **Plan Display**: Shows detailed partition creation plan
5. **Confirmation**: Prompts user for confirmation (unless -Force)
6. **Partition Creation**: Creates root and swap partitions
7. **Verification**: Confirms successful partition creation

## Partition Types

### Root Partition
- **GUID Type**: `{0FC63DAF-8483-4772-8E79-3D69D8477DE4}` (Linux filesystem)
- **Purpose**: Main Arch Linux installation
- **Recommended Size**: 50-200GB (depending on usage)

### Swap Partition
- **GUID Type**: `{0657FD6D-A4AB-43C4-84E5-0933C84B4F4F}` (Linux swap)
- **Purpose**: Virtual memory and hibernation
- **Recommended Size**: 8-32GB (typically 1-2x RAM size)

## Space Requirements

### Minimum Requirements
- **Root Partition**: 20GB (absolute minimum)
- **Swap Partition**: 2GB (minimum for hibernation)
- **Total**: 22GB minimum

### Recommended Sizes
- **Root Partition**: 50-100GB (desktop use)
- **Swap Partition**: 8-16GB (8GB RAM system)
- **Total**: 58-116GB recommended

### Large Installations
- **Root Partition**: 100-500GB (development, gaming)
- **Swap Partition**: 16-64GB (high-memory systems)
- **Total**: 116-564GB for large installations

## Exit Codes
- **0**: Partitions created successfully
- **1**: Critical error occurred (check error messages)

## Common Issues and Solutions

### Disk Not Found
**Issue**: "Disk [number] not found."
**Solution**:
- Verify disk number using `Get-Disk`
- Ensure disk is online and accessible
- Check disk is not in use by other processes

### Disk Not GPT
**Issue**: "Disk [number] must be GPT for UEFI operations."
**Solution**:
- Convert disk to GPT using `ConvertTo-Gpt`
- **Warning**: This will erase all data on the disk
- Consider backing up data first

### Disk Not Healthy
**Issue**: "Disk [number] health status is not healthy: [status]"
**Solution**:
- Check disk health using `Get-Disk`
- Run disk check: `chkdsk /f`
- Consider replacing failing disk

### Insufficient Space
**Issue**: "Insufficient unallocated space. Available: XGB, Required: YGB"
**Solution**:
- Shrink existing partitions using Disk Management
- Free up space by deleting unnecessary files
- Use `Ensure-ESP.ps1` to create unallocated space

### Partition Creation Failed
**Issue**: "Failed to create partitions: [error_message]"
**Solution**:
- Ensure sufficient unallocated space
- Check disk is not locked by other processes
- Verify disk health status
- Try running as Administrator

### Cleanup Failed
**Issue**: "Could not clean up partially created partitions."
**Solution**:
- Manually delete failed partitions using Disk Management
- Use `Remove-Partition` PowerShell cmdlet
- Check partition GUIDs match Linux types

## Technical Details

### Unallocated Space Analysis
- Scans disk for gaps between existing partitions
- Identifies largest contiguous unallocated region
- Validates space requirements before creation

### Partition Alignment
- Partitions are created with proper alignment
- Follows GPT standards for optimal performance
- Ensures compatibility with UEFI boot

### Error Handling
- Validates all operations before execution
- Provides detailed error messages
- Attempts cleanup on failure
- Preserves existing data

## Verification Steps

After partition creation, verify the results:

1. **Check Disk Management**: Verify partitions appear in Disk Management
2. **Verify Sizes**: Confirm partition sizes match specifications
3. **Check GUIDs**: Ensure correct partition types are assigned
4. **Test Access**: Verify partitions are accessible (though not yet formatted)

## Best Practices

### Before Running
- Create a system restore point
- Backup important data
- Ensure sufficient unallocated space
- Close unnecessary applications

### During Execution
- Monitor progress messages
- Don't interrupt the process
- Note any warnings or errors

### After Completion
- Verify partition creation
- Test disk access
- Proceed with Arch Linux installation
- Keep backup of partition layout

## Troubleshooting

### Script Won't Run
- Ensure running as Administrator
- Check PowerShell execution policy
- Verify script file permissions

### Partitions Not Created
- Check disk health status
- Ensure sufficient unallocated space
- Verify disk is not locked
- Try different disk number

### Wrong Partition Sizes
- Verify parameter values
- Check available unallocated space
- Ensure parameters are within limits

## Notes
- This script only creates partitions; formatting is done during Arch installation
- Partitions are created in the largest available unallocated region
- The script provides detailed progress information throughout execution
- Always verify results before proceeding with installation
- Consider the total space requirements when planning partition sizes
