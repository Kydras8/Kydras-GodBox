<#
Fix-CLIPath.ps1
Ensures the WinGet "Links" folder and Kydras SDKs are in the user PATH.
Safe + idempotent; you can run this as many times as you want.
#>

$ErrorActionPreference = "Stop"

Write-Host "[GodBox-CLIPath] === Fixing CLI PATH ==="

# Determine paths
$Links = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
$SdkRoot = "K:\Kydras\SDKs"

Write-Host "[GodBox-CLIPath] WinGet Links: $Links"
Write-Host "[GodBox-CLIPath] SDK Root     : $SdkRoot"

# Ensure SDK root exists (does nothing if already there)
if (-not (Test-Path $SdkRoot)) {
    New-Item -ItemType Directory -Path $SdkRoot -Force | Out-Null
}

# Helper: add a directory to user PATH if missing
function Add-UserPathIfMissing {
    param(
        [Parameter(Mandatory=$true)][string]$Dir
    )

    if (-not (Test-Path $Dir)) {
        Write-Host "[GodBox-CLIPath] Skipping '$Dir' (directory does not exist)."
        return
    }

    $current = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ([string]::IsNullOrWhiteSpace($current)) {
        $current = ""
    }

    if ($current -like "*$Dir*") {
        Write-Host "[GodBox-CLIPath] '$Dir' already in user PATH."
    } else {
        $newPath = if ($current.Length -gt 0) { "$current;$Dir" } else { $Dir }
        [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "[GodBox-CLIPath] Added '$Dir' to user PATH."
    }
}

# Add WinGet portable Links folder (where jq, fzf, rg, etc can land)
Add-UserPathIfMissing -Dir $Links

# Also ensure SDK root is in PATH (for zoxide / future portable tools)
Add-UserPathIfMissing -Dir $SdkRoot

Write-Host "[GodBox-CLIPath] Done. You may need to open a NEW terminal window for PATH changes to apply."
