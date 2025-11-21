<#
 GodBox Shortcut Pack Creator
 Creates 3 desktop shortcuts for:

 1. GodBox Admin – NetOps
 2. GodBox Admin – SYSTEM
 3. GodBox WSL – Kali (zsh)

 Requires GodBox profiles already installed.
#>

[CmdletBinding()]
param()

Write-Host "[GodBox] === Creating Desktop Shortcuts ==="

# ---------------------------------------------------------
# 1) Paths & GUIDs
# ---------------------------------------------------------
$Desktop = [Environment]::GetFolderPath("Desktop")
$WT = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"

if (-not (Test-Path $WT)) {
    throw "[GodBox] Windows Terminal (wt.exe) not found."
}

# GUIDs from installer script
$GUID_NetOps = "{77777777-1111-2222-3333-444444444444}"
$GUID_System = "{99999999-AAAA-BBBB-CCCC-DDDDDDDDDDDD}"
$GUID_Kali   = "{11111111-2222-3333-4444-555555555555}"

# ---------------------------------------------------------
# 2) Function to make shortcut
# ---------------------------------------------------------
function New-GodShortcut {
    param(
        [string]$Name,
        [string]$Args,
        [switch]$AsAdmin,
        [string]$Icon
    )

    $Path = Join-Path $Desktop "$Name.lnk"

    $WScript = New-Object -ComObject WScript.Shell
    $Shortcut = $WScript.CreateShortcut($Path)

    $Shortcut.TargetPath = $WT
    $Shortcut.Arguments  = $Args

    if ($Icon -and (Test-Path $Icon)) {
        $Shortcut.IconLocation = $Icon
    }

    $Shortcut.Save()

    # Enable "Run as administrator" if needed
    if ($AsAdmin) {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $bytes[21] = $bytes[21] -bor 0x20
        [System.IO.File]::WriteAllBytes($Path, $bytes)
    }

    Write-Host "[GodBox] Created shortcut: $Path"
}

# ---------------------------------------------------------
# 3) Create all shortcuts
# ---------------------------------------------------------

# Optional icons
$Icon_Admin  = "$PSScriptRoot\icons\admin.ico"
$Icon_System = "$PSScriptRoot\icons\system.ico"
$Icon_Kali   = "$PSScriptRoot\icons\kali.ico"

# Admin NetOps shell
New-GodShortcut `
    -Name "GodBox Admin – NetOps" `
    -Args "-p $GUID_NetOps" `
    -AsAdmin `
    -Icon $Icon_Admin

# SYSTEM shell
New-GodShortcut `
    -Name "GodBox Admin – SYSTEM" `
    -Args "-p $GUID_System" `
    -AsAdmin `
    -Icon $Icon_System

# Kali WSL shell
New-GodShortcut `
    -Name "GodBox WSL – Kali (zsh)" `
    -Args "-p $GUID_Kali" `
    -Icon $Icon_Kali

Write-Host "[GodBox] === Shortcut creation complete! ==="
