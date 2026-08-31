# Strips the taskbar down to Start and whatever is running: no search box, no
# task view, chat or copilot button, and none of the pinned shortcuts
# (Edge, Microsoft Store, File Explorer). Explorer is restarted at the end
# because it holds the pin list in memory and writes the old one back at
# sign-out. The pins and button settings are backed up first, so -Revert puts
# back exactly what was there.
param([switch]$Revert)

$Advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$Search = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
$Taskband = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
$Pinned = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
$Backup = "$env:LOCALAPPDATA\winit\taskbar"

# Which value hides which button. 0 hides every one of them. Widgets is not in
# here: Windows 11 25H2 denies writes to TaskbarDa outright, elevated or not, so
# the only switch left for it is the machine-wide DshAllowNewsAndInterests policy.
$Buttons = [ordered]@{
    'Search box' = @{ Path = $Search;   Name = 'SearchboxTaskbarMode' }
    'Task view'  = @{ Path = $Advanced; Name = 'ShowTaskViewButton' }
    'Chat'       = @{ Path = $Advanced; Name = 'TaskbarMn' }
    'Copilot'    = @{ Path = $Advanced; Name = 'ShowCopilotButton' }
}

function Restart-Explorer {
    # Forced, so Explorer does not get to save its in-memory pin list on the way
    # out and undo the change. Windows normally starts the shell again by itself.
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer }
}

if ($Revert) {
    if (-not (Test-Path "$Backup\buttons.json")) {
        Write-Host "Nothing to revert: no backup in $Backup"
        return
    }
    $Saved = Get-Content "$Backup\buttons.json" -Raw | ConvertFrom-Json
    foreach ($Button in $Buttons.GetEnumerator()) {
        $Value = $Saved.($Button.Key)
        if ($null -eq $Value) {
            Remove-ItemProperty $Button.Value.Path -Name $Button.Value.Name -ErrorAction SilentlyContinue
        } else {
            try {
                Set-ItemProperty $Button.Value.Path -Name $Button.Value.Name -Value $Value -Type DWord -ErrorAction Stop
            } catch {
                Write-Host "Could not restore $($Button.Key): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    reg import "$Backup\taskband.reg"
    Copy-Item "$Backup\pinned\*.lnk" $Pinned -Force -ErrorAction SilentlyContinue
    Restart-Explorer
    Write-Host "Taskbar restored from $Backup"
    return
}

# Save the state once, on the first run, so a later -Revert has the original to
# restore rather than the already stripped taskbar.
if (-not (Test-Path $Backup)) {
    New-Item -ItemType Directory -Path "$Backup\pinned" -Force | Out-Null
    $State = [ordered]@{}
    foreach ($Button in $Buttons.GetEnumerator()) {
        $State[$Button.Key] = (Get-ItemProperty $Button.Value.Path -Name $Button.Value.Name -ErrorAction SilentlyContinue).($Button.Value.Name)
    }
    $State | ConvertTo-Json | Set-Content "$Backup\buttons.json" -Encoding utf8
    reg export 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband' "$Backup\taskband.reg" /y | Out-Null
    Copy-Item "$Pinned\*.lnk" "$Backup\pinned" -Force -ErrorAction SilentlyContinue
}

foreach ($Button in $Buttons.GetEnumerator()) {
    # A value Windows has locked down throws; name it and carry on, rather than
    # leaving the pins in place over one button that will not budge.
    try {
        Set-ItemProperty $Button.Value.Path -Name $Button.Value.Name -Value 0 -Type DWord -ErrorAction Stop
    } catch {
        Write-Host "Could not hide $($Button.Key): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# A pin is two things: an entry in the Taskband blob, and for desktop apps a
# shortcut on disk. Store and other packaged apps only live in the blob.
Remove-ItemProperty $Taskband -Name Favorites, FavoritesResolve, FavoritesChanges, FavoritesVersion -ErrorAction SilentlyContinue
Remove-Item "$Pinned\*.lnk" -Force -ErrorAction SilentlyContinue

Restart-Explorer
Write-Host "Taskbar cleared: no search box, task view, chat or copilot, and no pins."
Write-Host "Backed up to $Backup, put it all back with: ./configure-taskbar.ps1 -Revert"
