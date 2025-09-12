<#
Purpose: Launch Rufus to create an Arch USB installer from an ISO.
Notes:
 - Rufus CLI support varies; this script primarily preselects the ISO and elevates Rufus
 - User completes the GUI workflow

Run as Administrator.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [string]$RufusPath,
    [Parameter(Mandatory=$true)]  [string]$ISOPath,
    [Parameter(Mandatory=$false)] [string]$USBDevice
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

try {
    if (-not (Test-Path $RufusPath)) { throw "Rufus not found at: $RufusPath" }
    if (-not (Test-Path $ISOPath))   { throw "ISO not found at: $ISOPath" }

    Write-Info 'Launching Rufus...'
    $args = @()
    if ($ISOPath) { $args += @($ISOPath) }
    # $USBDevice is currently unused due to unstable CLI; documented for future use
    Start-Process -FilePath $RufusPath -ArgumentList $args -Verb RunAs
    Write-Info 'Rufus started. Select the target USB and proceed in the GUI.'
} catch {
    Write-Err $_
    exit 1
}


