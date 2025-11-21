#!/usr/bin/env pwsh
<#
  AC1900 (Realtek 8814AU) detector
  - When -Json is used, ONLY JSON is output (no header text)
  - When not using -Json, prints nice human output
#>

[CmdletBinding()]
param(
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$TargetVid = "0BDA"
$TargetPid = "8813"

# Gather PnP matches
$pnps = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object {
        $_.InstanceId -like "USB\VID_${TargetVid}&PID_${TargetPid}*"
    }

if (-not $pnps) {
    if ($Json) {
        # Return empty JSON array
        "[]" | Write-Output
        exit 0
    }
    Write-Warning "[AC1900-Detect] No matching Realtek 8814AU PnP devices found."
    exit 0
}

# Gather NetAdapter list
$net = Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue

# Build result objects
$result = foreach ($p in $pnps) {
    foreach ($na in $net) {
        if ($na.InterfaceDescription -like "*8814AU*" -or
            $na.InterfaceDescription -like "*Realtek 8814AU*" -or
            $na.Name -in @("Wi-Fi","Wi-Fi 2","Wireless")) {

            [pscustomobject]@{
                PnpInstanceId        = $p.InstanceId
                PnpName              = $p.Name
                PnpStatus            = $p.Status
                NetName              = $na.Name
                InterfaceDescription = $na.InterfaceDescription
                NetStatus            = $na.Status
                MacAddress           = $na.MacAddress
                LinkSpeed            = $na.LinkSpeed
            }
        }
    }
}

# If JSON requested → ONLY return JSON, no other text
if ($Json) {
    $result | ConvertTo-Json -Depth 4
    exit 0
}

# Otherwise, human-readable output
Write-Host "[AC1900-Detect] Matched adapter(s):" -ForegroundColor Green
$result | Format-List *
