# Runs all scripts in order. Normally invoked by ../bootstrap.ps1,
# but can be run on its own from a regular (non-admin) PowerShell.
Push-Location $PSScriptRoot

./install-scoop.ps1
./install-apps-scoop.ps1
./install-apps-winget.ps1
./install-fonts.ps1
./install-nodejs.ps1
./install-vscode.ps1
./configure-git.ps1
./configure-windows-terminal.ps1
./set-keyboard-layouts.ps1

# These need elevation; sudo (installed by install-fonts.ps1) triggers a UAC prompt.
sudo powershell -NoProfile -ExecutionPolicy Bypass -File .\install-wsl.ps1
sudo powershell -NoProfile -ExecutionPolicy Bypass -File .\remap-caps-lock-to-ctrl.ps1

Pop-Location
Write-Host "Done. Reboot to apply the caps lock remap and finish the WSL install." -ForegroundColor Green
