<#
Purpose: Prepare a Windows system for Arch dual-boot or fresh install.
 - Creates a restore point and optional system image backup (USB/remote)
 - Ensures EFI System Partition (ESP) is sufficiently sized for dual-boot
 - Optionally launches Rufus to create an Arch USB installer

References:
 - Arch Wiki: Dual boot with Windows → EFI partition too small
   https://wiki.archlinux.org/title/Dual_boot_with_Windows#The_EFI_system_partition_created_by_Windows_Setup_is_too_small

SAFE POLICY:
 - We DO NOT shrink/move the existing ESP. Instead, we create a new larger ESP
   at the end of the disk and deploy Windows boot files to it using bcdboot.
 - The old ESP is left intact as a fallback.
 - This avoids risky moves of early disk partitions.

Requirements:
 - Run as Administrator
 - BitLocker should be suspended on the OS drive before partition changes

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [string]$BackupTargetDriveLetter,   # e.g. "E:" (USB disk)
    [Parameter(Mandatory=$false)] [string]$BackupNetworkPath,          # e.g. "\\server\share"
    [Parameter(Mandatory=$false)] [pscredential]$BackupNetworkCredential,
    [Parameter(Mandatory=$false)] [switch]$SkipBackup,

    [Parameter(Mandatory=$false)] [switch]$CreateUSB,
    [Parameter(Mandatory=$false)] [string]$RufusPath,                  # e.g. "C:\Tools\rufus.exe"
    [Parameter(Mandatory=$false)] [string]$ISOPath,                    # e.g. "C:\Users\me\Downloads\archlinux.iso"
    [Parameter(Mandatory=$false)] [string]$USBDevice,                  # e.g. "\\.\PhysicalDrive3" or drive letter

    [Parameter(Mandatory=$false)] [int]$MinEspMiB = 260,               # Minimum acceptable ESP size
    [Parameter(Mandatory=$false)] [int]$NewEspMiB = 300,               # New ESP size to create
    [Parameter(Mandatory=$false)] [int]$ShrinkOsMiB = 512,             # Amount to shrink OS volume if needed

    [Parameter(Mandatory=$false)] [switch]$DisableFastStartup,
    [Parameter(Mandatory=$false)] [switch]$DisableHibernation,
    [Parameter(Mandatory=$false)] [switch]$ApplyPowerFixes,            # Implies both disables

    [Parameter(Mandatory=$false)] [switch]$AllowBitLocker,             # Pass through to Ensure-ESP
    [Parameter(Mandatory=$false)] [switch]$SkipPendingRebootCheck      # Pass through to Ensure-ESP
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must be run as Administrator.'
    }
}

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-ErrorMsg($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Write-Log($Level, $Message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'INFO' { Write-Host $logMessage -ForegroundColor Green }
        'WARN' { Write-Host $logMessage -ForegroundColor Yellow }
        'ERROR' { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage }
    }
    
    # Optionally write to log file
    $logFile = Join-Path $env:TEMP "arch-usb-setup.log"
    try {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        # Ignore log file errors
    }
}

function Show-Progress($Current, $Total, $Operation) {
    $percent = [math]::Round(($Current / $Total) * 100, 1)
    $progressBar = "[" + ("=" * [math]::Floor($percent / 5)) + (" " * (20 - [math]::Floor($percent / 5))) + "]"
    Write-Host "`r$progressBar $percent% - $Operation" -NoNewline
    if ($Current -eq $Total) { Write-Host "" }
}

function Invoke-WithRollback($Operation, $RollbackOperation) {
    try {
        Write-Log 'INFO' "Starting operation: $Operation"
        $result = & $Operation
        Write-Log 'INFO' "Operation completed successfully: $Operation"
        return $result
    } catch {
        Write-Log 'ERROR' "Operation failed: $Operation - $($_.Exception.Message)"
        if ($RollbackOperation) {
            try {
                Write-Log 'INFO' "Attempting rollback: $RollbackOperation"
                & $RollbackOperation
                Write-Log 'INFO' "Rollback completed: $RollbackOperation"
            } catch {
                Write-Log 'ERROR' "Rollback failed: $RollbackOperation - $($_.Exception.Message)"
            }
        }
        throw
    }
}

function Test-InputValidation {
    Write-Log 'INFO' 'Validating input parameters...'
    
    # Validate ESP sizes
    if ($MinEspMiB -lt 100) { throw 'MinEspMiB must be at least 100 MiB' }
    if ($NewEspMiB -lt $MinEspMiB) { throw 'NewEspMiB must be at least MinEspMiB' }
    if ($ShrinkOsMiB -lt 100) { throw 'ShrinkOsMiB must be at least 100 MiB' }
    
    # Validate backup parameters
    if ($BackupTargetDriveLetter -and $BackupNetworkPath) {
        throw 'Cannot specify both BackupTargetDriveLetter and BackupNetworkPath'
    }
    
    if ($BackupTargetDriveLetter) {
        if (-not ($BackupTargetDriveLetter -match '^[A-Z]:$')) {
            throw 'BackupTargetDriveLetter must be in format "X:" where X is a drive letter'
        }
        if (-not (Test-Path $BackupTargetDriveLetter)) {
            throw "Backup target drive $BackupTargetDriveLetter not found"
        }
    }
    
    if ($BackupNetworkPath) {
        if (-not ($BackupNetworkPath -match '^\\\\')) {
            throw 'BackupNetworkPath must be a UNC path (\\server\share)'
        }
    }
    
    # Validate USB creation parameters
    if ($CreateUSB) {
        if (-not $RufusPath) { throw 'RufusPath is required when CreateUSB is specified' }
        if (-not $ISOPath) { throw 'ISOPath is required when CreateUSB is specified' }
        
        if (-not (Test-Path $RufusPath)) { throw "Rufus not found at: $RufusPath" }
        if (-not (Test-Path $ISOPath)) { throw "ISO not found at: $ISOPath" }
        
        # Validate ISO file extension
        if (-not ($ISOPath -match '\.iso$')) { throw 'ISOPath must be a .iso file' }
    }
    
    Write-Log 'INFO' 'Input validation completed successfully'
}

function New-SystemRestorePoint {
    try {
        Write-Info 'Creating a system restore point...'
        # Ensure System Protection is enabled on C:
        try { Enable-ComputerRestore -Drive 'C:\' } catch { }
        Checkpoint-Computer -Description 'Pre-ESP-Resize' -RestorePointType 'MODIFY_SETTINGS' | Out-Null
        Write-Info 'System restore point created.'
    } catch {
        Write-Warn "Could not create a restore point: $($_.Exception.Message)"
    }
}

function New-SystemImageBackup {
    param([string]$TargetDrive, [string]$NetworkPath, [pscredential]$Cred)
    try {
        if ($TargetDrive) {
            Write-Info "Starting system image backup to $TargetDrive ..."
            & wbAdmin start backup -backupTarget:$TargetDrive -include:C: -allCritical -quiet
            Write-Info 'System image backup completed.'
        } elseif ($NetworkPath) {
            Write-Info "Starting system image backup to network path $NetworkPath ..."
            if ($Cred) { cmdkey /add:$NetworkPath /user:$($Cred.UserName) /pass:$($Cred.GetNetworkCredential().Password) | Out-Null }
            & wbAdmin start backup -backupTarget:$NetworkPath -include:C: -allCritical -quiet
            Write-Info 'System image backup completed.'
        } else {
            Write-Warn 'No backup target specified; skipping system image backup.'
        }
    } catch {
        Write-ErrorMsg "Backup failed: $($_.Exception.Message)"
        throw
    }
}

function Suspend-BitLockerIfNeeded {
    try {
        $osVol = Get-BitLockerVolume -MountPoint 'C:' -ErrorAction SilentlyContinue
        if ($osVol -and $osVol.ProtectionStatus -eq 'On') {
            Write-Warn 'BitLocker is enabled on C:. Suspending protection for one reboot...'
            manage-bde -protectors -disable C: -RebootCount 1 | Out-Null
            Write-Info 'BitLocker protection suspended.'
        }
    } catch { Write-Warn 'BitLocker status could not be determined. Proceed with caution.' }
}

function Get-OsDisk {
    $cPart = Get-Partition -DriveLetter C
    $disk  = Get-Disk | Where-Object { $_.Number -eq $cPart.DiskNumber }
    if (-not $disk) { throw 'Unable to determine OS disk.' }
    if ($disk.PartitionStyle -ne 'GPT') { throw 'Disk must be GPT for UEFI/ESP operations.' }
    return $disk
}

function Get-EspPartition([Microsoft.Management.Infrastructure.CimInstance]$Disk) {
    $espGuid = '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    $esp = Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.GptType -eq $espGuid }
    return $esp
}

function Ensure-LargeEsp {
    param([Microsoft.Management.Infrastructure.CimInstance]$Disk,
          [int]$MinMiB,[int]$NewMiB,[int]$ShrinkMiB)

    $esp = Get-EspPartition -Disk $Disk
    if ($esp) {
        $espSizeMiB = [math]::Round($esp.Size / 1MB)
        Write-Info "Existing ESP found: $espSizeMiB MiB"
        if ($espSizeMiB -ge $MinMiB) {
            Write-Info 'ESP is sufficiently sized; no action needed.'
            return $esp
        } else {
            Write-Warn "ESP is smaller than $MinMiB MiB; will create a new larger ESP."
        }
    } else {
        Write-Warn 'No ESP found; will create a new ESP.'
    }

    # Shrink OS volume to create unallocated space at disk end
    $cPart   = Get-Partition -DriveLetter C
    $cSize   = $cPart.Size
    $newSize = $cSize - ($ShrinkMiB * 1MB)
    if ($newSize -lt 20GB) { throw 'OS partition too small to shrink safely.' }
    Write-Info "Shrinking C: by $ShrinkMiB MiB to create space for new ESP..."
    Resize-Partition -DriveLetter C -Size $newSize

    # Create new ESP at end of disk
    $espGuid = '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    Write-Info "Creating new $NewMiB MiB ESP..."
    $newEsp = New-Partition -DiskNumber $Disk.Number -Size ($NewMiB * 1MB) -GptType $espGuid -AssignDriveLetter
    $letter = ($newEsp | Get-Volume).DriveLetter
    if (-not $letter) {
        $letter = (Get-Partition -DiskNumber $Disk.Number -PartitionNumber $newEsp.PartitionNumber | Get-Volume -ErrorAction SilentlyContinue).DriveLetter
        if (-not $letter) {
            $tmpLtr = 'S'
            Set-Partition -DiskNumber $Disk.Number -PartitionNumber $newEsp.PartitionNumber -NewDriveLetter $tmpLtr -ErrorAction SilentlyContinue | Out-Null
            $letter = ($newEsp | Get-Volume -ErrorAction SilentlyContinue).DriveLetter
        }
    }
    if (-not $letter) { throw 'Failed to assign drive letter to new ESP.' }

    $newEspPath = "${letter}:"
    Write-Info "Formatting new ESP at $newEspPath as FAT32..."
    Format-Volume -DriveLetter $letter -FileSystem FAT32 -NewFileSystemLabel 'EFI' -Force | Out-Null

    # Deploy Windows boot files to the new ESP
    Write-Info 'Deploying Windows boot files to the new ESP...'
    bcdboot C:\Windows /s $newEspPath /f UEFI | Out-Null

    # Optionally copy existing ESP contents (kept minimal; bcdboot is authoritative for Windows)
    if ($esp) {
        try {
            $oldLetter = (Get-Volume -Partition $esp -ErrorAction SilentlyContinue).DriveLetter
            if (-not $oldLetter) {
                $tmpLtr = 'S'
                Set-Partition -DiskNumber $esp.DiskNumber -PartitionNumber $esp.PartitionNumber -NewDriveLetter $tmpLtr -ErrorAction SilentlyContinue | Out-Null
                $oldLetter = $tmpLtr
            }
            if ($oldLetter) {
                Write-Info 'Copying non-Microsoft boot entries from old ESP (if any)...'
                robocopy "${oldLetter}:\EFI" "${newEspPath}\EFI" /E /NFL /NDL /NJH /NJS /COPY:DAT /R:1 /W:1 | Out-Null
            }
        } catch { Write-Warn 'Skipping ESP content copy.' }
    }

    Write-Info 'New ESP created and populated. Old ESP is left intact as fallback.'
    return (Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.AccessPaths -like "$newEspPath*" })
}

function Test-ArchInstallationMedia {
    Write-Info 'Scanning for existing Arch Linux USB drives...'
    $usbDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and $_.Size -gt 1GB }
    $archDrives = @()
    
    foreach ($drive in $usbDrives) {
        $driveLetter = $drive.DeviceID
        $label = $drive.VolumeLabel
        $size = [math]::Round($drive.Size / 1GB, 2)
        
        # Check for common Arch Linux indicators
        $archIndicators = @(
            "$driveLetter\arch\",
            "$driveLetter\EFI\arch\",
            "$driveLetter\isolinux\",
            "$driveLetter\boot\"
        )
        
        $isArch = $false
        foreach ($indicator in $archIndicators) {
            if (Test-Path $indicator) {
                $isArch = $true
                break
            }
        }
        
        if ($isArch -or $label -match 'ARCH|arch|Arch') {
            $archDrives += @{
                DriveLetter = $driveLetter
                Label = $label
                Size = $size
                IsArch = $isArch
            }
        }
    }
    
    return $archDrives
}

function Test-RufusInstallation {
    param([string]$RufusPath)
    
    if ($RufusPath -and (Test-Path $RufusPath)) {
        Write-Info "Rufus found at: $RufusPath"
        try {
            $version = (Get-ItemProperty $RufusPath).VersionInfo.FileVersion
            Write-Info "Rufus version: $version"
            return $true
        } catch {
            Write-Warn "Could not determine Rufus version: $($_.Exception.Message)"
            return $true  # Assume it's working if we can't get version
        }
    }
    
    # Try common installation paths
    $commonPaths = @(
        "${env:ProgramFiles}\Rufus\rufus.exe",
        "${env:ProgramFiles(x86)}\Rufus\rufus.exe",
        "${env:LOCALAPPDATA}\Rufus\rufus.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-Info "Found Rufus at: $path"
            return $true
        }
    }
    
    Write-Warn 'Rufus not found. Please install Rufus from https://rufus.ie/'
    Write-Info 'You can also specify the path with -RufusPath parameter'
    return $false
}

function Test-USBDriveStatus {
    Write-Info 'Checking USB drive status...'
    $usbDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    
    if ($usbDrives.Count -eq 0) {
        Write-Warn 'No USB drives detected. Please insert a USB drive.'
        return $false
    }
    
    Write-Info "Found $($usbDrives.Count) USB drive(s):"
    foreach ($drive in $usbDrives) {
        $driveLetter = $drive.DeviceID
        $label = $drive.VolumeLabel
        $size = [math]::Round($drive.Size / 1GB, 2)
        $freeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
        
        Write-Info "  $driveLetter - $label (${size}GB total, ${freeSpace}GB free)"
        
        # Check for errors
        if ($drive.Status -ne 'OK') {
            Write-Warn "    Warning: Drive status is $($drive.Status)"
        }
        
        # Check for sufficient space (at least 2GB for Arch ISO)
        if ($freeSpace -lt 2) {
            Write-Warn "    Warning: Insufficient free space for Arch Linux ISO"
        }
    }
    
    return $true
}

function Launch-Rufus {
    param([string]$Path,[string]$Iso,[string]$Device)
    if (-not (Test-Path $Path)) { Write-Warn 'Rufus not found; skipping USB creation.'; return }
    if (-not (Test-Path $Iso))  { Write-Warn 'ISO path invalid; skipping USB creation.'; return }
    Write-Info 'Launching Rufus to create Arch USB (manual confirmation likely required)...'
    # Many Rufus versions lack a stable CLI; pass ISO to preselect it and open GUI
    $rufusArgs = @()
    if ($Iso)    { $rufusArgs += @($Iso) }
    Start-Process -FilePath $Path -ArgumentList $rufusArgs -Verb RunAs
}

function Disable-FastStartupSafely {
    try {
        Write-Info 'Disabling Fast Startup (registry)...'
        $reg = 'HKLM:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System'
        New-Item -Path $reg -Force | Out-Null
        New-ItemProperty -Path $reg -Name 'HiberbootEnabled' -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Info 'Fast Startup disabled.'
    } catch {
        Write-Warn "Failed to disable Fast Startup: $($_.Exception.Message)"
    }
}

function Disable-HibernationSafely {
    try {
        Write-Info 'Disabling Hibernation (powercfg /h off)...'
        powercfg /h off | Out-Null
        Write-Info 'Hibernation disabled.'
    } catch {
        Write-Warn "Failed to disable Hibernation: $($_.Exception.Message)"
    }
}

try {
    Write-Log 'INFO' 'Starting Arch Linux USB setup process...'
    
    # Step 1: Admin check and input validation
    Show-Progress 1 8 'Validating prerequisites'
    Assert-Admin
    Test-InputValidation
    
    # Step 2: Power fixes
    Show-Progress 2 8 'Applying power fixes'
    if ($ApplyPowerFixes -or $DisableHibernation) { Disable-HibernationSafely }
    if ($ApplyPowerFixes -or $DisableFastStartup) { Disable-FastStartupSafely }

    # Step 3: Preflight checks
    Show-Progress 3 8 'Running preflight checks'
    $precheck = Join-Path $PSScriptRoot 'Preflight-Checklist.ps1'
    if (-not (Test-Path $precheck)) { throw "Missing script: $precheck" }
    & $precheck -MinEspMiB $MinEspMiB
    if ($LASTEXITCODE -ne 0) { throw 'Preflight checks failed. Resolve issues and re-run.' }

    # Step 4: Backup operations
    Show-Progress 4 8 'Creating backups'
    if (-not $SkipBackup) {
        New-SystemRestorePoint
        if ($BackupTargetDriveLetter -or $BackupNetworkPath) {
            New-SystemImageBackup -TargetDrive $BackupTargetDriveLetter -NetworkPath $BackupNetworkPath -Cred $BackupNetworkCredential
        } else {
            Write-Warn 'No system image backup target provided. Proceeding without a full image backup.'
        }
    } else {
        Write-Warn 'Backup skipped by user request.'
    }

    # Step 5: BitLocker suspension
    Show-Progress 5 8 'Suspending BitLocker'
    Suspend-BitLockerIfNeeded

    # Step 6: ESP management
    Show-Progress 6 8 'Ensuring ESP configuration'
    $ensureEsp = Join-Path $PSScriptRoot 'Ensure-ESP.ps1'
    if (-not (Test-Path $ensureEsp)) { throw "Missing script: $ensureEsp" }
    
    # Build parameter array for Ensure-ESP.ps1
    $ensureEspParams = @(
        '-MinEspMiB', $MinEspMiB
        '-NewEspMiB', $NewEspMiB
        '-ShrinkOsMiB', $ShrinkOsMiB
    )
    if ($AllowBitLocker) { $ensureEspParams += '-AllowBitLocker' }
    if ($SkipPendingRebootCheck) { $ensureEspParams += '-SkipPendingRebootCheck' }
    
    & $ensureEsp @ensureEspParams

    # Step 7: USB creation (if requested)
    if ($CreateUSB) {
        Show-Progress 7 8 'Preparing USB creation'
        
        # Check for existing Arch installation media
        $existingArchDrives = Test-ArchInstallationMedia
        if ($existingArchDrives.Count -gt 0) {
            Write-Info "Found existing Arch Linux USB drives:"
            foreach ($drive in $existingArchDrives) {
                Write-Info "  $($drive.DriveLetter) - $($drive.Label) (${drive.Size}GB)"
            }
            $useExisting = Read-Host "Use existing Arch USB drive? (y/N)"
            if ($useExisting -eq 'y' -or $useExisting -eq 'Y') {
                Write-Info 'Using existing Arch USB drive. Skipping Rufus launch.'
                Show-Progress 8 8 'Process completed'
                return
            }
        }
        
        # Check USB drive status
        if (-not (Test-USBDriveStatus)) {
            Write-Warn 'USB drive check failed. Please ensure USB drives are properly connected.'
        }
        
        # Validate Rufus installation
        if (-not (Test-RufusInstallation -RufusPath $RufusPath)) {
            Write-Warn 'Rufus validation failed. Please install Rufus or provide correct path.'
            return
        }
        
        # Launch Rufus via dedicated script
        $makeUsb = Join-Path $PSScriptRoot 'Make-Arch-USB.ps1'
        if (-not (Test-Path $makeUsb)) { throw "Missing script: $makeUsb" }
        & $makeUsb -RufusPath $RufusPath -ISOPath $ISOPath -USBDevice $USBDevice
    }

    # Step 8: Completion
    Show-Progress 8 8 'Process completed'
    Write-Log 'INFO' 'Arch Linux USB setup process completed successfully'
    Write-Info 'All done.'
} catch {
    Write-Log 'ERROR' "Process failed: $($_.Exception.Message)"
    Write-ErrorMsg $_
    Write-Log 'INFO' "Log file available at: $env:TEMP\arch-usb-setup.log"
    exit 1
}


