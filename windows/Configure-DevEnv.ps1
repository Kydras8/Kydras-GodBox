<#
.Kydras-GodBox Dev Environment Configurator (Windows)

Phase A2: Configure core dev tooling defaults for GodBox.

What this script does:
  - Logs to:  <RepoRoot>\logs\devenv\devenv-YYYYMMDD-HHMMSS.log
  - Detects tools: git, npm, python, code
  - Sets safe global Git defaults (Kydras identity, default branch main)
  - Forces npm global prefix and cache to K: drive:
        K:\Kydras\SDKs\Node\npm-global
        K:\Kydras\SDKs\Node\npm-cache
  - Creates Python pip cache folder on K: and sets PIP_CACHE_DIR (user-level env var)

Safe & idempotent: you can run this multiple times.

Usage:
  K:
  cd K:\Kydras\Repos\Kydras-GodBox\windows
  pwsh -File .\Configure-DevEnv.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = "K:\Kydras\Repos\Kydras-GodBox"
)

$ErrorActionPreference = "Stop"

Write-Host "[GodBox-DevEnv] === Configure Dev Environment ==="
Write-Host "[GodBox-DevEnv] RepoRoot: $RepoRoot"

# -----------------------------------------------------------------------------
# 0) Paths & logging
# -----------------------------------------------------------------------------
$LogDir = Join-Path $RepoRoot "logs\devenv"
$null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue
$LogPath = Join-Path $LogDir ("devenv-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

Write-Host "[GodBox-DevEnv] Log file: $LogPath"
"=== DevEnv run: $(Get-Date) ===" | Out-File -FilePath $LogPath -Encoding UTF8

function Log {
    param([string]$Message)
    $Message | Tee-Object -FilePath $LogPath -Append
}

# -----------------------------------------------------------------------------
# 1) Helper: check if Admin
# -----------------------------------------------------------------------------
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Log "[WARN] This script is not running as Administrator."
    Log "       Most settings will still work (Git, npm, user env),"
    Log "       but some machine-level env changes would require elevation."
} else {
    Log "[OK] Running as Administrator."
}

# -----------------------------------------------------------------------------
# 2) Helper: check a command
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
# 3) Detect tools
# -----------------------------------------------------------------------------
$GitInfo    = Get-ToolInfo -Command "git"
$NpmInfo    = Get-ToolInfo -Command "npm" -VersionArgs "-v"
$PythonInfo = Get-ToolInfo -Command "python" -VersionArgs "--version"
$CodeInfo   = Get-ToolInfo -Command "code" -VersionArgs "--version"

foreach ($info in @($GitInfo, $NpmInfo, $PythonInfo, $CodeInfo)) {
    if ($null -eq $info) { continue }
    Log "[HAVE] $($info.Command)"
    Log "       Path   : $($info.Path)"
    Log "       Version: $($info.Version)"
}

if (-not $GitInfo)    { Log "[MISS] git not found in PATH." }
if (-not $NpmInfo)    { Log "[MISS] npm not found in PATH." }
if (-not $PythonInfo) { Log "[MISS] python not found in PATH." }
if (-not $CodeInfo)   { Log "[MISS] code (VS Code) not found in PATH." }

Log ""

# -----------------------------------------------------------------------------
# 4) Git global configuration
# -----------------------------------------------------------------------------
if ($GitInfo) {
    Log "[Git] Configuring global Git defaults (safe, idempotent)."

    function Set-GitGlobalIfEmpty {
        param(
            [Parameter(Mandatory=$true)][string]$Key,
            [Parameter(Mandatory=$true)][string]$Value
        )
        $current = git config --global $Key 2>$null
        if ([string]::IsNullOrWhiteSpace($current)) {
            Log "[Git] Setting '$Key' => '$Value'"
            git config --global $Key $Value
        } else {
            Log "[Git] Keeping existing '$Key' => '$current'"
        }
    }

    Set-GitGlobalIfEmpty -Key "user.name"             -Value "Kyle Rasmussen"
    Set-GitGlobalIfEmpty -Key "user.email"            -Value "8bitlate@gmail.com"
    Set-GitGlobalIfEmpty -Key "init.defaultBranch"    -Value "main"
    Set-GitGlobalIfEmpty -Key "core.autocrlf"         -Value "false"
    Set-GitGlobalIfEmpty -Key "pull.rebase"           -Value "false"
    Set-GitGlobalIfEmpty -Key "push.default"          -Value "simple"

    # Credential helper: safe default
    $credHelper = git config --global credential.helper 2>$null
    if ([string]::IsNullOrWhiteSpace($credHelper)) {
        Log "[Git] Setting credential.helper => manager-core"
        git config --global credential.helper manager-core
    } else {
        Log "[Git] Keeping existing credential.helper => $credHelper"
    }
} else {
    Log "[Git] Skipping Git config because git is missing."
}

Log ""

# -----------------------------------------------------------------------------
# 5) npm global prefix & cache on K:
# -----------------------------------------------------------------------------
$NodePrefix = "K:\Kydras\SDKs\Node\npm-global"
$NodeCache  = "K:\Kydras\SDKs\Node\npm-cache"

$null = New-Item -ItemType Directory -Path $NodePrefix -Force -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path $NodeCache  -Force -ErrorAction SilentlyContinue

if ($NpmInfo) {
    Log "[npm] Ensuring npm prefix & cache on K:"

    try {
        $currentPrefix = npm config get prefix 2>$null
        $currentCache  = npm config get cache  2>$null

        Log "[npm] Current prefix: $currentPrefix"
        Log "[npm] Current cache : $currentCache"

        if ($currentPrefix -ne $NodePrefix) {
            Log "[npm] Setting prefix => $NodePrefix"
            npm config set prefix $NodePrefix | Out-Null
        } else {
            Log "[npm] Prefix already set to desired value."
        }

        if ($currentCache -ne $NodeCache) {
            Log "[npm] Setting cache => $NodeCache"
            npm config set cache $NodeCache | Out-Null
        } else {
            Log "[npm] Cache already set to desired value."
        }
    } catch {
        Log "[npm] ERROR adjusting npm config: $($_.Exception.Message)"
    }
} else {
    Log "[npm] Skipping npm config because npm is missing."
}

Log ""

# -----------------------------------------------------------------------------
# 6) Python pip cache on K: (PIP_CACHE_DIR)
# -----------------------------------------------------------------------------
$PipCache = "K:\Kydras\SDKs\Python\pip-cache"
$null = New-Item -ItemType Directory -Path $PipCache -Force -ErrorAction SilentlyContinue

function Set-UserEnvVar {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Value
    )

    $current = [System.Environment]::GetEnvironmentVariable($Name, "User")
    if ($current -ne $Value) {
        Log "[Env] Setting user env '$Name' => '$Value' (was: '$current')"
        [System.Environment]::SetEnvironmentVariable($Name, $Value, "User")
    } else {
        Log "[Env] User env '$Name' already set to desired value."
    }
}

if ($PythonInfo) {
    Log "[Python] Ensuring PIP_CACHE_DIR points to K:"

    Set-UserEnvVar -Name "PIP_CACHE_DIR" -Value $PipCache
} else {
    Log "[Python] Skipping PIP_CACHE_DIR config because python is missing."
}

Log ""

# -----------------------------------------------------------------------------
# 7) Optional: Add K:\Kydras\bin to PATH (user-level)
# -----------------------------------------------------------------------------
$KydrasBin = "K:\Kydras\bin"
$null = New-Item -ItemType Directory -Path $KydrasBin -Force -ErrorAction SilentlyContinue

$UserPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$KydrasBin*") {
    $NewUserPath = if ([string]::IsNullOrWhiteSpace($UserPath)) {
        $KydrasBin
    } else {
        "$UserPath;$KydrasBin"
    }

    Log "[Env] Adding K:\Kydras\bin to user PATH."
    [System.Environment]::SetEnvironmentVariable("PATH", $NewUserPath, "User")
} else {
    Log "[Env] K:\Kydras\bin already in user PATH."
}

Log "=== DevEnv configuration complete ==="
Write-Host "[GodBox-DevEnv] Configuration complete. You may need to restart terminals to pick up env changes." -ForegroundColor Green
