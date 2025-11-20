#!/usr/bin/env pwsh
<#
.SYNOPSIS
  AC1900 (Realtek 8814AU) detection + status.

.DESCRIPTION
  Phase 2:
  - Calls wireless\ac1900-detect.ps1
  - Shows PnP + NetAdapter status for the Wavelink AC1900
  - No changes to adapter priority or config yet (safe).
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "[Kydras-GodBox] [Configure-AC1900] Start" -ForegroundColor Cyan

# 1. Sanity: ensure we're running as admin (not strictly required for read-only, but good habit)
$principal = New-Object Security.Principal.WindowsPrincipal (
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[Configure-AC1900] Recommended: run this from an elevated PowerShell (Run as administrator)."
}

# 2. Locate repo root and wireless script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$WirelessDir = Join-Path $RepoRoot 'wireless'
$DetectScript = Join-Path $WirelessDir 'ac1900-detect.ps1'

Write-Host "[Configure-AC1900] ScriptDir : $ScriptDir"
Write-Host "[Configure-AC1900] RepoRoot  : $RepoRoot"
Write-Host "[Configure-AC1900] Wireless  : $WirelessDir"

if (-not (Test-Path $DetectScript)) {
    Write-Warning "[Configure-AC1900] Detection script not found: $DetectScript"
    Write-Warning "[Configure-AC1900] Make sure wireless\\ac1900-detect.ps1 exists."
    return
}

Write-Host "[Configure-AC1900] Running ac1900-detect.ps1 ..." -ForegroundColor Cyan

try {
    & $DetectScript
}
catch {
    Write-Warning "[Configure-AC1900] Detection failed: $($_.Exception.Message)"
}

Write-Host "[Configure-AC1900] Phase 2: detection-only (no config changes applied)." -ForegroundColor Yellow
Write-Host "[Kydras-GodBox] [Configure-AC1900] End" -ForegroundColor Green
