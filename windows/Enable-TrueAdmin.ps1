#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Phase 1: Skeleton for creating 3 fully elevated terminals.

.DESCRIPTION
  Right now this script just:
  - Verifies Admin
  - Logs what it would do
  Later, we will:
  - Create Windows Terminal profiles
  - Create desktop shortcuts for 3x full-admin shells
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "[Kydras-GodBox] [Enable-TrueAdmin] Start" -ForegroundColor Cyan

# Admin check (defensive, even though Install-GodBox already checked)
$principal = New-Object Security.Principal.WindowsPrincipal (
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "[Enable-TrueAdmin] Must be run as Administrator."
    exit 1
}

# For now, just log intentions
Write-Host "[Enable-TrueAdmin] Phase 1: No changes made." -ForegroundColor Yellow
Write-Host "[Enable-TrueAdmin] In future phases, this will:" -ForegroundColor Yellow
Write-Host "  - Create 3 Windows Terminal profiles for full Admin shells" -ForegroundColor Yellow
Write-Host "  - Optionally create desktop shortcuts launching those profiles" -ForegroundColor Yellow

Write-Host "[Kydras-GodBox] [Enable-TrueAdmin] End" -ForegroundColor Green
