param(
    [switch]$CI
)

$stack = "other"

Write-Host "=== Build starting ($($PWD)) ==="

switch ($stack) {
    "node" {
        if (Test-Path package.json) {
            npm install
            if (Test-Path package-lock.json) { npm ci }
            if (Select-String -Path package.json -Pattern '"build"' -Quiet) {
                npm run build
            }
        }
    }
    "python" {
        if (Test-Path pyproject.toml) {
            python -m pip install -U pip
            python -m pip install .
        }
        elseif (Test-Path requirements.txt) {
            python -m pip install -U pip
            python -m pip install -r requirements.txt
        }
    }
    "dotnet" {
        $sln = Get-ChildItem -Filter *.sln | Select-Object -First 1
        if ($sln) {
            dotnet restore $sln.FullName
            dotnet build $sln.FullName -c Release
        }
    }
    default {
        Write-Host "No specific build steps for stack: $stack"
    }
}

Write-Host "=== Build completed ==="
