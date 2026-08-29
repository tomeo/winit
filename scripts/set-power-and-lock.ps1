# Never sleep on AC, lock after 5 minutes idle, screen off a minute later.
# Locking does not end the session, so long running jobs keep going behind the
# lock screen. -Revert puts the 5 minute sleep and no automatic lock back.
param(
    [int]$LockAfterMinutes = 5,
    [switch]$Revert
)

$Desktop = 'HKCU:\Control Panel\Desktop'

# SystemParametersInfo applies the screen saver settings to the running session.
# Writing the registry alone only takes effect at the next sign-in.
if (-not ('Winit.Spi' -as [type])) {
    Add-Type -Namespace Winit -Name Spi -MemberDefinition @'
[DllImport("user32.dll", SetLastError=true)]
public static extern bool SystemParametersInfo(uint action, uint param, IntPtr pvParam, uint winIni);
'@
}
# 17 = SETSCREENSAVEACTIVE, 15 = SETSCREENSAVETIMEOUT, 119 = SETSCREENSAVESECURE.
# 3 = SPIF_UPDATEINIFILE | SPIF_SENDCHANGE: persist the value and broadcast the change.
function Set-Spi { param([int]$Action, [int]$Value) [void][Winit.Spi]::SystemParametersInfo($Action, $Value, [IntPtr]::Zero, 3) }

if ($Revert) {
    Set-ItemProperty $Desktop -Name ScreenSaveActive -Value '0'
    Set-Spi 17 0
    powercfg /change standby-timeout-ac 5
    powercfg /change monitor-timeout-ac 5
    Write-Host "AC power: sleeps and blanks after 5 min, no automatic lock."
    return
}

# The screen saver is what locks the session, so the display must not power down
# before it gets to start. One minute of margin is enough.
$LockSeconds = $LockAfterMinutes * 60
Set-ItemProperty $Desktop -Name 'SCRNSAVE.EXE' -Value "$env:SystemRoot\System32\scrnsave.scr"
Set-ItemProperty $Desktop -Name ScreenSaveActive -Value '1'
Set-ItemProperty $Desktop -Name ScreenSaveTimeOut -Value "$LockSeconds"
Set-ItemProperty $Desktop -Name ScreenSaverIsSecure -Value '1'
Set-Spi 17 1
Set-Spi 15 $LockSeconds
Set-Spi 119 1

powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac ($LockAfterMinutes + 1)

Write-Host "AC power: never sleeps, locks after $LockAfterMinutes min, screen off after $($LockAfterMinutes + 1) min."
Write-Host "On battery nothing changed: it still sleeps, and the wake asks for the password."
Write-Host "Test the lock without waiting: $env:SystemRoot\System32\scrnsave.scr /s"
