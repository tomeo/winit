# Checks that Chrome is the default browser, opening Settings if not.
# Windows protects the default-app choice with a hash, so the default can't
# be set by script reliably: the check is scripted and the actual switch is
# the one manual click in Settings.
$Current = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice').ProgId
if ($Current -like 'ChromeHTML*') {
    Write-Host 'Chrome is already the default browser'
} else {
    Write-Host 'Click "Set default" for Google Chrome in the window that opens'
    Start-Process 'ms-settings:defaultapps'
}
