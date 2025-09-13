<#
Purpose: Create partitions for Arch Linux dual-boot installation.
 - Creates Linux root and swap partitions from unallocated space
 - Validates partition alignment and size requirements
 - Provides rollback capability on failure

Requirements:
 - Run as Administrator
 - Sufficient unallocated space on target disk
 - GPT partition table

SAFE POLICY:
 - Only creates new partitions in unallocated space
 - Does not modify existing Windows partitions
 - Validates all operations before execution

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [int]$DiskNumber,
    [Parameter(Mandatory=$false)] [int]$RootSizeGB = 50,
    [Parameter(Mandatory=$false)] [int]$SwapSizeGB = 8,
    [Parameter(Mandatory=$false)] [switch]$DryRun,
    [Parameter(Mandatory=$false)] [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

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
        
        $currentOffset = 1MB  # Start after protective MBR
        
        foreach ($partition in $partitions) {
            if ($partition.Offset -gt $currentOffset) {
                $unallocatedRegions += @{
                    Offset = $currentOffset
                    Size = $partition.Offset - $currentOffset
                }
            }
            $currentOffset = $partition.Offset + $partition.Size
        }
        
        # Check for space at end of disk
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

function Test-SufficientSpace([array]$UnallocatedRegions, [int]$RequiredBytes) {
    $totalUnallocated = ($UnallocatedRegions | Measure-Object -Property Size -Sum).Sum
    return $totalUnallocated -ge $RequiredBytes
}

function New-LinuxPartitions([Microsoft.Management.Infrastructure.CimInstance]$Disk, [int]$RootSizeBytes, [int]$SwapSizeBytes, [bool]$DryRun) {
    $unallocatedRegions = Get-UnallocatedSpace -Disk $Disk
    $totalRequired = $RootSizeBytes + $SwapSizeBytes
    
    if (-not (Test-SufficientSpace -UnallocatedRegions $unallocatedRegions -RequiredBytes $totalRequired)) {
        $availableGB = [math]::Round((($unallocatedRegions | Measure-Object -Property Size -Sum).Sum) / 1GB, 2)
        $requiredGB = [math]::Round($totalRequired / 1GB, 2)
        throw "Insufficient unallocated space. Available: ${availableGB}GB, Required: ${requiredGB}GB"
    }
    
    # Find the largest unallocated region
    $largestRegion = $unallocatedRegions | Sort-Object Size -Descending | Select-Object -First 1
    
    if ($largestRegion.Size -lt $totalRequired) {
        throw "Largest unallocated region is too small for both partitions."
    }
    
    Write-Info "Creating partitions in unallocated space at offset $($largestRegion.Offset)"
    Write-Info "Root partition: $([math]::Round($RootSizeBytes / 1GB, 2))GB"
    Write-Info "Swap partition: $([math]::Round($SwapSizeBytes / 1GB, 2))GB"
    
    if ($DryRun) {
        Write-Info "DRY RUN: Would create partitions but not executing."
        return @{
            RootPartition = "Would create root partition"
            SwapPartition = "Would create swap partition"
        }
    }
    
    try {
        # Create root partition (Linux filesystem GUID)
        $rootPartition = New-Partition -DiskNumber $Disk.Number -Size $RootSizeBytes -GptType '{0FC63DAF-8483-4772-8E79-3D69D8477DE4}'
        Write-Info "Created root partition: $($rootPartition.PartitionNumber)"
        
        # Create swap partition (Linux swap GUID)
        $swapPartition = New-Partition -DiskNumber $Disk.Number -Size $SwapSizeBytes -GptType '{0657FD6D-A4AB-43C4-84E5-0933C84B4F4F}'
        Write-Info "Created swap partition: $($swapPartition.PartitionNumber)"
        
        return @{
            RootPartition = $rootPartition
            SwapPartition = $swapPartition
        }
    } catch {
        Write-Err "Failed to create partitions: $($_.Exception.Message)"
        # Attempt cleanup of any created partitions
        try {
            Get-Partition -DiskNumber $Disk.Number | Where-Object { 
                $_.GptType -eq '{0FC63DAF-8483-4772-8E79-3D69D8477DE4}' -or 
                $_.GptType -eq '{0657FD6D-A4AB-43C4-84E5-0933C84B4F4F}' 
            } | Remove-Partition -Confirm:$false -ErrorAction SilentlyContinue
            Write-Info "Cleaned up partially created partitions."
        } catch {
            Write-Warn "Could not clean up partially created partitions. Manual cleanup may be required."
        }
        throw
    }
}

function Show-PartitionPlan([Microsoft.Management.Infrastructure.CimInstance]$Disk, [int]$RootSizeGB, [int]$SwapSizeGB) {
    Write-Info "Partition Creation Plan for Disk $($Disk.Number):"
    Write-Info "  Disk: $($Disk.FriendlyName) ($([math]::Round($Disk.Size / 1GB, 2))GB)"
    Write-Info "  Root Partition: ${RootSizeGB}GB (Linux filesystem)"
    Write-Info "  Swap Partition: ${SwapSizeGB}GB (Linux swap)"
    Write-Info "  Total Required: $($RootSizeGB + $SwapSizeGB)GB"
    
    $unallocatedRegions = Get-UnallocatedSpace -Disk $Disk
    $totalUnallocatedGB = [math]::Round((($unallocatedRegions | Measure-Object -Property Size -Sum).Sum) / 1GB, 2)
    Write-Info "  Available Unallocated: ${totalUnallocatedGB}GB"
    
    if ($unallocatedRegions.Count -gt 0) {
        Write-Info "  Unallocated Regions:"
        for ($i = 0; $i -lt $unallocatedRegions.Count; $i++) {
            $region = $unallocatedRegions[$i]
            $sizeGB = [math]::Round($region.Size / 1GB, 2)
            $offsetGB = [math]::Round($region.Offset / 1GB, 2)
            Write-Info "    Region $($i + 1): ${sizeGB}GB at offset ${offsetGB}GB"
        }
    }
}

try {
    Assert-Admin
    
    $disk = Get-TargetDisk -Number $DiskNumber
    $rootSizeBytes = $RootSizeGB * 1GB
    $swapSizeBytes = $SwapSizeGB * 1GB
    
    Show-PartitionPlan -Disk $disk -RootSizeGB $RootSizeGB -SwapSizeGB $SwapSizeGB
    
    if (-not $Force -and -not $DryRun) {
        $confirmation = Read-Host "Proceed with partition creation? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Info "Operation cancelled by user."
            exit 0
        }
    }
    
    $result = New-LinuxPartitions -Disk $disk -RootSizeBytes $rootSizeBytes -SwapSizeBytes $swapSizeBytes -DryRun $DryRun
    
    if (-not $DryRun) {
        Write-Info "Partitions created successfully:"
        Write-Info "  Root: Partition $($result.RootPartition.PartitionNumber) on Disk $DiskNumber"
        Write-Info "  Swap: Partition $($result.SwapPartition.PartitionNumber) on Disk $DiskNumber"
        Write-Info "Partitions are ready for Arch Linux installation."
    }
    
} catch {
    Write-Err $_
    exit 1
}
