<#
.Kydras-GodBox: Create 3 elevated Windows Terminal profiles
- GodBox Admin – NetOps (Admin)
- GodBox Admin – SYSTEM (using PsExec)
- GodBox WSL – Kali (zsh)
#>

[CmdletBinding()]
param()

Write-Host "[GodBox] === Creating Windows Terminal Profiles (Admin/System/WSL) ==="

# -------------------------------------------------------------
# 0. Pre-flight checks
# -------------------------------------------------------------
$WTSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (-not (Test-Path $WTSettings)) {
    Write-Host "[GodBox] ERROR: Windows Terminal settings.json not found."
    exit 1
}

$SettingsJson = Get-Content $WTSettings -Raw | ConvertFrom-Json

if (-not $SettingsJson.profiles.list) {
    Write-Host "[GodBox] ERROR: settings.json missing profiles.list"
    exit 1
}

# Directories for scripts Windows Terminal will launch
$ToolsDir = "$env:ProgramData\GodBox"
$SystemHelper = Join-Path $ToolsDir "LaunchSystem.cmd"

if (-not (Test-Path $ToolsDir)) {
    New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
}

# -------------------------------------------------------------
# 1. Create SYSTEM launcher script using PsExec (bundled)
# -------------------------------------------------------------
$psexec = "$PSScriptRoot\bin\PsExec64.exe"

if (-not (Test-Path $psexec)) {
    Write-Host "[GodBox] ERROR: PsExec64.exe not found at $psexec"
    Write-Host "Place PsExec64.exe in: $PSScriptRoot\bin"
    exit 1
}

$SystemCmd = @"
@echo off
"$psexec" -accepteula -s -i powershell.exe -NoLogo -NoExit
"@
Set-Content -Path $SystemHelper -Value $SystemCmd -Force -Encoding ASCII

Write-Host "[GodBox] SYSTEM launcher created: $SystemHelper"


# -------------------------------------------------------------
# 2. Functions to create profile blocks
# -------------------------------------------------------------
function New-GodBoxProfileJson {
    param(
        [string]$guid,
        [string]$name,
        [string]$command
    )

    return [pscustomobject]@{
        guid   = $guid
        name   = $name
        commandline = $command
        hidden = $false
        startingDirectory = null
        icon = null
    }
}

# -------------------------------------------------------------
# 3. Define 3 profile GUIDs
# -------------------------------------------------------------
$GUID_AdminNetOps = "{B0000001-0000-4000-9000-ADMINNETOPS0001}"
$GUID_AdminSystem = "{B0000002-0000-4000-9000-ADMINSYSTEM0001}"
$GUID_KaliWSL     = "{B0000003-0000-4000-9000-KALIWSL000001}"

# Remove old duplicates
$SettingsJson.profiles.list = $SettingsJson.profiles.list |
    Where-Object { $_.guid -notin @(
        $GUID_AdminNetOps,
        $GUID_AdminSystem,
        $GUID_KaliWSL
    ) }

# -------------------------------------------------------------
# 4. Create new profile objects
# -------------------------------------------------------------
$Profile_AdminNetOps = New-GodBoxProfileJson `
    -guid $GUID_AdminNetOps `
    -name "GodBox Admin – NetOps" `
    -command "powershell.exe -NoLogo -NoExit"

$Profile_AdminSystem = New-GodBoxProfileJson `
    -guid $GUID_AdminSystem `
    -name "GodBox Admin – SYSTEM" `
    -command "$SystemHelper"

$Profile_KaliWSL = New-GodBoxProfileJson `
    -guid $GUID_KaliWSL `
    -name "GodBox WSL – Kali (zsh)" `
    -command "wsl.exe -d kali-linux -e zsh -l"

# -------------------------------------------------------------
# 5. Add profiles to settings.json
# -------------------------------------------------------------
$SettingsJson.profiles.list += $Profile_AdminNetOps
$SettingsJson.profiles.list += $Profile_AdminSystem
$SettingsJson.profiles.list += $Profile_KaliWSL

# -------------------------------------------------------------
# 6. Write back the file
# -------------------------------------------------------------
($SettingsJson | ConvertTo-Json -Depth 50) |
    Set-Content -Path $WTSettings -Encoding utf8 -Force

Write-Host "[GodBox] Windows Terminal profiles created successfully!"
Write-Host "[GodBox] === Done ==="
