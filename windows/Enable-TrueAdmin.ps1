#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Enable "True Admin" experience for Kydras-GodBox.

.DESCRIPTION
  - Backs up existing Windows Terminal settings.json
  - Injects GodBox admin + WSL profiles
  - Creates Desktop shortcuts to launch those profiles

  NOTE:
    - Elevation is controlled by running Windows Terminal as Administrator.
    - After shortcuts are created, you can set them to "Run as administrator"
      via the shortcut properties (one-time manual step).
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "[Kydras-GodBox] [Enable-TrueAdmin] Start" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

Write-Host "[Enable-TrueAdmin] ScriptDir: $ScriptDir"
Write-Host "[Enable-TrueAdmin] RepoRoot : $RepoRoot"

# 1. Locate helpers
$CreateTerminals = Join-Path $ScriptDir 'Create-Admin-Terminals.ps1'
$CreateShortcuts = Join-Path $ScriptDir 'Create-DesktopShortcuts.ps1'

if (-not (Test-Path $CreateTerminals)) {
    Write-Warning "[Enable-TrueAdmin] Create-Admin-Terminals.ps1 not found at: $CreateTerminals"
} else {
    Write-Host "[Enable-TrueAdmin] Running Create-Admin-Terminals.ps1 ..." -ForegroundColor Cyan
    try {
        & $CreateTerminals -RepoRoot $RepoRoot
    } catch {
        Write-Warning "[Enable-TrueAdmin] Create-Admin-Terminals.ps1 failed: $($_.Exception.Message)"
    }
}

if (-not (Test-Path $CreateShortcuts)) {
    Write-Warning "[Enable-TrueAdmin] Create-DesktopShortcuts.ps1 not found at: $CreateShortcuts"
} else {
    Write-Host "[Enable-TrueAdmin] Running Create-DesktopShortcuts.ps1 ..." -ForegroundColor Cyan
    try {
        & $CreateShortcuts
    } catch {
        Write-Warning "[Enable-TrueAdmin] Create-DesktopShortcuts.ps1 failed: $($_.Exception.Message)"
    }
}

Write-Host "[Kydras-GodBox] [Enable-TrueAdmin] End" -ForegroundColor Green
