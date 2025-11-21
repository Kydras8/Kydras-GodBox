#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Create Desktop shortcuts for GodBox Windows Terminal profiles.

.DESCRIPTION
  - Creates shortcuts that call:
      wt.exe -p "GodBox Admin – System"
      wt.exe -p "GodBox Admin – NetOps"
      wt.exe -p "GodBox WSL – Kali (zsh)"
  - After creation, you can set each shortcut to "Run as administrator"
    via Properties > Advanced.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "[Create-DesktopShortcuts] Start" -ForegroundColor Cyan

# 1. Locate Desktop and Windows Terminal executable
$desktop = [Environment]::GetFolderPath('Desktop')
$wtExe   = 'wt.exe'  # relies on PATH

Write-Host "[Create-DesktopShortcuts] Desktop: $desktop"

if (-not (Get-Command $wtExe -ErrorAction SilentlyContinue)) {
    Write-Warning "[Create-DesktopShortcuts] Cannot find wt.exe on PATH."
    Write-Warning "  Make sure Windows Terminal is installed and its path is available."
    return
}

# 2. Helper to create a shortcut
function New-Shortcut {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Arguments
    )

    $shell = New-Object -ComObject WScript.Shell
    $lnkPath = Join-Path $desktop ($Name + '.lnk')
    $shortcut = $shell.CreateShortcut($lnkPath)
    $shortcut.TargetPath = $wtExe
    $shortcut.Arguments  = $Arguments
    $shortcut.WorkingDirectory = $desktop
    $shortcut.WindowStyle = 1  # normal
    $shortcut.IconLocation = "$wtExe,0"
    $shortcut.Save()

    Write-Host "[Create-DesktopShortcuts] Created shortcut: $lnkPath" -ForegroundColor Green
    Write-Host "  Arguments: $Arguments"
}

# 3. Create shortcuts for each profile

New-Shortcut -Name 'GodBox Admin - System' -Arguments '-p "GodBox Admin – System"'
New-Shortcut -Name 'GodBox Admin - NetOps' -Arguments '-p "GodBox Admin – NetOps"'
New-Shortcut -Name 'GodBox WSL - Kali (zsh)' -Arguments '-p "GodBox WSL – Kali (zsh)"'

Write-Host ""
Write-Host "[Create-DesktopShortcuts] Shortcuts created." -ForegroundColor Green
Write-Host "  OPTIONAL: Right-click each shortcut -> Properties -> Advanced -> check 'Run as administrator'." -ForegroundColor Yellow
Write-Host "[Create-DesktopShortcuts] End" -ForegroundColor Green
