# Installs the repo's Herdr config and the scripts its status row calls,
# backing up what they replace.
#
# The status row runs a command per entry on the Herdr server and shows what it
# prints: Site Watch alarms, the inbox, the next meeting. The commands are in
# apps/herdr/bin and go to ~/bin, which is why they travel with the config —
# a config pointing at scripts that are not there shows nothing and says
# nothing about why. They call wsg (scoop, see install-apps-scoop.ps1) and sign
# in as whoever runs them; on a new machine the row stays empty until
# `wsg graph login` and `wsg arena login` have been run once.
$Source = "$PSScriptRoot\..\apps\herdr"

$Target = "$env:APPDATA\herdr\config.toml"
New-Item -ItemType Directory -Force (Split-Path $Target) | Out-Null
if (Test-Path $Target) {
    Copy-Item $Target "$Target.bak" -Force
}
Copy-Item "$Source\config.toml" $Target -Force
Write-Host "Installed $Target"

$BinDir = "$env:USERPROFILE\bin"
New-Item -ItemType Directory -Force $BinDir | Out-Null
Get-ChildItem "$Source\bin" -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $BinDir $_.Name) -Force
    Write-Host "Installed $($_.Name) to $BinDir"
}

# A running server keeps the old config until it is told otherwise. On a fresh
# machine there is none, and the reload failing is not worth stopping for.
if (Get-Command herdr -ErrorAction SilentlyContinue) {
    try {
        herdr server reload-config | Out-Null
        Write-Host 'Reloaded the running Herdr server'
    } catch {
        Write-Host 'No running Herdr server to reload'
    }
}
