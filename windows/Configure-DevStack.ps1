#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Phase 1: Dev stack configuration skeleton.

.DESCRIPTION
  Right now this script simply:
  - Logs system info
  - Logs where it *would* install tools (Node, Python, etc.)
  It does NOT install anything yet.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "[Kydras-GodBox] [Configure-DevStack] Start" -ForegroundColor Cyan

$osInfo = Get-CimInstance Win32_OperatingSystem
Write-Host "[Configure-DevStack] OS: $($osInfo.Caption) ($($osInfo.Version))"

Write-Host "[Configure-DevStack] Phase 1: no installations performed." -ForegroundColor Yellow
Write-Host "[Configure-DevStack] Later phases will:" -ForegroundColor Yellow
Write-Host "  - Ensure Git, Node, Python, etc. are installed" -ForegroundColor Yellow
Write-Host "  - Prefer installation paths on K: or D: where feasible" -ForegroundColor Yellow
Write-Host "  - Adjust PATH environment variables safely" -ForegroundColor Yellow

Write-Host "[Kydras-GodBox] [Configure-DevStack] End" -ForegroundColor Green
