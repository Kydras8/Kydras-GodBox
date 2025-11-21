#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Make the Realtek 8814AU (AC1900) the preferred Wi-Fi adapter.

.DESCRIPTION
  - Detects the AC1900 using VID_0BDA & PID_8813 and Realtek 8814AU name.
  - Shows what it would do by default (dry-run).
  - With -MakeDefault:
      * Ensures AC1900 adapter is enabled.
      * Sets a low interface metric to prefer it.
  - With -DisableIntel (and -MakeDefault):
      * Tries to disable the Intel Dual Band Wireless-AC 3168 adapter.

  NOTE:
    - Disabling the Intel adapter is reversible (Enable-NetAdapter).
    - Must be run from an elevated PowerShell for changes to apply.
#>

[CmdletBinding()]
param(
    [switch]$MakeDefault,
    [switch]$DisableIntel
)

$ErrorActionPreference = 'Stop'

Write-Host "[AC1900-Default] Starting..." -ForegroundColor Cyan

# 1. Admin check
$principal = New-Object Security.Principal.WindowsPrincipal (
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "[AC1900-Default] This script must be run as Administrator."
    exit 1
}

# 2. Reuse the detector
$RepoRoot   = Split-Path -Parent $PSScriptRoot
$DetectPath = Join-Path (Join-Path $RepoRoot 'wireless') 'ac1900-detect.ps1'

if (-not (Test-Path $DetectPath)) {
    Write-Error "[AC1900-Default] ac1900-detect.ps1 not found at: $DetectPath"
    exit 1
}

# Call detector in JSON mode for easier parsing
$json = & $DetectPath -Json
if (-not $json) {
    Write-Error "[AC1900-Default] Detection returned no candidates."
    exit 1
}

$candidates = $json | ConvertFrom-Json
if ($candidates -isnot [System.Collections.IEnumerable]) {
    $candidates = @($candidates)
}

# Prefer Realtek 8814AU entry with Status=Up
$ac1900 = $candidates | Where-Object {
    $_.InterfaceDescription -like '*8814AU*' -and $_.NetStatus -eq 'Up'
} | Select-Object -First 1

if (-not $ac1900) {
    Write-Warning "[AC1900-Default] No active Realtek 8814AU adapter found. Using first candidate instead."
    $ac1900 = $candidates | Select-Object -First 1
}

Write-Host "[AC1900-Default] Selected adapter:" -ForegroundColor Green
$ac1900 | Format-List *

$acName = $ac1900.NetName

if (-not $acName) {
    Write-Error "[AC1900-Default] Could not determine adapter name."
    exit 1
}

# 3. Intel 3168 (if present)
$allAdapters = Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue
$intel = $allAdapters | Where-Object {
    $_.InterfaceDescription -like '*Intel*3168*'
}

if ($intel) {
    Write-Host "[AC1900-Default] Intel 3168 adapter(s) detected:" -ForegroundColor Yellow
    $intel | Select-Object Name, InterfaceDescription, Status | Format-Table
}
else {
    Write-Host "[AC1900-Default] No Intel 3168 adapter detected (or already removed)." -ForegroundColor Yellow
}

if (-not $MakeDefault) {
    Write-Host ""
    Write-Host "[AC1900-Default] DRY-RUN ONLY (no changes made)." -ForegroundColor Yellow
    Write-Host "  To apply changes, run:" -ForegroundColor Yellow
    Write-Host "    .\wireless\set-ac1900-default.ps1 -MakeDefault" -ForegroundColor Yellow
    Write-Host "  To also disable Intel 3168, run:" -ForegroundColor Yellow
    Write-Host "    .\wireless\set-ac1900-default.ps1 -MakeDefault -DisableIntel" -ForegroundColor Yellow
    exit 0
}

Write-Host "[AC1900-Default] Applying configuration..." -ForegroundColor Cyan

# 4. Ensure AC1900 adapter is enabled
try {
    $net = Get-NetAdapter -Name $acName -IncludeHidden -ErrorAction Stop
}
catch {
    Write-Error "[AC1900-Default] Failed to get adapter '$acName': $($_.Exception.Message)"
    exit 1
}

if ($net.Status -ne 'Up') {
    Write-Host "[AC1900-Default] Enabling adapter '$acName'..." -ForegroundColor Cyan
    Enable-NetAdapter -Name $acName -Confirm:$false
}
else {
    Write-Host "[AC1900-Default] Adapter '$acName' is already Up." -ForegroundColor Green
}

# 5. Set interface metric for AC1900 (prefer lower number)
try {
    $ipIf = Get-NetIPInterface -InterfaceAlias $acName -AddressFamily IPv4 -ErrorAction Stop
    $desiredMetric = 10
    if ($ipIf.InterfaceMetric -ne $desiredMetric) {
        Write-Host "[AC1900-Default] Setting interface metric for '$acName' to $desiredMetric..." -ForegroundColor Cyan
        Set-NetIPInterface -InterfaceAlias $acName -AddressFamily IPv4 -InterfaceMetric $desiredMetric
    }
    else {
        Write-Host "[AC1900-Default] '$acName' already has metric $desiredMetric." -ForegroundColor Green
    }
}
catch {
    Write-Warning "[AC1900-Default] Could not adjust interface metric: $($_.Exception.Message)"
}

# 6. Optionally disable Intel 3168
if ($DisableIntel -and $intel) {
    foreach ($ad in $intel) {
        Write-Host "[AC1900-Default] Disabling Intel adapter '$($ad.Name)'..." -ForegroundColor Yellow
        try {
            Disable-NetAdapter -Name $ad.Name -Confirm:$false
        }
        catch {
            Write-Warning "[AC1900-Default] Failed to disable '$($ad.Name)': $($_.Exception.Message)"
        }
    }
}

# 7. Summary
Write-Host ""
Write-Host "[AC1900-Default] Final adapter status:" -ForegroundColor Cyan
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress | Format-Table

Write-Host ""
Write-Host "[AC1900-Default] Completed." -ForegroundColor Green
Write-Host "  To revert Intel adapter, run:  Enable-NetAdapter -Name '<IntelName>' -Confirm:$false" -ForegroundColor Yellow
