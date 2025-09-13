<#
Purpose: Ensure a sufficiently sized EFI System Partition (ESP) using a safe method.
 - Never shrinks/moves the original ESP
 - Creates a new ESP at the end of disk and deploys Windows boot files via bcdboot

Run as Administrator.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [int]$MinEspMiB = 260,
    [Parameter(Mandatory=$false)] [int]$NewEspMiB = 300,
    [Parameter(Mandatory=$false)] [int]$ShrinkOsMiB = 512,
    [Parameter(Mandatory=$false)] [switch]$AllowBitLocker,
    [Parameter(Mandatory=$false)] [switch]$SkipPendingRebootCheck
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
    
    # Write to log file
    $logFile = Join-Path $env:TEMP "ensure-esp.log"
    try {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        # Ignore log file errors
    }
}

function Test-InputValidation {
    Write-Log 'INFO' 'Validating input parameters...'
    
    # Validate ESP sizes
    if ($MinEspMiB -lt 100) { throw 'MinEspMiB must be at least 100 MiB' }
    if ($NewEspMiB -lt $MinEspMiB) { throw 'NewEspMiB must be at least MinEspMiB' }
    if ($ShrinkOsMiB -lt 100) { throw 'ShrinkOsMiB must be at least 100 MiB' }
    
    # Validate reasonable limits
    if ($MinEspMiB -gt 1000) { throw 'MinEspMiB seems too large (>1000 MiB)' }
    if ($NewEspMiB -gt 2000) { throw 'NewEspMiB seems too large (>2000 MiB)' }
    if ($ShrinkOsMiB -gt 10000) { throw 'ShrinkOsMiB seems too large (>10000 MiB)' }
    
    Write-Log 'INFO' 'Input validation completed successfully'
}

function Assert-Admin {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=[Security.Principal.WindowsPrincipal]::new($id)
    if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){ throw 'Run as Administrator.' }
}

function Get-OsDisk {
    $cPart = Get-Partition -DriveLetter C
    $disk  = Get-Disk | Where-Object { $_.Number -eq $cPart.DiskNumber }
    if (-not $disk) { throw 'Unable to determine OS disk.' }
    if ($disk.PartitionStyle -ne 'GPT') { throw 'Disk must be GPT for UEFI/ESP operations.' }
    $disk
}

function Get-Esp([Microsoft.Management.Infrastructure.CimInstance]$Disk) {
    $guid='{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.GptType -eq $guid }
}

function Test-PendingReboot {
    try {
        $reboot = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue)
        return [bool]$reboot
    } catch { return $false }
}

function Assert-NoPendingReboot {
    if (-not $SkipPendingRebootCheck) {
        if (Test-PendingReboot) { throw 'A reboot is pending. Please reboot Windows and re-run this script.' }
    }
}

function Assert-BitLockerSuspended {
    try {
        $osVol = Get-BitLockerVolume -MountPoint 'C:' -ErrorAction SilentlyContinue
        if ($osVol -and $osVol.ProtectionStatus -eq 'On' -and -not $AllowBitLocker) {
            throw 'BitLocker is enabled on C:. Suspend BitLocker (manage-bde -protectors -disable C: -RebootCount 1) and retry, or pass -AllowBitLocker to proceed at your own risk.'
        }
    } catch {
        Write-Warn 'BitLocker status could not be determined; proceeding. Consider suspending BitLocker before ESP changes.'
    }
}

function Ensure-LargeEsp([Microsoft.Management.Infrastructure.CimInstance]$Disk,[int]$MinMiB,[int]$NewMiB,[int]$ShrinkMiB){
    $esp = Get-Esp -Disk $Disk
    if($esp){
        $mi=[math]::Round($esp.Size/1MB)
        if($mi -ge $MinMiB){ Write-Info "ESP OK: $mi MiB"; return $esp }
        Write-Warn "ESP $mi MiB < $MinMiB MiB; creating new ESP."
    } else { Write-Warn 'No ESP found; creating new ESP.' }

    $cPart = Get-Partition -DriveLetter C
    $supported = $null
    try {
        $supported = Get-PartitionSupportedSize -DriveLetter C
    } catch {
        throw 'Failed to query supported shrink size for C:. Ensure you are running as Administrator.'
    }

    $desiredSize = $cPart.Size - ($ShrinkMiB * 1MB)
    if ($desiredSize -lt 20GB) { throw 'C: would become too small. Reduce -ShrinkOsMiB or free space on C:.' }
    if ($desiredSize -lt $supported.SizeMin) {
        throw "Insufficient shrink headroom. Minimum supported size is $([math]::Round($supported.SizeMin/1MB)) MiB. Free space, disable hibernation/Fast Startup, reduce restore points, then retry."
    }

    try {
        Write-Info "Shrinking C: by $ShrinkMiB MiB..."
        Resize-Partition -DriveLetter C -Size $desiredSize
    } catch {
        throw "Failed to shrink C:: $($_.Exception.Message). Try: powercfg /h off; disable Fast Startup; run Disk Cleanup; reboot and retry."
    }

    $guid='{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    Write-Info "Creating new $NewMiB MiB ESP..."
    try {
        $newEsp = New-Partition -DiskNumber $Disk.Number -Size ($NewMiB*1MB) -GptType $guid -AssignDriveLetter
    } catch {
        throw "Failed to create new ESP: $($_.Exception.Message). Ensure there is unallocated space at disk end."
    }
    $letter = ($newEsp | Get-Volume).DriveLetter
    if(-not $letter){
        try {
            $letter = 'S'
            Set-Partition -DiskNumber $Disk.Number -PartitionNumber $newEsp.PartitionNumber -NewDriveLetter $letter
            # Verify assignment worked
            if (-not (Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue)) {
                throw 'Failed to assign drive letter'
            }
        } catch {
            throw 'Failed to assign a drive letter to the new ESP.'
        }
    }
    try {
        Format-Volume -DriveLetter $letter -FileSystem FAT32 -NewFileSystemLabel 'EFI' -Force | Out-Null
    } catch {
        throw "Failed to format the new ESP: $($_.Exception.Message)"
    }

    Write-Info 'Deploying Windows boot files to new ESP...'
    try {
        bcdboot C:\Windows /s "$letter:" /f UEFI | Out-Null
    } catch {
        throw "bcdboot failed to deploy boot files: $($_.Exception.Message)"
    }

    Write-Info 'New ESP ready; old ESP kept as fallback.'
    return (Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.PartitionNumber -eq $newEsp.PartitionNumber })
}

try{
    Write-Log 'INFO' 'Starting ESP management process...'
    
    Assert-Admin
    Test-InputValidation
    Assert-NoPendingReboot
    Assert-BitLockerSuspended
    
    $disk = Get-OsDisk
    Write-Log 'INFO' "Working with disk: $($disk.FriendlyName) (Number: $($disk.Number))"
    
    $esp = Ensure-LargeEsp $disk $MinEspMiB $NewEspMiB $ShrinkOsMiB
    $mi = [math]::Round($esp.Size/1MB)
    $vol = $esp | Get-Volume -ErrorAction SilentlyContinue
    $path = if($vol){"$($vol.DriveLetter):"}else{'(no drive letter)'}
    
    Write-Log 'INFO' "ESP management completed successfully"
    Write-Info "ESP: Partition=$($esp.PartitionNumber) Size=$mi MiB Path=$path"
}catch{ 
    Write-Log 'ERROR' "ESP management failed: $($_.Exception.Message)"
    Write-Err $_ 
    Write-Log 'INFO' "Log file available at: $env:TEMP\ensure-esp.log"
    exit 1 
}


