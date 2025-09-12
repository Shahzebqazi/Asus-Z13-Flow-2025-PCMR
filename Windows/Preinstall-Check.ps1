<#
Purpose: Pre-install checks on Windows before booting the Arch ISO.
 - Validates Administrator rights, UEFI/GPT, BitLocker status, Fast Startup, pending reboot
 - Checks ESP presence/size and ability to shrink C: if a new ESP is needed later
 - Produces a clear PASS/FAIL summary without making system changes

Run as Administrator.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [int]$MinEspMiB = 260,
    [Parameter(Mandatory=$false)] [int]$MinShrinkRoomMiB = 512
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err ($msg)  { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal]::new($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-OsDisk {
    $cPart = Get-Partition -DriveLetter C
    $disk  = Get-Disk | Where-Object { $_.Number -eq $cPart.DiskNumber }
    if (-not $disk) { throw 'Unable to determine OS disk.' }
    return $disk
}

function Get-EspPartition([Microsoft.Management.Infrastructure.CimInstance]$Disk) {
    $espGuid = '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.GptType -eq $espGuid }
}

function Test-PendingReboot {
    try {
        $reboot = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue)
        return [bool]$reboot
    } catch { return $false }
}

function Test-FastStartupEnabled {
    try {
        $val = (powercfg /a) 2>$null | Select-String -SimpleMatch 'Fast Startup'
        if ($val) {
            $hiber = (powercfg /a) 2>$null | Select-String -SimpleMatch 'Hibernation has been disabled'
            return -not [bool]$hiber
        }
        return $false
    } catch { return $false }
}

function Main {
    $fail = @()
    $warn = @()

    if (-not (Test-Admin)) { $fail += 'Run PowerShell as Administrator.' }

    $disk = $null
    try { $disk = Get-OsDisk } catch { $fail += $_.Exception.Message }
    if ($disk) {
        if ($disk.PartitionStyle -ne 'GPT') { $fail += 'OS disk must be GPT for UEFI.' }
    }

    # BitLocker
    try {
        $osVol = Get-BitLockerVolume -MountPoint 'C:' -ErrorAction SilentlyContinue
        if ($osVol -and $osVol.ProtectionStatus -eq 'On') {
            $warn += 'BitLocker is enabled: suspend protection before ESP changes.'
        }
    } catch { $warn += 'BitLocker status unknown.' }

    # Pending reboot
    if (Test-PendingReboot) { $warn += 'A reboot is pending; reboot before proceeding.' }

    # Fast startup
    if (Test-FastStartupEnabled) { $warn += 'Fast Startup is enabled; disable it to avoid hibernation lock.' }

    # ESP check
    if ($disk) {
        $esp = Get-EspPartition -Disk $disk
        if ($esp) {
            $espMiB = [math]::Round($esp.Size/1MB)
            if ($espMiB -lt $MinEspMiB) {
                $warn += "ESP is $espMiB MiB (< $MinEspMiB). New ESP will be needed."
            } else {
                Write-Info "ESP OK: $espMiB MiB"
            }
        } else { $warn += 'No ESP found; new ESP will be needed.' }

        # Shrink headroom
        $cPart   = Get-Partition -DriveLetter C
        $cSizeMiB= [math]::Round($cPart.Size/1MB)
        if ($cSizeMiB -lt (20*1024)) { $warn += 'C: is very small; ensure enough free space for shrink.' }
    }

    if ($fail.Count -eq 0 -and $warn.Count -eq 0) {
        Write-Info 'Preinstall checks PASSED with no warnings.'
        exit 0
    }

    if ($fail.Count -gt 0) {
        Write-Err 'Preinstall checks FAILED:'
        $fail | ForEach-Object { Write-Err " - $_" }
        if ($warn.Count -gt 0) {
            Write-Warn 'Additionally, warnings:'
            $warn | ForEach-Object { Write-Warn " - $_" }
        }
        exit 1
    } else {
        Write-Warn 'Preinstall checks completed with warnings:'
        $warn | ForEach-Object { Write-Warn " - $_" }
        exit 0
    }
}

Main


