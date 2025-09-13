<#
Purpose: Safely resize EFI partition using GParted Live USB
 - Downloads GParted Live ISO
 - Creates bootable USB with Rufus
 - Provides instructions for EFI resize
 - Handles the entire process safely
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [int]$DiskNumber,
    [Parameter(Mandatory=$false)] [int]$EfiSizeMB = 512,
    [Parameter(Mandatory=$false)] [string]$RufusPath,
    [Parameter(Mandatory=$false)] [string]$DownloadPath = "$env:USERPROFILE\Downloads",
    [Parameter(Mandatory=$false)] [switch]$SkipDownload,
    [Parameter(Mandatory=$false)] [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

function Get-EspPartition([int]$DiskNumber) {
    $espGuid = '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}'
    $esp = Get-Partition -DiskNumber $DiskNumber | Where-Object { $_.GptType -eq $espGuid }
    return $esp
}

function Test-RufusInstallation([string]$RufusPath) {
    if ($RufusPath -and (Test-Path $RufusPath)) {
        Write-Info "Rufus found at: $RufusPath"
        return $true
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
    return $false
}

function Get-GPartedDownloadUrl() {
    # GParted Live stable release URL
    $baseUrl = "https://sourceforge.net/projects/gparted/files/gparted-live-stable/"
    
    try {
        # Get the latest version from sourceforge
        $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
        $content = $response.Content
        
        # Extract the latest version number
        if ($content -match 'gparted-live-stable/(\d+\.\d+-\d+)/') {
            $version = $matches[1]
            $isoUrl = "${baseUrl}${version}/gparted-live-${version}-amd64.iso/download"
            Write-Info "Latest GParted Live version: $version"
            return $isoUrl
        } else {
            # Fallback to a known stable version
            $isoUrl = "${baseUrl}1.5.0-6/gparted-live-1.5.0-6-amd64.iso/download"
            Write-Info "Using fallback GParted Live version: 1.5.0-6"
            return $isoUrl
        }
    } catch {
        Write-Warn "Could not determine latest version, using fallback"
        $isoUrl = "https://sourceforge.net/projects/gparted/files/gparted-live-stable/1.5.0-6/gparted-live-1.5.0-6-amd64.iso/download"
        return $isoUrl
    }
}

function Download-GPartedIso([string]$DownloadPath) {
    $isoPath = Join-Path $DownloadPath "gparted-live.iso"
    
    if (Test-Path $isoPath) {
        Write-Info "GParted Live ISO already exists: $isoPath"
        return $isoPath
    }
    
    Write-Info "Downloading GParted Live ISO..."
    $isoUrl = Get-GPartedDownloadUrl
    
    try {
        $progressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $isoUrl -OutFile $isoPath -UseBasicParsing
        $ProgressPreference = $progressPreference
        
        Write-Info "GParted Live ISO downloaded: $isoPath"
        return $isoPath
    } catch {
        throw "Failed to download GParted Live ISO: $($_.Exception.Message)"
    }
}

function Show-EfiResizeInstructions([int]$CurrentSizeMB, [int]$TargetSizeMB) {
    Write-Info "`n=== GParted Live EFI Resize Instructions ==="
    Write-Info "Current EFI partition: ${CurrentSizeMB}MB"
    Write-Info "Target EFI partition: ${TargetSizeMB}MB"
    Write-Info ""
    Write-Info "Step-by-step instructions:"
    Write-Info "1. Boot from the GParted Live USB"
    Write-Info "2. Wait for GParted to load (default options are fine)"
    Write-Info "3. Find your EFI partition (usually the first partition, ~260MB)"
    Write-Info "4. Right-click the EFI partition → 'Resize/Move'"
    Write-Info "5. Drag the right edge to extend the partition to ${TargetSizeMB}MB"
    Write-Info "6. Click 'Resize/Move' to confirm"
    Write-Info "7. Click the 'Apply' button (checkmark icon) to execute changes"
    Write-Info "8. Wait for the operation to complete"
    Write-Info "9. Close GParted and reboot to Windows"
    Write-Info ""
    Write-Warn "IMPORTANT SAFETY NOTES:"
    Write-Warn "- Do NOT resize any other partitions"
    Write-Warn "- Only resize the EFI partition (first partition)"
    Write-Warn "- Make sure you have a Windows recovery disk ready"
    Write-Warn "- The EFI partition should be FAT32 (GParted will preserve this)"
}

function Show-RecoveryInstructions() {
    Write-Warn "`n=== Recovery Instructions (if needed) ==="
    Write-Warn "If the EFI resize causes boot issues:"
    Write-Warn "1. Boot from Windows recovery media"
    Write-Warn "2. Open Command Prompt"
    Write-Warn "3. Run these commands:"
    Write-Warn "   bootrec /fixmbr"
    Write-Warn "   bootrec /fixboot"
    Write-Warn "   bootrec /rebuildbcd"
    Write-Warn "4. Reboot"
    Write-Warn ""
    Write-Warn "Alternative recovery:"
    Write-Warn "1. Boot from Windows installation media"
    Write-Warn "2. Choose 'Repair your computer'"
    Write-Warn "3. Select 'Troubleshoot' → 'Command Prompt'"
    Write-Warn "4. Run the same bootrec commands"
}

function Get-UserEfiSizeChoice([int]$CurrentSizeMB) {
    Write-Info "`n=== EFI Partition Size Selection ==="
    Write-Info "Current EFI partition size: ${CurrentSizeMB}MB"
    Write-Info "`nChoose EFI partition size for multiple Linux distributions:"
    Write-Info "1. 512 MB  - Minimum for multiple distros"
    Write-Info "2. 1 GB    - Recommended for multiple distros + recovery tools"
    Write-Info "3. 2 GB    - Future-proof for many distros"
    Write-Info "4. Custom size"
    
    do {
        $choice = Read-Host "`nSelect option (1-4)"
        switch ($choice) {
            "1" { return 512 }
            "2" { return 1024 }
            "3" { return 2048 }
            "4" { 
                do {
                    $customSize = Read-Host "Enter custom size in MB (minimum 260)"
                    if ($customSize -match '^\d+$' -and [int]$customSize -ge 260) {
                        return [int]$customSize
                    } else {
                        Write-Warn "Please enter a valid number >= 260"
                    }
                } while ($true)
            }
            default { Write-Warn "Please enter 1, 2, 3, or 4" }
        }
    } while ($true)
}

function Create-GPartedUsb([string]$RufusPath, [string]$IsoPath) {
    Write-Info "Creating GParted Live USB with Rufus..."
    
    if ($DryRun) {
        Write-Info "DRY RUN: Would create GParted Live USB"
        return
    }
    
    try {
        # Launch Rufus with the ISO
        Start-Process -FilePath $RufusPath -ArgumentList $IsoPath -Verb RunAs
        Write-Info "Rufus launched. Please:"
        Write-Info "1. Select your USB drive"
        Write-Info "2. Choose 'DD Image' mode"
        Write-Info "3. Click 'START' to create the bootable USB"
        Write-Info "4. Wait for completion"
    } catch {
        throw "Failed to launch Rufus: $($_.Exception.Message)"
    }
}

try {
    Write-Info "=== GParted Live EFI Resize Tool ==="
    
    # Check admin rights
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator"
    }
    
    # Get EFI partition
    $esp = Get-EspPartition -DiskNumber $DiskNumber
    if (-not $esp) {
        throw "No EFI partition found on disk $DiskNumber"
    }
    
    $currentSizeMB = [math]::Round($esp.Size / 1MB)
    Write-Info "Current EFI partition size: ${currentSizeMB}MB"
    
    # Get user choice for EFI size
    $targetSizeMB = Get-UserEfiSizeChoice -CurrentSizeMB $currentSizeMB
    
    if ($targetSizeMB -le $currentSizeMB) {
        Write-Info "EFI partition is already ${currentSizeMB}MB (>= ${targetSizeMB}MB required)"
        Write-Info "No resize needed."
        exit 0
    }
    
    # Check if Rufus is available
    if (-not (Test-RufusInstallation -RufusPath $RufusPath)) {
        Write-Err "Rufus is required to create the GParted Live USB"
        Write-Info "Please install Rufus from https://rufus.ie/ and re-run this script"
        exit 1
    }
    
    # Download GParted Live ISO
    if (-not $SkipDownload) {
        $isoPath = Download-GPartedIso -DownloadPath $DownloadPath
    } else {
        $isoPath = Join-Path $DownloadPath "gparted-live.iso"
        if (-not (Test-Path $isoPath)) {
            throw "GParted Live ISO not found at: $isoPath"
        }
    }
    
    # Show instructions
    Show-EfiResizeInstructions -CurrentSizeMB $currentSizeMB -TargetSizeMB $targetSizeMB
    
    # Create USB
    $rufusPath = if ($RufusPath) { $RufusPath } else { (Get-Command rufus -ErrorAction SilentlyContinue).Source }
    if (-not $rufusPath) {
        $rufusPath = "${env:ProgramFiles}\Rufus\rufus.exe"
    }
    
    Create-GPartedUsb -RufusPath $rufusPath -IsoPath $isoPath
    
    # Show recovery instructions
    Show-RecoveryInstructions
    
    Write-Info "`n=== Next Steps ==="
    Write-Info "1. Complete the USB creation in Rufus"
    Write-Info "2. Boot from the GParted Live USB"
    Write-Info "3. Follow the resize instructions above"
    Write-Info "4. Reboot to Windows"
    Write-Info "5. Run your Arch Linux installation"
    
} catch {
    Write-Err "Script failed: $($_.Exception.Message)"
    Show-RecoveryInstructions
    exit 1
}
