#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Phase 1: Wavelink AC1900 detection + logging.

.DESCRIPTION
  This script:
  - Enumerates network adapters
  - Tries to spot anything that looks like Wavelink/AC1900
  - Logs status only (no network changes yet)
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "[Kydras-GodBox] [Configure-AC1900] Start" -ForegroundColor Cyan

# Basic adapter inventory
try {
    $adapters = Get-NetAdapter -Physical -ErrorAction Stop
}
catch {
    Write-Warning "[Configure-AC1900] Unable to query adapters: $($_.Exception.Message)"
    $adapters = @()
}

if (-not $adapters) {
    Write-Warning "[Configure-AC1900] No physical adapters found or access denied."
}
else {
    Write-Host "[Configure-AC1900] Found adapters:" -ForegroundColor Cyan
    $adapters | Select-Object Name, InterfaceDescription, Status, MacAddress | Format-Table
}

# Very rough detection placeholder (we'll tighten this later with real HW IDs)
$possibleAc1900 = $adapters | Where-Object {
    $_.InterfaceDescription -match 'Wavlink|AC1900'
}

if ($possibleAc1900) {
    Write-Host "[Configure-AC1900] Candidate AC1900 adapter(s):" -ForegroundColor Green
    $possibleAc1900 | Select-Object Name, InterfaceDescription, Status | Format-Table
}
else {
    Write-Host "[Configure-AC1900] No obvious AC1900 candidate detected yet." -ForegroundColor Yellow
}

Write-Host "[Configure-AC1900] Phase 1: detection-only. No changes applied." -ForegroundColor Yellow
Write-Host "[Kydras-GodBox] [Configure-AC1900] End" -ForegroundColor Green
