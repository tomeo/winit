# Per-user font install, no elevation needed.
scoop bucket add nerd-fonts
if (Test-Path "$env:ProgramData\scoop\apps\firacode-nf") {
    Write-Host "firacode-nf is already installed globally, skipping"
} else {
    scoop install firacode-nf
}
