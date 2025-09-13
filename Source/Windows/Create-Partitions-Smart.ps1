<#
Purpose: Smart partition creation for Arch Linux with ZFS support.
 - Uses unallocated space first (no resizing unless necessary)
 - Asks user how much space to allocate for Linux
 - No swap partition (ZFS handles swap)
 - Resizes EFI only if needed for multiple distros
 - Interactive and user-friendly

Requirements:
 - Run as Administrator
 - GPT partition table
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [int]$DiskNumber,
    [Parameter(Mandatory=$false)] [int]$EfiSizeMB = 1024,
    [Parameter(Mandatory=$false)] [switch]$DryRun,
    [Parameter(Mandatory=$false)] [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

function Write-Log($Level, $Message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'INFO' { Write-Host $logMessage -ForegroundColor Green }
        'WARN' { Write-Host $logMessage -ForegroundColor Yellow }
        'ERROR' { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage }
    }
    
    $logFile = Join-Path $env:TEMP "create-partitions-smart.log"
    try {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        # Ignore log file errors
    }
}

function Assert-Admin {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=[Security.Principal.WindowsPrincipal]::new($id)
    if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){ throw 'Run as Administrator.' }
}

function Get-TargetDisk([int]$Number) {
    $disk = Get-Disk -Number $Number -ErrorAction SilentlyContinue
    if (-not $disk) { throw "Disk $Number not found." }
    if ($disk.PartitionStyle -ne 'GPT') { throw "Disk $Number must be GPT for UEFI operations." }
    if ($disk.HealthStatus -ne 'Healthy') { throw "Disk $Number health status is not healthy: $($disk.HealthStatus)" }
    return $disk
}

function Get-UnallocatedSpace([Microsoft.Management.Infrastructure.CimInstance]$Disk) {
    try {
        $partitions = Get-Partition -DiskNumber $Disk.Number | Sort-Object Offset
        $diskSize = $Disk.Size
        $unallocatedRegions = @()
        
        $currentOffset = 1MB
        
        foreach ($partition in $partitions) {
            if ($partition.Offset -gt $currentOffset) {
                $unallocatedRegions += @{
                    Offset = $currentOffset
                    Size = $partition.Offset - $currentOffset
                }
            }
            $currentOffset = $partition.Offset + $partition.Size
        }
        
        if ($currentOffset -lt $diskSize) {
            $unallocatedRegions += @{
                Offset = $currentOffset
                Size = $diskSize - $currentOffset
            }
        }
        
        return $unallocatedRegions
    } catch {
        throw "Failed to analyze unallocated space: $($_.Exception.Message)"
    }
}

function Get-EspPartition([Microsoft.Management.Infrastructure.CimInstance]$Disk) {
    $espGuid = '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    $esp = Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.GptType -eq $espGuid }
    return $esp
}

function Show-DiskAnalysis([Microsoft.Management.Infrastructure.CimInstance]$Disk) {
    Write-Info "=== Disk Analysis ==="
    Write-Info "Disk: $($disk.FriendlyName) ($([math]::Round($disk.Size / 1GB, 2))GB)"
    
    # Check EFI partition
    $esp = Get-EspPartition -Disk $Disk
    if ($esp) {
        $espSizeMB = [math]::Round($esp.Size / 1MB)
        Write-Info "EFI Partition: ${espSizeMB}MB"
        if ($espSizeMB -lt $EfiSizeMB) {
            Write-Warn "  → Needs resizing to ${EfiSizeMB}MB for multiple distros"
        } else {
            Write-Info "  → Adequate size for multiple distros"
        }
    } else {
        Write-Err "No EFI System Partition found!"
    }
    
    # Check unallocated space
    $unallocatedRegions = Get-UnallocatedSpace -Disk $Disk
    $totalUnallocated = 0
    foreach ($region in $unallocatedRegions) {
        $totalUnallocated += $region.Size
    }
    $totalUnallocatedGB = [math]::Round($totalUnallocated / 1GB, 2)
    
    Write-Info "Unallocated Space: ${totalUnallocatedGB}GB"
    if ($unallocatedRegions.Count -gt 0) {
        Write-Info "  Available regions:"
        for ($i = 0; $i -lt $unallocatedRegions.Count; $i++) {
            $region = $unallocatedRegions[$i]
            $sizeGB = [math]::Round($region.Size / 1GB, 2)
            $offsetGB = [math]::Round($region.Offset / 1GB, 2)
            if ($sizeGB -gt 0) {
                Write-Info "    Region $($i + 1): ${sizeGB}GB at offset ${offsetGB}GB"
            }
        }
    }
    
    return @{
        Esp = $esp
        UnallocatedRegions = $unallocatedRegions
        TotalUnallocated = $totalUnallocated
    }
}

function Get-UserInput([int]$MaxSizeGB) {
    Write-Info "`n=== Linux Partition Setup ==="
    Write-Info "ZFS will handle swap automatically, so we only need a root partition."
    Write-Info "Available unallocated space: ${MaxSizeGB}GB"
    
    do {
        $input = Read-Host "How much space to allocate for Linux root partition? (GB, 20-${MaxSizeGB})"
        if ($input -match '^\d+$') {
            $sizeGB = [int]$input
            if ($sizeGB -ge 20 -and $sizeGB -le $MaxSizeGB) {
                return $sizeGB
            } else {
                Write-Warn "Please enter a number between 20 and ${MaxSizeGB}"
            }
        } else {
            Write-Warn "Please enter a valid number"
        }
    } while ($true)
}

function Get-EfiSizeChoice([int]$CurrentSizeMB) {
    Write-Info "`n=== EFI Partition Size Selection ==="
    Write-Info "Current EFI partition size: ${CurrentSizeMB}MB"
    Write-Info "`nChoose EFI partition size for multiple Linux distributions:"
    Write-Info "1. 512 MB  - Minimum for multiple distros"
    Write-Info "2. 1 GB    - Recommended for multiple distros + recovery tools"
    Write-Info "3. 2 GB    - Future-proof for many distros"
    Write-Info "4. Keep current size (${CurrentSizeMB}MB) - May limit future distros"
    
    do {
        $choice = Read-Host "`nSelect option (1-4)"
        switch ($choice) {
            "1" { return 512 }
            "2" { return 1024 }
            "3" { return 2048 }
            "4" { return $CurrentSizeMB }
            default { Write-Warn "Please enter 1, 2, 3, or 4" }
        }
    } while ($true)
}

function Create-NewEfiPartition([Microsoft.Management.Infrastructure.CimInstance]$Disk, [int]$NewSizeMB, [bool]$DryRun) {
    Write-Info "Creating new ${NewSizeMB}MB EFI partition in unallocated space..."
    
    if ($DryRun) {
        Write-Info "DRY RUN: Would create new ${NewSizeMB}MB EFI partition"
        return "Would create new EFI partition"
    }
    
    try {
        # Create new EFI partition at the end of unallocated space
        $espGuid = '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
        $newEsp = New-Partition -DiskNumber $Disk.Number -Size ($NewSizeMB * 1MB) -GptType $espGuid -AssignDriveLetter
        Write-Info "Created new EFI partition: $($newEsp.PartitionNumber)"
        
        # Assign drive letter if not automatically assigned
        $letter = ($newEsp | Get-Volume).DriveLetter
        if (-not $letter) {
            $letter = 'S'
            Set-Partition -DiskNumber $Disk.Number -PartitionNumber $newEsp.PartitionNumber -NewDriveLetter $letter
        }
        
        # Format as FAT32
        Write-Info "Formatting new EFI partition as FAT32..."
        Format-Volume -DriveLetter $letter -FileSystem FAT32 -NewFileSystemLabel 'EFI' -Force | Out-Null
        
        # Copy Windows boot files to new EFI
        Write-Info "Copying Windows boot files to new EFI partition..."
        bcdboot C:\Windows /s "$letter:" /f UEFI | Out-Null
        
        # Set the new EFI as the primary boot partition
        Write-Info "Setting new EFI partition as primary boot partition..."
        try {
            # Update BCD to point to new EFI
            bcdedit /set "{bootmgr}" device "partition=$letter:"
            bcdedit /set "{bootmgr}" path "\EFI\Microsoft\Boot\bootmgfw.efi"
            Write-Info "New EFI partition set as primary boot partition"
        } catch {
            Write-Warn "Could not set new EFI as primary - manual configuration may be needed"
        }
        
        Write-Info "New EFI partition created and configured successfully"
        Write-Info "Old EFI partition kept as fallback"
        Write-Warn "IMPORTANT: During Arch Linux installation, you may need to:"
        Write-Warn "1. Delete the old EFI partition (nvme0n1p1) to force use of new EFI"
        Write-Warn "2. Or manually specify the new EFI partition for GRUB installation"
        
        return (Get-Partition -DiskNumber $Disk.Number -PartitionNumber $newEsp.PartitionNumber)
    } catch {
        throw "Failed to create new EFI partition: $($_.Exception.Message)"
    }
}

function Resize-EspIfNeeded([Microsoft.Management.Infrastructure.CimInstance]$Disk, [Microsoft.Management.Infrastructure.CimInstance]$Esp, [int]$RequiredSizeMB, [array]$UnallocatedRegions, [bool]$DryRun) {
    if (-not $Esp) {
        Write-Err "No EFI partition found - cannot proceed"
        return $null
    }
    
    $currentSizeMB = [math]::Round($Esp.Size / 1MB)
    if ($currentSizeMB -ge $RequiredSizeMB) {
        Write-Info "EFI partition is already ${currentSizeMB}MB (>= ${RequiredSizeMB}MB required)"
        return $Esp
    }
    
    # Check if we have enough unallocated space for new EFI
    $totalUnallocated = 0
    foreach ($region in $UnallocatedRegions) {
        $totalUnallocated += $region.Size
    }
    $requiredBytes = $RequiredSizeMB * 1MB
    
    if ($totalUnallocated -lt $requiredBytes) {
        Write-Warn "Insufficient unallocated space for new EFI partition"
        Write-Warn "Required: ${RequiredSizeMB}MB, Available: $([math]::Round($totalUnallocated / 1MB))MB"
        Write-Warn "Continuing with current EFI size: ${currentSizeMB}MB"
        return $Esp
    }
    
    Write-Info "`nEFI Partition Upgrade Plan:"
    Write-Info "  Current: ${currentSizeMB}MB (kept as fallback)"
    Write-Info "  New: ${RequiredSizeMB}MB (created in unallocated space)"
    Write-Info "  Windows boot files will be copied to new EFI"
    
    $choice = Read-Host "`nCreate new larger EFI partition? (y/N)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        return Create-NewEfiPartition -Disk $Disk -NewSizeMB $RequiredSizeMB -DryRun $DryRun
    } else {
        Write-Info "Using current EFI partition size: ${currentSizeMB}MB"
        Write-Warn "Note: This may limit future Linux distributions"
        return $Esp
    }
}

function New-LinuxRootPartition([Microsoft.Management.Infrastructure.CimInstance]$Disk, [array]$UnallocatedRegions, [int]$SizeGB, [bool]$DryRun) {
    # Find the largest unallocated region
    $largestRegion = $UnallocatedRegions | Sort-Object Size -Descending | Select-Object -First 1
    $requiredBytes = $SizeGB * 1GB
    
    if ($largestRegion.Size -lt $requiredBytes) {
        $availableGB = [math]::Round($largestRegion.Size / 1GB, 2)
        throw "Largest unallocated region (${availableGB}GB) is smaller than requested size (${SizeGB}GB)"
    }
    
    Write-Info "Creating Linux root partition in unallocated space:"
    Write-Info "  Size: ${SizeGB}GB"
    Write-Info "  Location: Offset $([math]::Round($largestRegion.Offset / 1GB, 2))GB"
    
    if ($DryRun) {
        Write-Info "DRY RUN: Would create ${SizeGB}GB root partition"
        return "Would create root partition"
    }
    
    try {
        $rootPartition = New-Partition -DiskNumber $Disk.Number -Size $requiredBytes -GptType '{0FC63DAF-8483-4772-8E79-3D69D8477DE4}'
        Write-Info "Created Linux root partition: $($rootPartition.PartitionNumber)"
        return $rootPartition
    } catch {
        throw "Failed to create Linux root partition: $($_.Exception.Message)"
    }
}

try {
    Write-Log 'INFO' 'Starting smart partition creation process...'
    
    Assert-Admin
    
    $disk = Get-TargetDisk -Number $DiskNumber
    Write-Log 'INFO' "Working with disk: $($disk.FriendlyName) (Number: $DiskNumber)"
    
    # Analyze disk
    $analysis = Show-DiskAnalysis -Disk $disk
    
    # Get user choice for EFI size
    $currentEfiSizeMB = [math]::Round($analysis.Esp.Size / 1MB)
    $chosenEfiSizeMB = Get-EfiSizeChoice -CurrentSizeMB $currentEfiSizeMB
    
    # Check if we have enough unallocated space
    $maxSizeGB = [math]::Floor($analysis.TotalUnallocated / 1GB)
    if ($maxSizeGB -lt 20) {
        throw "Insufficient unallocated space. Available: ${maxSizeGB}GB, Minimum required: 20GB"
    }
    
    # Get user input for Linux partition size
    $linuxSizeGB = Get-UserInput -MaxSizeGB $maxSizeGB
    
    # Show plan
    Write-Info "`n=== Partition Plan ==="
    if ($chosenEfiSizeMB -gt $currentEfiSizeMB) {
        Write-Info "EFI Partition: ${currentEfiSizeMB}MB → ${chosenEfiSizeMB}MB (requires Ensure-ESP.ps1)"
    } else {
        Write-Info "EFI Partition: ${currentEfiSizeMB}MB (keeping current size)"
    }
    Write-Info "Linux Root: ${linuxSizeGB}GB (ZFS will handle swap)"
    Write-Info "Using unallocated space: ${maxSizeGB}GB available"
    
    if (-not $Force -and -not $DryRun) {
        $confirmation = Read-Host "`nProceed with partition creation? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Info "Operation cancelled by user."
            exit 0
        }
    }
    
    # Step 1: Handle EFI partition
    $esp = Resize-EspIfNeeded -Disk $disk -Esp $analysis.Esp -RequiredSizeMB $chosenEfiSizeMB -UnallocatedRegions $analysis.UnallocatedRegions -DryRun $DryRun
    
    # Refresh analysis after any changes
    $analysis = Show-DiskAnalysis -Disk $disk
    
    # Step 2: Create Linux root partition
    $rootPartition = New-LinuxRootPartition -Disk $disk -UnallocatedRegions $analysis.UnallocatedRegions -SizeGB $linuxSizeGB -DryRun $DryRun
    
    if (-not $DryRun) {
        Write-Log 'INFO' 'Partition creation completed successfully'
        Write-Info "`n=== Success ==="
        Write-Info "EFI Partition: $($esp.PartitionNumber) ($([math]::Round($esp.Size / 1MB))MB)"
        Write-Info "Linux Root: $($rootPartition.PartitionNumber) (${linuxSizeGB}GB)"
        Write-Info "`nReady for Arch Linux installation with ZFS!"
        Write-Info "Note: ZFS will handle swap automatically - no separate swap partition needed."
    } else {
        Write-Log 'INFO' 'Dry run completed successfully'
    }
    
} catch {
    Write-Log 'ERROR' "Partition creation failed: $($_.Exception.Message)"
    Write-Err $_
    Write-Log 'INFO' "Log file available at: $env:TEMP\create-partitions-smart.log"
    exit 1
}
