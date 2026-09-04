# Takes the camera out of Windows Hello: disables the face recognition device so
# sign-in is PIN and password (fingerprint untouched). Elevated. -Revert puts it back.
param([switch]$Revert)

# Disable-PnpDevice needs admin. From a regular shell, re-run through sudo.
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
if (-not $IsAdmin) {
    $Forward = @()
    if ($Revert) { $Forward += '-Revert' }
    sudo powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @Forward
    return
}

# Windows Hello face is its own biometric unit, a software device on top of the IR
# camera. Disabling that one unit is enough: Settings stops offering face, the lock
# screen stops looking for you, and the normal camera, the IR camera and the
# fingerprint reader are left alone. The enrolment stays in the biometric database,
# so -Revert brings face sign-in back without setting it up again.
$Face = Get-PnpDevice -PresentOnly -Class Biometric |
    Where-Object { $_.InstanceId -like 'ROOT\WINDOWSHELLOFACESOFTWAREDRIVER\*' -or $_.FriendlyName -like 'Facial Recognition*' }
if (-not $Face) {
    Write-Host "No Windows Hello face device on this machine, nothing to do."
    return
}

foreach ($Device in $Face) {
    $Disabled = $Device.Problem -eq 'CM_PROB_DISABLED'
    if ($Revert) {
        if (-not $Disabled) {
            Write-Host "$($Device.FriendlyName) is already enabled."
            continue
        }
        Enable-PnpDevice -InstanceId $Device.InstanceId -Confirm:$false
        Write-Host "Enabled $($Device.FriendlyName). Face sign-in is back."
    } else {
        if ($Disabled) {
            Write-Host "$($Device.FriendlyName) is already disabled."
            continue
        }
        Disable-PnpDevice -InstanceId $Device.InstanceId -Confirm:$false
        Write-Host "Disabled $($Device.FriendlyName). Sign-in is PIN and password from now on."
    }
}
