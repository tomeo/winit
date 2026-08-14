# Windows protects the default-app choice with a hash, so setting Chrome as
# the default browser can't be scripted reliably. Instead: check if it is
# already the default, and open the settings page for the one manual click
# if it is not.
$Current = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice').ProgId
if ($Current -like 'ChromeHTML*') {
    Write-Host 'Chrome is already the default browser'
} else {
    Write-Host 'Click "Set default" for Google Chrome in the window that opens'
    Start-Process 'ms-settings:defaultapps'
}
