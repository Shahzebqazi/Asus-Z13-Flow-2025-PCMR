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
    [Parameter(Mandatory=$false)] [int]$ShrinkOsMiB = 512
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

function Ensure-LargeEsp([Microsoft.Management.Infrastructure.CimInstance]$Disk,[int]$MinMiB,[int]$NewMiB,[int]$ShrinkMiB){
    $esp = Get-Esp -Disk $Disk
    if($esp){
        $mi=[math]::Round($esp.Size/1MB)
        if($mi -ge $MinMiB){ Write-Info "ESP OK: $mi MiB"; return $esp }
        Write-Warn "ESP $mi MiB < $MinMiB MiB; creating new ESP."
    } else { Write-Warn 'No ESP found; creating new ESP.' }

    $cPart   = Get-Partition -DriveLetter C
    $newSize = $cPart.Size - ($ShrinkMiB * 1MB)
    if($newSize -lt 20GB){ throw 'C: too small to shrink safely.' }
    Write-Info "Shrinking C: by $ShrinkMiB MiB..."; Resize-Partition -DriveLetter C -Size $newSize

    $guid='{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    Write-Info "Creating new $NewMiB MiB ESP..."
    $newEsp = New-Partition -DiskNumber $Disk.Number -Size ($NewMiB*1MB) -GptType $guid -AssignDriveLetter
    $letter = ($newEsp | Get-Volume).DriveLetter
    if(-not $letter){ $letter='S'; Set-Partition -DiskNumber $Disk.Number -PartitionNumber $newEsp.PartitionNumber -NewDriveLetter $letter }
    Format-Volume -DriveLetter $letter -FileSystem FAT32 -NewFileSystemLabel 'EFI' -Force | Out-Null

    Write-Info 'Deploying Windows boot files to new ESP...'
    bcdboot C:\Windows /s "$letter:" /f UEFI | Out-Null

    Write-Info 'New ESP ready; old ESP kept as fallback.'
    return (Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.PartitionNumber -eq $newEsp.PartitionNumber })
}

try{
    Assert-Admin
    $disk = Get-OsDisk
    $esp  = Ensure-LargeEsp $disk $MinEspMiB $NewEspMiB $ShrinkOsMiB
    $mi=[math]::Round($esp.Size/1MB)
    $vol=$esp|Get-Volume -ErrorAction SilentlyContinue
    $path= if($vol){"$($vol.DriveLetter):"}else{'(no drive letter)'}
    Write-Info "ESP: Partition=$($esp.PartitionNumber) Size=$mi MiB Path=$path"
}catch{ Write-Err $_; exit 1 }


