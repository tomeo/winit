# Turns the three finger touchpad gestures off, so a stray third finger while
# scrolling stops throwing up Task View. -IncludeFourFinger takes those too,
# -Revert puts the Windows defaults back.
param(
    [switch]$IncludeFourFinger,
    [switch]$Revert
)

$TouchPad = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PrecisionTouchPad'

# The key only exists on machines with a precision touchpad.
if (-not (Test-Path $TouchPad)) {
    Write-Host 'No precision touchpad on this machine, nothing to do.'
    return
}

# Windows leaves these values unset and falls back to the defaults below:
# 3 finger slide switches apps, 4 finger slide switches desktops, both taps
# open search. 0 means Nothing on all four.
$Defaults = @{
    ThreeFingerSlideEnabled = 1
    ThreeFingerTapEnabled   = 1
    FourFingerSlideEnabled  = 2
    FourFingerTapEnabled    = 1
}

$Names = @('ThreeFingerSlideEnabled', 'ThreeFingerTapEnabled')
# A revert always restores all four, whether or not this run turned them off.
if ($IncludeFourFinger -or $Revert) { $Names += 'FourFingerSlideEnabled', 'FourFingerTapEnabled' }

foreach ($Name in $Names) {
    $Value = if ($Revert) { $Defaults[$Name] } else { 0 }
    New-ItemProperty -Path $TouchPad -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

if ($Revert) {
    Write-Host 'Touchpad gestures back to the Windows defaults: 3 fingers switch apps, 4 switch desktops.'
} else {
    $Which = if ($IncludeFourFinger) { 'Three and four finger' } else { 'Three finger' }
    Write-Host "$Which swipes and taps are off. Two finger scrolling, zoom and taps are untouched."
}
Write-Host 'Check it under Settings > Bluetooth & devices > Touchpad; sign out and in if a gesture still fires.'
