# Windows: Make-Arch-USB.ps1

## Purpose
Launch Rufus to create an Arch Linux USB installer from an ISO file. This script handles the initial setup and elevation of Rufus, then allows the user to complete the USB creation process through the Rufus GUI.

## Prerequisites
- Run as Administrator
- Rufus executable available
- Arch Linux ISO file downloaded
- USB drive with sufficient capacity (8GB+ recommended)

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `RufusPath` | string | Required | Path to Rufus executable (e.g., "C:\Tools\rufus.exe") |
| `ISOPath` | string | Required | Path to Arch Linux ISO file |
| `USBDevice` | string | null | Target USB device (e.g., "\\.\PhysicalDrive3") - Currently unused due to CLI limitations |

## Usage Examples

### Basic USB Creation
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Make-Arch-USB.ps1 -RufusPath C:\Tools\rufus.exe -ISOPath C:\Users\you\Downloads\archlinux.iso
```

### With Custom Paths
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Make-Arch-USB.ps1 -RufusPath "D:\Tools\Rufus\rufus.exe" -ISOPath "C:\Downloads\archlinux-2024.01.01-x86_64.iso"
```

### From Network Location
```powershell
PowerShell -ExecutionPolicy Bypass -File .\Make-Arch-USB.ps1 -RufusPath "C:\Tools\rufus.exe" -ISOPath "\\server\isos\archlinux.iso"
```

## Workflow
1. **Validation**: Verifies Rufus executable and ISO file exist
2. **Elevation**: Launches Rufus with administrator privileges
3. **ISO Preselection**: Passes ISO path to Rufus for preselection
4. **GUI Completion**: User completes the USB creation process in Rufus GUI

## Rufus Configuration Recommendations

### For Arch Linux Installation
- **Partition Scheme**: GPT
- **Target System**: UEFI (non CSM)
- **File System**: FAT32
- **Cluster Size**: 32 kilobytes (default)
- **Volume Label**: ARCH_202401 (or current date)

### Advanced Options
- **Bad Blocks Check**: 1 pass (for reliability)
- **Quick Format**: Unchecked (for better compatibility)
- **Create Extended Label**: Checked (for better identification)

## Common Issues and Solutions

### Rufus Not Found
**Issue**: "Rufus not found at: [path]"
**Solution**:
- Download Rufus from official website
- Ensure the path is correct and accessible
- Check file permissions

### ISO Not Found
**Issue**: "ISO not found at: [path]"
**Solution**:
- Verify ISO file exists and is accessible
- Check file path for typos
- Ensure sufficient permissions to read the file

### Rufus Launch Failure
**Issue**: Rufus fails to start or crashes
**Solution**:
- Run Rufus manually to test
- Check Windows compatibility
- Try running as Administrator directly
- Update to latest Rufus version

### USB Not Detected
**Issue**: USB drive not showing in Rufus
**Solution**:
- Ensure USB drive is properly connected
- Check USB drive is formatted and accessible
- Try different USB port
- Restart Rufus

### ISO Verification Failed
**Issue**: Rufus reports ISO verification issues
**Solution**:
- Re-download the ISO file
- Verify ISO checksum matches official release
- Check ISO file integrity

## Manual Rufus Configuration

If the script fails or you prefer manual configuration:

1. **Launch Rufus** as Administrator
2. **Select Device**: Choose your USB drive
3. **Select Boot Selection**: Choose "Disk or ISO image" and browse to your Arch ISO
4. **Partition Scheme**: Select "GPT"
5. **Target System**: Select "UEFI (non CSM)"
6. **File System**: Select "FAT32"
7. **Cluster Size**: Leave as default (32 kilobytes)
8. **Volume Label**: Enter "ARCH_202401" (or current date)
9. **Format Options**: Uncheck "Quick format" for better compatibility
10. **Click Start** and confirm all dialogs

## Verification Steps

After USB creation, verify the installation media:

1. **Check Boot Files**: Ensure `\EFI\BOOT\BOOTX64.EFI` exists
2. **Test Boot**: Boot from USB to verify Arch Linux loads
3. **Check Partition**: Verify GPT partition table and FAT32 filesystem
4. **Verify ISO Contents**: Ensure all Arch Linux files are present

## Troubleshooting

### USB Won't Boot
- Ensure UEFI boot is enabled in BIOS
- Check USB is set as boot priority
- Verify USB was created with correct partition scheme
- Try different USB port or drive

### Arch Linux Won't Load
- Verify ISO file integrity
- Check USB creation process completed successfully
- Ensure sufficient USB drive capacity
- Try recreating the USB with different settings

### Rufus Errors
- Update to latest Rufus version
- Check Windows compatibility
- Run as Administrator
- Disable antivirus temporarily

## Notes
- This script only launches Rufus; manual completion is required
- Rufus CLI support varies by version; GUI completion is recommended
- Always verify the USB before attempting installation
- Keep a backup of your ISO file for future use
- The script provides basic validation but relies on Rufus for actual USB creation

