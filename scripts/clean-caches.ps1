# Reclaims disk space from package caches, old scoop versions and %TEMP%.
# Everything here is re-downloadable, so it is safe to run any time.

Write-Host '=== Scoop: old app versions and download cache ===' -ForegroundColor Cyan
scoop cleanup *
scoop cache rm *

Write-Host '=== npm cache ===' -ForegroundColor Cyan
npm cache clean --force

if (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host '=== pip cache ===' -ForegroundColor Cyan
    pip cache purge
}

Write-Host '=== %TEMP% files older than 7 days ===' -ForegroundColor Cyan
$Cutoff = (Get-Date).AddDays(-7)
Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $Cutoff } |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
