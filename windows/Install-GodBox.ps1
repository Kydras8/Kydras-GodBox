#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Top-level installer for Kydras-GodBox on Windows.

.DESCRIPTION
  Phase 1: skeleton only (no destructive actions).
  - Verifies Administrator
  - Locates repo root
  - Invokes sub-scripts:
      * Enable-TrueAdmin.ps1
      * Configure-DevStack.ps1
      * Configure-AC1900.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "[Kydras-GodBox] === Windows Install Start (Phase 1 Skeleton) ===" -ForegroundColor Cyan

# 1. Admin check
$principal = New-Object Security.Principal.WindowsPrincipal (
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "[Kydras-GodBox] This script must be run as Administrator. Right-click PowerShell and choose 'Run as administrator'."
    exit 1
}

# 2. Locate script + repo root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

Write-Host "[Kydras-GodBox] ScriptDir: $ScriptDir"
Write-Host "[Kydras-GodBox] RepoRoot : $RepoRoot"

# 3. Identify sub-scripts
$EnableTrueAdmin = Join-Path $ScriptDir 'Enable-TrueAdmin.ps1'
$ConfigureDev    = Join-Path $ScriptDir 'Configure-DevStack.ps1'
$ConfigureAC1900 = Join-Path $ScriptDir 'Configure-AC1900.ps1'

$subs = @(
    @{ Name = 'Enable-TrueAdmin'; Path = $EnableTrueAdmin },
    @{ Name = 'Configure-DevStack'; Path = $ConfigureDev },
    @{ Name = 'Configure-AC1900'; Path = $ConfigureAC1900 }
)

foreach ($sub in $subs) {
    $name = $sub.Name
    $path = $sub.Path

    if (Test-Path $path) {
        Write-Host "[Kydras-GodBox] >>> Running $name ..."
        try {
            & $path
            Write-Host "[Kydras-GodBox] <<< $name completed." -ForegroundColor Green
        }
        catch {
            Write-Warning "[Kydras-GodBox] $name failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "[Kydras-GodBox] Missing sub-script: $path"
    }
}

Write-Host "[Kydras-GodBox] === Windows Install Complete (Phase 1 Skeleton) ===" -ForegroundColor Cyan
