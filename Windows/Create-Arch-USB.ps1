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
    [Parameter(Mandatory=$false)] [int]$ShrinkOsMiB = 512              # Amount to shrink OS volume if needed
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
    $cVol  = Get-Volume -DriveLetter C
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
            $letter = (Get-Partition -DiskNumber $Disk.Number -PartitionNumber $newEsp.PartitionNumber | Set-Partition -NewDriveLetter (Get-ChildItem Function: | Measure-Object).Count | Out-Null; (Get-Volume -Partition $newEsp).DriveLetter)
        }
    }
    if (-not $letter) { throw 'Failed to assign drive letter to new ESP.' }

    $newEspPath = "$letter:"
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
                robocopy "$oldLetter:\EFI" "$newEspPath\EFI" /E /NFL /NDL /NJH /NJS /COPY:DAT /R:1 /W:1 | Out-Null
            }
        } catch { Write-Warn 'Skipping ESP content copy.' }
    }

    Write-Info 'New ESP created and populated. Old ESP is left intact as fallback.'
    return (Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.AccessPaths -like "$newEspPath*" })
}

function Launch-Rufus {
    param([string]$Path,[string]$Iso,[string]$Device)
    if (-not (Test-Path $Path)) { Write-Warn 'Rufus not found; skipping USB creation.'; return }
    if (-not (Test-Path $Iso))  { Write-Warn 'ISO path invalid; skipping USB creation.'; return }
    Write-Info 'Launching Rufus to create Arch USB (manual confirmation likely required)...'
    # Many Rufus versions lack a stable CLI; pass ISO to preselect it and open GUI
    $args = @()
    if ($Iso)    { $args += @($Iso) }
    Start-Process -FilePath $Path -ArgumentList $args -Verb RunAs
}

try {
    Assert-Admin

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

    Suspend-BitLockerIfNeeded

    $disk = Get-OsDisk
    $finalEsp = Ensure-LargeEsp -Disk $disk -MinMiB $MinEspMiB -NewMiB $NewEspMiB -ShrinkMiB $ShrinkOsMiB
    if ($finalEsp) {
        $vol = Get-Volume -Partition $finalEsp -ErrorAction SilentlyContinue
        $path = if ($vol) { "$($vol.DriveLetter):" } else { '(no drive letter assigned)' }
        Write-Info "ESP ready: PartitionNumber=$($finalEsp.PartitionNumber) SizeMiB=$([math]::Round($finalEsp.Size/1MB)) Path=$path"
        Write-Info 'You can now proceed to boot the Arch USB and install. Mount the larger ESP at /boot.'
    }

    if ($CreateUSB) { Launch-Rufus -Path $RufusPath -Iso $ISOPath -Device $USBDevice }

    Write-Info 'All done.'
} catch {
    Write-ErrorMsg $_
    exit 1
}


