# Installs WSL (elevated; finishes after a reboot). Skips if already installed.
$null = wsl --status
if ($LASTEXITCODE -eq 0) {
    Write-Host "WSL is already installed, skipping"
} else {
    wsl --install
}
