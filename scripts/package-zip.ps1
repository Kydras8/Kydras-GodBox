param(
    [string]$OutputDir = "dist"
)

$repoName = Split-Path -Leaf (Get-Location)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$distDir = Join-Path $PWD $OutputDir
$zipName = "$repoName-$timestamp.zip"
$zipPath = Join-Path $distDir $zipName

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

Write-Host "Packaging repo into: $zipPath"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path * -DestinationPath $zipPath -Force -CompressionLevel Optimal

Write-Host "ZIP created: $zipPath"
