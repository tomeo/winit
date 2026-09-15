# Makes VS Code the app that opens .md files.
# Registers the same ProgId scoop's own install-associations.reg uses, but for
# .md only, instead of the 90-odd extensions that file claims. Windows honours
# this as long as no choice has been saved for .md: once one has, the UserChoice
# hash protects it and only Settings can change it, like the default browser.
$CodeExe = Join-Path $env:USERPROFILE 'scoop\apps\vscode\current\Code.exe'
if (-not (Test-Path $CodeExe)) {
    Write-Host "No VS Code at $CodeExe, run install-vscode.ps1 first" -ForegroundColor Yellow
    return
}

$ProgId = 'CodeOSS.md'
$Key = "HKCU:\Software\Classes\$ProgId"
# The icon is Code.exe's own, not the markdown.ico scoop's reg file points at:
# since 1.133 VS Code keeps its resources under a build-hash folder that changes
# with every update, so a path into it goes stale (which is why that reg file
# leaves .md iconless too). Code.exe sits behind the stable current junction.
$Icon = "`"$CodeExe`",0"

New-Item -Path "$Key\shell\open\command" -Force | Out-Null
New-Item -Path "$Key\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path $Key -Name '(default)' -Value 'Markdown Source File'
Set-ItemProperty -Path $Key -Name 'AppUserModelID' -Value 'Microsoft.CodeOSS'
Set-ItemProperty -Path "$Key\DefaultIcon" -Name '(default)' -Value $Icon
Set-ItemProperty -Path "$Key\shell\open" -Name 'Icon' -Value "`"$CodeExe`""
Set-ItemProperty -Path "$Key\shell\open\command" -Name '(default)' -Value "`"$CodeExe`" `"%1`""

New-Item -Path 'HKCU:\Software\Classes\.md\OpenWithProgids' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Classes\.md' -Name '(default)' -Value $ProgId
Set-ItemProperty -Path 'HKCU:\Software\Classes\.md\OpenWithProgids' -Name $ProgId -Value ''

# Tell the shell the associations changed, so it doesn't need a restart.
if (-not ('Winit.Shell' -as [type])) {
    Add-Type -Namespace Winit -Name Shell -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("shell32.dll")]
public static extern void SHChangeNotify(int eventId, uint flags, System.IntPtr item1, System.IntPtr item2);
'@
}
[Winit.Shell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
ie4uinit.exe -show   # drops the cached icon for the extension

$Choice = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.md\UserChoice' -ErrorAction SilentlyContinue).ProgId
if ($Choice -and $Choice -ne $ProgId) {
    Write-Host "Windows has a saved choice for .md ($Choice) that a script can't overwrite"
    Write-Host 'Pick Visual Studio Code under .md in the window that opens'
    Start-Process 'ms-settings:defaultapps'
} else {
    Write-Host '.md files now open in VS Code'
}
