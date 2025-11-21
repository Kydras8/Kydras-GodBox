<#
.Kydras-GodBox Dev Stack Installer (Windows)

Phase A: Core tools for the GodBox Admin / SYSTEM shells.

Tools managed:
  - Git (git)
  - GitHub CLI (gh)
  - Python 3 (python)
  - Node.js LTS (node, npm)
  - Visual Studio Code (code)

Behavior:
  - Default: scan-only (no installs) -> shows what you have and what's missing.
  - With -Apply: uses winget to install/upgrade missing tools IF winget is available.

Safe + idempotent: you can run this as many times as you like.

Usage:
  K:
  cd K:\Kydras\Repos\Kydras-GodBox\windows
  pwsh -File .\Install-DevStack.ps1          # scan only
  pwsh -File .\Install-DevStack.ps1 -Apply   # install/upgrade (requires winget)
#>

[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$RepoRoot = "K:\Kydras\Repos\Kydras-GodBox"
)

$ErrorActionPreference = "Stop"

Write-Host "[GodBox-Dev] === Dev Stack Check ==="
Write-Host "[GodBox-Dev] RepoRoot: $RepoRoot"
Write-Host "[GodBox-Dev] Mode    : " -NoNewline
if ($Apply) { Write-Host "APPLY (will install/upgrade where needed)" -ForegroundColor Yellow }
else        { Write-Host "SCAN-ONLY (no changes made)" -ForegroundColor Cyan }

# -----------------------------------------------------------------------------
# 0) Paths & logging
# -----------------------------------------------------------------------------
$LogDir = Join-Path $RepoRoot "logs\devstack"
$null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue
$LogPath = Join-Path $LogDir ("devstack-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

Write-Host "[GodBox-Dev] Log file: $LogPath"
"=== DevStack run: $(Get-Date) ===" | Out-File -FilePath $LogPath -Encoding UTF8

function Log {
    param([string]$Message)
    $Message | Tee-Object -FilePath $LogPath -Append
}

# -----------------------------------------------------------------------------
# 1) Helper: Require-Admin (we want elevated for installs)
# -----------------------------------------------------------------------------
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Log "[WARN] This script is not running as Administrator."
    Log "       Scans are fine; installs (winget) may fail."
} else {
    Log "[OK] Running as Administrator."
}

# -----------------------------------------------------------------------------
# 2) Helper: winget availability
# -----------------------------------------------------------------------------
function Test-Winget {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

$HasWinget = Test-Winget
if (-not $HasWinget) {
    Log "[WARN] winget not found in PATH."
    if ($Apply) {
        Write-Host "[GodBox-Dev] winget is not available, so installs cannot run." -ForegroundColor Yellow
        Write-Host "[GodBox-Dev] Tip: Install 'App Installer' from Microsoft Store, then re-run with -Apply."
        Log "[WARN] APPLY requested but winget is missing. Exiting before install."
        return
    }
}

# -----------------------------------------------------------------------------
# 3) Helper: check a tool
# -----------------------------------------------------------------------------
function Get-ToolInfo {
    param(
        [string]$Command,
        [string]$VersionArgs = "--version"
    )

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }

    $version = $null
    try {
        $version = & $Command $VersionArgs 2>$null | Select-Object -First 1
    } catch {
        $version = "(version check failed)"
    }

    return [pscustomobject]@{
        Command = $Command
        Path    = $cmd.Source
        Version = $version
    }
}

# -----------------------------------------------------------------------------
# 4) Tool registry
# -----------------------------------------------------------------------------
$tools = @(
    @{
        Name     = "Git"
        Command  = "git"
        WingetId = "Git.Git"
    },
    @{
        Name     = "GitHub CLI"
        Command  = "gh"
        WingetId = "GitHub.cli"
    },
    @{
        Name     = "Python 3"
        Command  = "python"
        WingetId = "Python.Python.3.12"
    },
    @{
        Name     = "Node.js LTS"
        Command  = "node"
        WingetId = "OpenJS.NodeJS.LTS"
    },
    @{
        Name     = "Visual Studio Code"
        Command  = "code"
        WingetId = "Microsoft.VisualStudioCode"
    }
)

# -----------------------------------------------------------------------------
# 5) Scan & optionally install
# -----------------------------------------------------------------------------
$missing = @()

foreach ($tool in $tools) {
    $info = Get-ToolInfo -Command $tool.Command
    if ($null -eq $info) {
        Log "[MISS] $($tool.Name) ($($tool.Command)) not found in PATH."
        $missing += $tool
    } else {
        Log "[HAVE] $($tool.Name) ($($tool.Command))"
        Log "       Path   : $($info.Path)"
        Log "       Version: $($info.Version)"
    }
    Log ""
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "[GodBox-Dev] Scan complete. Missing tools:" -ForegroundColor Cyan
    if ($missing.Count -eq 0) {
        Write-Host "  (none) — you're fully stocked."
    } else {
        foreach ($m in $missing) {
            Write-Host "  - $($m.Name) via winget id '$($m.WingetId)'"
        }
        Write-Host ""
        Write-Host "To install/upgrade these automatically, re-run with:" -ForegroundColor Yellow
        Write-Host "  pwsh -File .\Install-DevStack.ps1 -Apply"
    }

    Log "=== SCAN-ONLY COMPLETE ==="
    return
}

# -----------------------------------------------------------------------------
# 6) Apply mode: install/upgrade missing tools (only if winget exists)
# -----------------------------------------------------------------------------
if (-not $HasWinget) {
    # This should already be handled above; extra guard.
    Write-Host "[GodBox-Dev] winget still missing; cannot perform installs." -ForegroundColor Yellow
    Log "=== APPLY MODE ABORTED: winget missing. ==="
    return
}

if ($missing.Count -eq 0) {
    Write-Host "[GodBox-Dev] No missing tools. You can still manually 'winget upgrade' if desired."
    Log "=== APPLY MODE: nothing to install. ==="
    return
}

Write-Host ""
Write-Host "[GodBox-Dev] APPLY mode: installing/upgrading missing tools via winget..." -ForegroundColor Yellow

foreach ($tool in $missing) {
    $id = $tool.WingetId
    Write-Host ""
    Write-Host "[GodBox-Dev] >>> Installing $($tool.Name) via winget ($id) ..."
    Log "Installing $($tool.Name) via winget ($id)"

    try {
        winget install --id $id --source winget --silent --accept-source-agreements --accept-package-agreements
        Log "SUCCESS: $($tool.Name) installed/upgraded."
    } catch {
        Log "ERROR: Failed to install $($tool.Name): $($_.Exception.Message)"
        Write-Host "[GodBox-Dev] ERROR installing $($tool.Name). See log for details." -ForegroundColor Red
    }
}

Log "=== APPLY COMPLETE ==="
Write-Host ""
Write-Host "[GodBox-Dev] Install phase complete. Re-open GodBox terminals to pick up any new PATH changes."
