<#
.Kydras-GodBox Auto SYSTEM & Terminal Profile Installer

This script:

1. Ensures K:\Kydras\Repos\Kydras-GodBox\windows\bin exists
2. Downloads PsTools (PsExec) from Microsoft if needed
3. Extracts PsExec64.exe into windows\bin
4. Creates a LaunchSystem.cmd wrapper for SYSTEM shells
5. Modifies Windows Terminal settings.json to ensure EXACTLY 3 profiles:

   - GodBox Admin – SYSTEM
   - GodBox Admin – NetOps
   - GodBox WSL – Kali (zsh)

Idempotent: you can run this as many times as you want.
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = "K:\Kydras\Repos\Kydras-GodBox"
)

$ErrorActionPreference = "Stop"

Write-Host "[GodBox] === Auto SYSTEM & Terminal Installer ==="

# -------------------------------------------------------------
# 1) Paths
# -------------------------------------------------------------
$Bin         = Join-Path $RepoRoot "windows\bin"
$PsToolsZip  = Join-Path $Bin "PsTools.zip"
$PsExec      = Join-Path $Bin "PsExec64.exe"
$SystemBat   = Join-Path $Bin "LaunchSystem.cmd"
$WTDir       = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$SettingsJsonPath = Join-Path $WTDir "settings.json"

# -------------------------------------------------------------
# 2) Ensure bin exists
# -------------------------------------------------------------
if (-not (Test-Path $Bin)) {
    Write-Host "[GodBox] Creating bin directory at $Bin"
    New-Item -ItemType Directory -Path $Bin -Force | Out-Null
} else {
    Write-Host "[GodBox] Bin directory exists: $Bin"
}

# -------------------------------------------------------------
# 3) Get PsExec64.exe (download + extract if missing)
# -------------------------------------------------------------
if (-not (Test-Path $PsExec)) {
    Write-Host "[GodBox] PsExec64.exe missing — downloading from Microsoft..."

    $Url = "https://download.sysinternals.com/files/PSTools.zip"
    Write-Host "[GodBox] Downloading PsTools.zip from $Url"
    Invoke-WebRequest -Uri $Url -OutFile $PsToolsZip -UseBasicParsing

    Write-Host "[GodBox] Extracting PsTools.zip into $Bin ..."
    Expand-Archive -Path $PsToolsZip -DestinationPath $Bin -Force

    # Search for PsExec64.exe in the extracted contents
    $nested = Get-ChildItem -Path $Bin -Recurse -Filter "PsExec64.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($nested -and -not (Test-Path $PsExec)) {
        Copy-Item $nested.FullName $PsExec -Force
    }

    if (-not (Test-Path $PsExec)) {
        throw "[GodBox] ERROR — PsExec64.exe could not be found after extraction."
    }

    Write-Host "[GodBox] PsExec64.exe installed successfully at $PsExec"
} else {
    Write-Host "[GodBox] PsExec64.exe already present at $PsExec"
}

# -------------------------------------------------------------
# 4) Build SYSTEM launcher (LaunchSystem.cmd)
# -------------------------------------------------------------
Write-Host "[GodBox] Creating SYSTEM launcher at $SystemBat ..."

# Escape backslashes for cmd
$PsExecEscaped = $PsExec.Replace("\", "\\")

@"
@echo off
"$PsExecEscaped" -accepteula -i -s pwsh.exe
"@ | Out-File -FilePath $SystemBat -Encoding ASCII -Force

Write-Host "[GodBox] SYSTEM launcher created."

# -------------------------------------------------------------
# 5) Load Windows Terminal settings.json
# -------------------------------------------------------------
if (-not (Test-Path $SettingsJsonPath)) {
    throw "[GodBox] ERROR — Windows Terminal settings.json not found at $SettingsJsonPath. Open Windows Terminal once, then re-run this script."
}

Write-Host "[GodBox] Loading Windows Terminal settings from $SettingsJsonPath ..."
$Settings = Get-Content $SettingsJsonPath -Raw | ConvertFrom-Json

if (-not $Settings.profiles) {
    $Settings | Add-Member -NotePropertyName "profiles" -NotePropertyValue (@{ list = @(); defaults = @{} })
}
if (-not $Settings.profiles.list) {
    $Settings.profiles | Add-Member -NotePropertyName "list" -NotePropertyValue @()
}

# -------------------------------------------------------------
# 6) Helper: Ensure-Profile (safe property merge)
# -------------------------------------------------------------
function Ensure-Profile {
    param(
        [Parameter(Mandatory=$true)][string]$Guid,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][hashtable]$Props
    )

    # Get first existing profile with this GUID
    $existing = $Settings.profiles.list | Where-Object { $_.guid -eq $Guid } | Select-Object -First 1

    if ($existing) {
        Write-Host "[GodBox] Updating existing profile: $Name"
        foreach ($k in $Props.Keys) {
            $prop = $existing.PSObject.Properties[$k]
            if ($prop) {
                $existing.$k = $Props[$k]
            } else {
                $existing | Add-Member -NotePropertyName $k -NotePropertyValue $Props[$k]
            }
        }
    }
    else {
        Write-Host "[GodBox] Adding new profile: $Name"
        $p = New-Object PSObject
        $p | Add-Member -NotePropertyName "guid" -NotePropertyValue $Guid
        $p | Add-Member -NotePropertyName "name" -NotePropertyValue $Name

        foreach ($k in $Props.Keys) {
            $p | Add-Member -NotePropertyName $k -NotePropertyValue $Props[$k]
        }

        $Settings.profiles.list += $p
    }
}

# -------------------------------------------------------------
# 7) GUIDs & cleanup of duplicates by name
# -------------------------------------------------------------
$GUID_System = "{99999999-AAAA-BBBB-CCCC-DDDDDDDDDDDD}"
$GUID_NetOps = "{77777777-1111-2222-3333-444444444444}"
$GUID_Kali   = "{11111111-2222-3333-4444-555555555555}"

# Remove any older duplicates with same names but wrong GUIDs
$Settings.profiles.list = $Settings.profiles.list | Where-Object {
    if ($_.name -eq "GodBox Admin – SYSTEM" -and $_.guid -ne $GUID_System) { return $false }
    if ($_.name -eq "GodBox Admin – NetOps" -and $_.guid -ne $GUID_NetOps) { return $false }
    if ($_.name -eq "GodBox WSL – Kali (zsh)" -and $_.guid -ne $GUID_Kali) { return $false }
    return $true
}

$GodDir = $RepoRoot

# -------------------------------------------------------------
# 8) Ensure the 3 GodBox profiles
# -------------------------------------------------------------
# SYSTEM profile
Ensure-Profile -Guid $GUID_System -Name "GodBox Admin – SYSTEM" -Props @{
    commandline       = $SystemBat
    startingDirectory = $GodDir
    font              = @{ face = "JetBrainsMono Nerd Font"; size = 11 }
    hidden            = $false
    tabTitle          = "SYSTEM"
    colorScheme       = "Campbell"
}

# Admin / NetOps profile
Ensure-Profile -Guid $GUID_NetOps -Name "GodBox Admin – NetOps" -Props @{
    commandline       = "pwsh.exe"
    startingDirectory = $GodDir
    font              = @{ face = "JetBrainsMono Nerd Font"; size = 11 }
    hidden            = $false
    tabTitle          = "NetOps"
    colorScheme       = "Campbell"
}

# Kali WSL profile
Ensure-Profile -Guid $GUID_Kali -Name "GodBox WSL – Kali (zsh)" -Props @{
    commandline       = "wsl.exe -d kali-linux -e zsh -l"
    startingDirectory = $GodDir
    font              = @{ face = "JetBrainsMono Nerd Font"; size = 11 }
    hidden            = $false
    tabTitle          = "Kali (zsh)"
    colorScheme       = "Campbell"
}

# Optional: set default profile to NetOps (you can change if you want)
$Settings.defaultProfile = $GUID_NetOps

# -------------------------------------------------------------
# 9) Save updated settings.json
# -------------------------------------------------------------
Write-Host "[GodBox] Writing updated settings.json ..."
$Settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsJsonPath -Encoding UTF8

Write-Host "[GodBox] === Profiles installed & cleaned! ===" -ForegroundColor Green
Write-Host "Open Windows Terminal → ▼ and you should see exactly:"
Write-Host " - GodBox Admin – SYSTEM"
Write-Host " - GodBox Admin – NetOps"
Write-Host " - GodBox WSL – Kali (zsh)"
