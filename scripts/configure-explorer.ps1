# Explorer preferences: show file extensions and hidden files.
# Takes effect the next time Explorer starts (init ends with a reboot anyway).
$Advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty -Path $Advanced -Name HideFileExt -Value 0
Set-ItemProperty -Path $Advanced -Name Hidden -Value 1
