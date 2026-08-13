# Copies dotfiles into the user profile, backing up anything they replace.
Get-ChildItem "$PSScriptRoot\..\dotfiles" -File -Force | ForEach-Object {
    $Target = Join-Path $env:USERPROFILE $_.Name
    if (Test-Path $Target) {
        Copy-Item $Target "$Target.bak" -Force
    }
    Copy-Item $_.FullName $Target -Force
    Write-Host "Installed $($_.Name)"
}
