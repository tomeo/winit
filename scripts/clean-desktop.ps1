# Removes shortcuts (*.lnk, *.url) that installers drop on the desktop.
# Only shortcuts are touched: real files and folders are left alone.
$Extensions = '.lnk', '.url'

$Desktop = [Environment]::GetFolderPath('Desktop')
$Links = @(Get-ChildItem $Desktop -File | Where-Object { $_.Extension -in $Extensions })
$Links | Remove-Item
$Links | ForEach-Object { Write-Host "  removed $($_.Name)" }

# The public desktop needs elevation, so sudo only when there is something to remove.
$PublicLinks = @(Get-ChildItem 'C:\Users\Public\Desktop' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in $Extensions })
if ($PublicLinks) {
    sudo powershell -NoProfile -Command "Remove-Item 'C:\Users\Public\Desktop\*.lnk', 'C:\Users\Public\Desktop\*.url'"
    $PublicLinks | ForEach-Object { Write-Host "  removed $($_.Name) (public)" }
}

if (-not $Links -and -not $PublicLinks) { Write-Host 'No shortcuts to remove.' }
