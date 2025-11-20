#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Build a distributable ZIP of the Kydras-GodBox project.

.DESCRIPTION
  - Collects key folders/files
  - Writes ZIP to K:\Kydras\Builds by default (to avoid filling C:)
#>

[CmdletBinding()]
param(
    [string]$OutputDir = "K:\Kydras\Builds"
)

$ErrorActionPreference = 'Stop'

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    Write-Host "[Kydras-GodBox] Creating output directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ZipName = "Kydras-GodBox-$Timestamp.zip"
$ZipPath = Join-Path $OutputDir $ZipName

Write-Host "[Kydras-GodBox] Building ZIP: $ZipPath" -ForegroundColor Cyan

if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

$itemsToInclude = @(
    'README.md',
    'windows',
    'wsl',
    'kali',
    'wireless',
    'packaging',
    'docs'
)

$fullPaths = @()
foreach ($item in $itemsToInclude) {
    $path = Join-Path $RepoRoot $item
    if (Test-Path $path) {
        $fullPaths += $path
    }
    else {
        Write-Warning "[Kydras-GodBox] Missing item (skipped): $path"
    }
}

if (-not $fullPaths) {
    Write-Error "[Kydras-GodBox] No items found to include in ZIP."
    exit 1
}

Compress-Archive -Path $fullPaths -DestinationPath $ZipPath -Force

Write-Host "[Kydras-GodBox] ZIP build complete." -ForegroundColor Green
Write-Host "Output: $ZipPath"
