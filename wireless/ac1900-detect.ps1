#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Detect the Wavelink AC1900 (Realtek 8814AU) adapter and show details.

.DESCRIPTION
  - Matches on USB VID_0BDA & PID_8813 (Realtek 8814AU chipset)
  - Tries to correlate with a NetAdapter (interface)
  - Phase 1: detection + logging only (no changes to system)
#>

[CmdletBinding()]
param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

$TargetVid = '0BDA'
$TargetPid = '8813'

Write-Host "[AC1900-Detect] Looking for USB\VID_$TargetVid&PID_$TargetPid ..." -ForegroundColor Cyan

# 1. Find the PnP device(s) that match the Realtek 8814AU NIC
$pnps = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object {
        $_.InstanceId -like "USB\VID_${TargetVid}&PID_${TargetPid}*"
    }

if (-not $pnps) {
    Write-Warning "[AC1900-Detect] No matching PnP device found for VID_$TargetVid PID_$TargetPid."
    return
}

Write-Host "[AC1900-Detect] Found candidate PnP device(s):" -ForegroundColor Green
$pnps | Select-Object Status, Class, InstanceId, Name | Format-Table

# 2. Try to correlate with NetAdapter objects
$netAdapters = Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue

if (-not $netAdapters) {
    Write-Warning "[AC1900-Detect] Unable to query NetAdapter list."
}

$candidates = @()

foreach ($p in $pnps) {
    # Heuristics: Realtek 8814AU NIC usually has this description
    $matches = $netAdapters | Where-Object {
        $_.InterfaceDescription -like '*8814AU*' -or
        $_.InterfaceDescription -like '*Realtek 8814AU*' -or
        $_.Name -like '*Wi-Fi*' -or
        $_.Name -like '*Wireless*'
    }

    foreach ($na in $matches) {
        $obj = [pscustomobject]@{
            PnpInstanceId        = $p.InstanceId
            PnpName              = $p.Name
            PnpStatus            = $p.Status
            NetName              = $na.Name
            InterfaceDescription = $na.InterfaceDescription
            NetStatus            = $na.Status
            MacAddress           = $na.MacAddress
            LinkSpeed            = $na.LinkSpeed
        }
        $candidates += $obj
    }
}

if (-not $candidates) {
    Write-Warning "[AC1900-Detect] PnP device found, but no obvious matching NetAdapter yet."
    Write-Host "Try running: Get-NetAdapter | Select Name, InterfaceDescription, Status" -ForegroundColor Yellow
    return
}

if ($Json) {
    $candidates | ConvertTo-Json -Depth 4
}
else {
    Write-Host "[AC1900-Detect] Matched adapter(s):" -ForegroundColor Green
    $candidates | Format-List *
}
