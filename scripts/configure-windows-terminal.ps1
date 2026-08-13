# Windows Terminal is installed via scoop on purpose, so its settings live
# in the scoop dir. Backs up the current settings before overwriting.
$Target = "$env:USERPROFILE\scoop\apps\windows-terminal\current\settings\settings.json"

New-Item -ItemType Directory -Force (Split-Path $Target) | Out-Null
if (Test-Path $Target) {
    Copy-Item $Target "$Target.bak" -Force
}
Copy-Item "$PSScriptRoot\..\apps\windows-terminal\settings.json" $Target
