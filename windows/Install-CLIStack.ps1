<#
GodBox – Install A3 CLI Stack (Windows)
Corrected version — fixes ParserError due to $Id: expansion.
#>

param(
    [string]$RepoRoot = "K:\Kydras\Repos\Kydras-GodBox"
)

$ErrorActionPreference = "Stop"

Write-Host "[GodBox-CLI] === Installing CLI Stack (A3) ==="

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
$LogDir = Join-Path $RepoRoot "logs\devstack"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$Log = Join-Path $LogDir ("cli-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

function Log {
    param([string]$Message)
    $Message | Tee-Object -FilePath $Log -Append
}

Log "=== CLI install run: $(Get-Date) ==="

# -----------------------------------------------------------------------------
# Admin check
# -----------------------------------------------------------------------------
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Log "[WARN] Not running as Administrator – installs may fail."
    Write-Host "[WARN] Not running as Administrator – winget installs may fail." -ForegroundColor Yellow
} else {
    Log "[OK] Running as Administrator."
}

# -----------------------------------------------------------------------------
# winget check
# -----------------------------------------------------------------------------
function Test-Winget {
    try {
        $null = winget --version 2>$null
        if ($LASTEXITCODE -eq 0) { return $true }
    } catch {}
    return $false
}

$HasWinget = Test-Winget

if ($HasWinget) {
    Log "[OK] winget available."
} else {
    Log "[MISS] winget is missing — winget-based installs will be skipped."
}

# -----------------------------------------------------------------------------
# winget installer helper (fixed for parser errors)
# -----------------------------------------------------------------------------
function Install-WG {
    param([string]$Id)

    if (-not $HasWinget) {
        Log "[SKIP] winget missing — cannot install ${Id}"
        return
    }

    Log "[WG] Installing ${Id} ..."
    try {
        winget install --id $Id --silent --accept-package-agreements --accept-source-agreements `
            | Tee-Object -FilePath $Log -Append
    } catch {
        Log ("[ERROR] winget install failed for ${Id}. Exception: " + $_.Exception.Message)
    }
}

# -----------------------------------------------------------------------------
# WINDOWS INSTALLS
# -----------------------------------------------------------------------------
Log "[STEP] Installing CLI tools via winget (if available)"

Install-WG "Git.Git"
Install-WG "GitHub.cli"
Install-WG "Microsoft.OpenSSH.Beta"
Install-WG "7zip.7zip"
Install-WG "Python.Python.3.12"

# CLI tools
Install-WG "BurntSushi.ripgrep.MSVC"  # rg
Install-WG "junegunn.fzf"             # fzf
Install-WG "sharkdp.bat"              # bat
Install-WG "sharkdp.fd"               # fd
Install-WG "eza-community.eza"        # eza
Install-WG "jqlang.jq"                # jq

# -----------------------------------------------------------------------------
# PYTHON EXTRAS
# -----------------------------------------------------------------------------
if (Get-Command python -ErrorAction SilentlyContinue) {
    Log "[STEP] Python found – installing pipx, poetry, yq"

    try {
        python -m pip install --upgrade pip | Tee-Object -FilePath $Log -Append
        python -m pip install pipx          | Tee-Object -FilePath $Log -Append
        python -m pipx ensurepath           | Tee-Object -FilePath $Log -Append

        pipx install poetry                 | Tee-Object -FilePath $Log -Append
        pipx install yq                     | Tee-Object -FilePath $Log -Append
    } catch {
        Log ("[ERROR] Python extra setup failed: " + $_.Exception.Message)
    }
} else {
    Log "[MISS] Python missing — skipping pipx/poetry"
}

# -----------------------------------------------------------------------------
# ZOXIDE (portable fallback)
# -----------------------------------------------------------------------------
$Zx = "K:\Kydras\SDKs\zoxide"
New-Item -ItemType Directory -Path $Zx -Force | Out-Null

try {
    $ZUrl = "https://github.com/ajeetdsouza/zoxide/releases/latest/download/zoxide-x86_64-pc-windows-msvc.zip"
    $Zip  = Join-Path $Zx "zoxide.zip"
    Log "[STEP] Downloading zoxide portable"

    Invoke-WebRequest $ZUrl -OutFile $Zip
    Expand-Archive $Zip -DestinationPath $Zx -Force
    Remove-Item $Zip -Force

    Log "[OK] zoxide installed to ${Zx}"
} catch {
    Log ("[ERROR] zoxide install failed: " + $_.Exception.Message)
}

# -----------------------------------------------------------------------------
# Ensure PATH contains SDK root
# -----------------------------------------------------------------------------
$SdkRoot = "K:\Kydras\SDKs"
$null = New-Item -ItemType Directory -Path $SdkRoot -Force -ErrorAction SilentlyContinue

$UserPath = [Environment]::GetEnvironmentVariable("PATH","User")
if ([string]::IsNullOrWhiteSpace($UserPath)) { $UserPath = "" }

if ($UserPath -notlike "*$SdkRoot*") {
    $newPath = if ($UserPath.Length -gt 0) { "$UserPath;$SdkRoot" } else { $SdkRoot }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Log "[ENV] Added ${SdkRoot} to user PATH"
} else {
    Log "[ENV] ${SdkRoot} already in PATH"
}

Log "=== CLI Stack Install Complete ==="
Write-Host "[GodBox-CLI] CLI Stack Installed (A3 COMPLETE)" -ForegroundColor Green
Write-Host "[GodBox-CLI] Open a NEW Terminal window to refresh PATH." -ForegroundColor Yellow
