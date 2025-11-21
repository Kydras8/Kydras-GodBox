<#
Kydras GodBox – Portable install for ripgrep (rg) and jq on Windows

This script:
  - Creates K:\Kydras\SDKs\bin
  - Downloads ripgrep (rg) Windows build and extracts rg.exe to that bin
  - Downloads jq-win64.exe and saves it as jq.exe in that bin
  - Ensures K:\Kydras\SDKs\bin is in the USER PATH

Safe & idempotent:
  - You can re-run it any time; it will just overwrite the same files.
#>

param(
    [string]$RepoRoot = "K:\Kydras\Repos\Kydras-GodBox"
)

$ErrorActionPreference = "Stop"

Write-Host "[GodBox-RgJq] === Portable ripgrep + jq installer ==="

# -----------------------------------------------------------------------------
# Paths & logging
# -----------------------------------------------------------------------------
$LogDir = Join-Path $RepoRoot "logs\devstack"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$Log = Join-Path $LogDir ("rgjq-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

function Log {
    param([string]$Message)
    $Message | Tee-Object -FilePath $Log -Append
}

Log "=== Rg/Jq portable install run: $(Get-Date) ==="

$SdkRoot = "K:\Kydras\SDKs"
$BinDir  = Join-Path $SdkRoot "bin"

New-Item -ItemType Directory -Path $SdkRoot -Force | Out-Null
New-Item -ItemType Directory -Path $BinDir  -Force | Out-Null

Log "[PATH] SdkRoot: $SdkRoot"
Log "[PATH] BinDir : $BinDir"

# -----------------------------------------------------------------------------
# Helper: download with basic logging
# -----------------------------------------------------------------------------
function Download-File {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Log "[DL] Downloading: $Url"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        Log "[DL] Saved to: $Destination"
    }
    catch {
        Log "[ERROR] Failed to download from $Url. Exception: $($_.Exception.Message)"
        throw
    }
}

# -----------------------------------------------------------------------------
# 1) Install ripgrep (rg) portable
# -----------------------------------------------------------------------------
# Version pinned to a known stable build
$RgVersion = "14.1.0"
$RgFile    = "ripgrep-$RgVersion-x86_64-pc-windows-msvc.zip"
$RgUrl     = "https://github.com/BurntSushi/ripgrep/releases/download/$RgVersion/$RgFile"
$RgZip     = Join-Path $BinDir "ripgrep.zip"
$RgTmp     = Join-Path $BinDir "rg-tmp"

Log "[STEP] Installing ripgrep (rg) portable"
Log "[Rg] URL   : $RgUrl"

if (Test-Path $RgTmp) {
    Remove-Item -Path $RgTmp -Recurse -Force
}
New-Item -ItemType Directory -Path $RgTmp -Force | Out-Null

Download-File -Url $RgUrl -Destination $RgZip

try {
    Expand-Archive -Path $RgZip -DestinationPath $RgTmp -Force
    Log "[Rg] Extracted ripgrep archive."
}
catch {
    Log "[ERROR] Failed to expand ripgrep archive: $($_.Exception.Message)"
    throw
}

$RgExeSrc = Get-ChildItem -Path $RgTmp -Recurse -Filter "rg.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $RgExeSrc) {
    Log "[ERROR] rg.exe not found inside extracted ripgrep archive."
    throw "rg.exe not found in ripgrep package."
}

$RgExeDst = Join-Path $BinDir "rg.exe"
Copy-Item -Path $RgExeSrc.FullName -Destination $RgExeDst -Force
Log "[Rg] Deployed rg.exe to $RgExeDst"

Remove-Item -Path $RgTmp -Recurse -Force
Remove-Item -Path $RgZip -Force

# -----------------------------------------------------------------------------
# 2) Install jq portable
# -----------------------------------------------------------------------------
$JqVersion = "jq-1.7.1"
$JqUrl     = "https://github.com/jqlang/jq/releases/download/$JqVersion/jq-win64.exe"
$JqExeDst  = Join-Path $BinDir "jq.exe"

Log "[STEP] Installing jq portable"
Log "[jq] URL   : $JqUrl"

Download-File -Url $JqUrl -Destination $JqExeDst

Log "[jq] Deployed jq.exe to $JqExeDst"

# -----------------------------------------------------------------------------
# 3) Ensure BinDir is in USER PATH
# -----------------------------------------------------------------------------
$UserPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ([string]::IsNullOrWhiteSpace($UserPath)) {
    $UserPath = ""
}

if ($UserPath -like "*$BinDir*") {
    Log "[ENV] BinDir already present in user PATH."
} else {
    $NewPath = if ($UserPath.Length -gt 0) { "$UserPath;$BinDir" } else { $BinDir }
    [System.Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    Log "[ENV] Added BinDir to user PATH: $BinDir"
}

Log "=== Rg/Jq portable install completed successfully ==="
Write-Host "[GodBox-RgJq] Portable ripgrep + jq installed to $BinDir" -ForegroundColor Green
Write-Host "[GodBox-RgJq] Open a NEW terminal window and run: rg --version, jq --version" -ForegroundColor Yellow
