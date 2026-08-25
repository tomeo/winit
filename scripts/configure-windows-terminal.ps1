# Installs the repo's Windows Terminal settings, backing up what they replace.
# Two installs can exist side by side: the scoop one and the Windows 11
# built-in (packaged) one. They read different settings files, so the
# settings go to every install that is present.
$Source = "$PSScriptRoot\..\apps\windows-terminal\settings.json"

$Targets = @()
$ScoopDir = "$env:USERPROFILE\scoop\apps\windows-terminal\current"
if (Test-Path $ScoopDir) { $Targets += "$ScoopDir\settings\settings.json" }
$PackageDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe"
if (Test-Path $PackageDir) { $Targets += "$PackageDir\LocalState\settings.json" }

foreach ($Target in $Targets) {
    New-Item -ItemType Directory -Force (Split-Path $Target) | Out-Null
    if (Test-Path $Target) {
        Copy-Item $Target "$Target.bak" -Force
    }
    Copy-Item $Source $Target
    Write-Host "Installed terminal settings to $Target"
}
