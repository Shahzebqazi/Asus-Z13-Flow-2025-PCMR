# Windows: Create-Arch-USB.ps1 (Orchestrator)

## Purpose
Comprehensive orchestrator script that prepares a Windows system for Arch Linux dual-boot installation. This script coordinates all pre-installation tasks including system validation, backup creation, ESP management, and optional USB installer creation.

## Prerequisites
- Run as Administrator
- Windows 11 with UEFI firmware
- GPT partition table on OS disk
- Installation media
- Sufficient disk space for backup operations (if enabled)

## Workflow
1. **System Validation**: Validates input parameters and runs `Preflight-Checklist.ps1` to validate system requirements
2. **Power Management**: Applies optional power management fixes (Fast Startup, Hibernation)
3. **Backup Creation**: Creates system restore point and optional system image backup
4. **BitLocker Management**: Suspends BitLocker protection if enabled
5. **ESP Management**: Runs `Ensure-ESP.ps1` to ensure properly sized EFI System Partition
6. **USB Detection**: Scans for existing Arch Linux USB drives and offers to reuse them
7. **USB Validation**: Validates USB drive status and Rufus installation
8. **USB Creation**: Optionally runs `Make-Arch-USB.ps1` to create Arch Linux installer USB

## Parameters

### Backup Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `BackupTargetDriveLetter` | string | null | Drive letter for system image backup (e.g., "E:") |
| `BackupNetworkPath` | string | null | Network path for system image backup (e.g., "\\server\share") |
| `BackupNetworkCredential` | PSCredential | null | Credentials for network backup path |
| `SkipBackup` | switch | false | Skip all backup operations |

### USB Creation Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `CreateUSB` | switch | false | Enable USB creation workflow |
| `RufusPath` | string | null | Path to Rufus executable (e.g., "C:\Tools\rufus.exe") |
| `ISOPath` | string | null | Path to Arch Linux ISO file |
| `USBDevice` | string | null | Target USB device (e.g., "\\.\PhysicalDrive3") |

### ESP Management Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `MinEspMiB` | int | 260 | Minimum acceptable ESP size in MiB |
| `NewEspMiB` | int | 300 | Size for new ESP in MiB |
| `ShrinkOsMiB` | int | 512 | Amount to shrink OS volume in MiB |

### Power Management Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `DisableFastStartup` | switch | false | Disable Fast Startup |
| `DisableHibernation` | switch | false | Disable hibernation |
| `ApplyPowerFixes` | switch | false | Apply both power management fixes |

### Advanced Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `AllowBitLocker` | switch | false | Allow proceeding with BitLocker enabled |
| `SkipPendingRebootCheck` | switch | false | Skip pending reboot validation |

## Usage Examples

### Basic Preparation (No USB Creation)
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1
```

### Full Preparation with USB Creation
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1 -CreateUSB -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

### With System Image Backup
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1 -BackupTargetDriveLetter "E:" -CreateUSB -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

### Network Backup with Credentials
```powershell
$cred = Get-Credential
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1 -BackupNetworkPath "\\server\backups" -BackupNetworkCredential $cred -CreateUSB -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

### Custom ESP Configuration
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1 -MinEspMiB 300 -NewEspMiB 400 -ShrinkOsMiB 1024 -CreateUSB -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

### Apply Power Management Fixes
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Create-Arch-USB.ps1 -ApplyPowerFixes -CreateUSB -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

## Enhanced Features

### USB Detection and Validation
- **Existing Media Detection**: Automatically scans for existing Arch Linux USB drives
- **USB Drive Status Check**: Validates USB drive health and available space
- **Rufus Installation Validation**: Checks for Rufus installation and version compatibility
- **Smart Reuse**: Offers to reuse existing Arch installation media when found

### Progress Tracking and Logging
- **Real-time Progress**: Visual progress indicators for all major operations
- **Comprehensive Logging**: Detailed logging to `%TEMP%\arch-usb-setup.log`
- **Error Tracking**: Enhanced error reporting with rollback capabilities
- **Input Validation**: Comprehensive parameter validation before execution

### Improved Error Handling
- **Rollback Capabilities**: Automatic rollback on critical failures
- **Detailed Error Messages**: Specific error messages with suggested solutions
- **Log File References**: Automatic log file location reporting on errors
- **Graceful Degradation**: Continues operation when non-critical components fail

## Safety Features

### Backup Strategy
- **System Restore Point**: Always created before disk modifications
- **System Image Backup**: Optional full system backup to external drive or network
- **BitLocker Suspension**: Automatically suspends BitLocker for one reboot cycle

### ESP Management Policy
- **Non-Destructive**: Never modifies existing ESP
- **Safe Creation**: Creates new ESP at disk end and populates via `bcdboot`
- **Fallback Preservation**: Original ESP remains intact as fallback

## Exit Codes
- **0**: All operations completed successfully
- **1**: Critical error occurred (check error messages)

## Common Issues and Solutions

### Missing Dependencies
**Issue**: "Missing script: [script_path]"
**Solution**: Ensure all PowerShell scripts are in the same directory

### Preflight Check Failures
**Issue**: "Preflight checks failed. Resolve issues and re-run."
**Solution**: Run `Preflight-Checklist.ps1` separately to identify and resolve issues

### Backup Failures
**Issue**: "Backup failed: [error_message]"
**Solution**: 
- Ensure target drive has sufficient space
- Check network connectivity for network backups
- Verify credentials for network paths

### BitLocker Issues
**Issue**: "BitLocker is enabled on C:"
**Solution**: 
```powershell
manage-bde -protectors -disable C: -RebootCount 1
```

### ESP Creation Failures
**Issue**: "Failed to create new ESP"
**Solution**: 
- Ensure sufficient unallocated space
- Disable hibernation: `powercfg /h off`
- Disable Fast Startup via GUI
- Run Disk Cleanup to free space

### USB Detection Issues
**Issue**: "No USB drives detected"
**Solution**: 
- Ensure USB drives are properly connected
- Check USB drive health in Disk Management
- Try different USB ports

**Issue**: "Rufus validation failed"
**Solution**: 
- Install Rufus from https://rufus.ie/
- Provide correct path with -RufusPath parameter
- Ensure Rufus version is compatible

### Input Validation Errors
**Issue**: "MinEspMiB must be at least 100 MiB"
**Solution**: 
- Use reasonable ESP sizes (100-1000 MiB)
- Ensure NewEspMiB >= MinEspMiB
- Check ShrinkOsMiB is reasonable (100-10000 MiB)

### Log File Access
**Issue**: Need to troubleshoot script execution
**Solution**: 
- Check log file at `%TEMP%\arch-usb-setup.log`
- Log contains detailed execution information
- Use log file for error reporting and debugging

## Notes
- This script coordinates multiple sub-scripts; ensure all are present
- Backup operations may take significant time depending on system size
- USB creation requires manual completion in Rufus GUI
- The script provides detailed progress information throughout execution

