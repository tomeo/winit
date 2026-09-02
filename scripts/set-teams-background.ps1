# Installs a SharePoint hosted image as a Teams background, for one account only.
# It does nothing unless the machine is signed in as the account the image
# belongs to, checked against the Windows UPN. This repo is public, so
# the picture is fetched from SharePoint at run time instead of being committed:
# the share link is not a secret, the picture behind it is. Downloading it needs
# a token, which comes from the Azure CLI (installed by install-apps-winget.ps1).
# -RestartTeams restarts Teams so a running client reads the new file, and
# -Revert removes the background again.
param(
    [string]$Url = 'https://infospobik.sharepoint.com/:i:/s/VartexAB/IQBqC9Z3qqL2TrNCXhJrOfzIAZSV_c0orjGz2S4wXuIhMyw?e=1XOlFF',
    [string]$Upn = 'tommy.ivarsson@vartex.se',
    [string]$Path,
    [switch]$RestartTeams,
    [switch]$Revert
)

# Where the new Teams (the MSTeams app package, not the retired desktop client)
# reads custom backgrounds from. Teams creates the folder itself on first run.
$Uploads = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"

# Teams reads the Uploads folder at startup, so a background added underneath a
# running client does not turn up in the picker until it restarts. Asked to close
# its window first; the tray process ignores that, so whatever is left is killed.
function Restart-Teams {
    if (-not (Get-Process -Name ms-teams -ErrorAction SilentlyContinue)) {
        Write-Host 'Teams is not running, so it will read the folder at its next start.'
        return
    }
    Get-Process -Name ms-teams | ForEach-Object { $null = $_.CloseMainWindow() }
    Start-Sleep -Seconds 2
    Get-Process -Name ms-teams -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    # A packaged app has no exe to launch by path, it starts through its app id.
    Start-Process 'shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams'
    Write-Host 'Restarted Teams.'
}

# Full path on purpose: git's usr\bin is ahead of System32 on the PATH and its
# own whoami does not understand /upn. Fails on a local account, hence the 2>$null.
$Current = & "$env:SystemRoot\System32\whoami.exe" /upn 2>$null
if ($Current -ne $Upn) {
    Write-Host "Signed in as $(if ($Current) { $Current } else { 'a local account' }), not $Upn. Skipping the Teams background."
    return
}

# Teams identifies a background by its file name, which has to be a GUID. Deriving
# it from the URL keeps it stable, so a re-run replaces the image instead of
# adding a second copy of it to the picker.
$Md5 = [Security.Cryptography.MD5]::Create()
$Id = [Guid]::new($Md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($Url))).Guid

if ($Revert) {
    $Existing = @(Get-ChildItem "$Uploads\$Id*" -ErrorAction SilentlyContinue)
    if (-not $Existing) {
        Write-Host 'No winit background installed, nothing to revert.'
        return
    }
    $Existing | Remove-Item -Force
    Write-Host "Removed the background from $Uploads"
    if ($RestartTeams) { Restart-Teams } else { Write-Host 'Restart Teams to drop it from the background picker.' }
    return
}

function Get-GraphToken {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw 'The Azure CLI is not installed, run ./install-apps-winget.ps1 first.'
    }
    # Silent when the CLI already has a session; it refreshes expired tokens itself.
    $Token = az account get-access-token --resource-type ms-graph --query accessToken -o tsv 2>$null
    if ($LASTEXITCODE -eq 0 -and $Token) { return $Token }
    Write-Host 'The Azure CLI has no session, opening a browser to sign in...'
    az login --only-show-errors | Out-Null
    $Token = az account get-access-token --resource-type ms-graph --query accessToken -o tsv 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $Token) { throw 'Could not get a Graph token from the Azure CLI.' }
    return $Token
}

if ($Path) {
    $Source = (Resolve-Path $Path).Path
    $Bytes = [IO.File]::ReadAllBytes($Source)
    $Name = Split-Path $Source -Leaf
} else {
    # Graph addresses a sharing link as an unpadded base64url of the URL itself,
    # which saves having to know the site, library and path behind it.
    $ShareId = 'u!' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Url)).TrimEnd('=').Replace('/', '_').Replace('+', '-')
    $Item = Invoke-RestMethod "https://graph.microsoft.com/v1.0/shares/$ShareId/driveItem" -Headers @{ Authorization = "Bearer $(Get-GraphToken)" }
    # The download URL is pre-authenticated, so it takes no Authorization header.
    $Bytes = (Invoke-WebRequest $Item.'@microsoft.graph.downloadUrl' -UseBasicParsing).Content
    $Name = $Item.name
}

# Teams only picks up .png and .jpg, and .jpeg is common enough on SharePoint to
# be worth renaming rather than silently installing a file Teams ignores.
$Extension = [IO.Path]::GetExtension($Name).ToLower()
if ($Extension -eq '.jpeg') { $Extension = '.jpg' }
if ($Extension -notin '.png', '.jpg') { throw "$Name is a $Extension, Teams only reads .png and .jpg backgrounds." }

# Teams renders a background at 1920x1080 and the picker grid at 280 wide, so the
# image is opened once: to warn about a small one, and to scale the _thumb file
# the grid shows. Kept in a variable because GDI+ needs the stream alive with it.
function Open-Image {
    param([byte[]]$Bytes)
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $script:Stream = New-Object IO.MemoryStream -ArgumentList @(, $Bytes)
        return [Drawing.Image]::FromStream($script:Stream)
    } catch {
        Write-Host "Could not read the image ($($_.Exception.Message)), installing it unscaled."
        return $null
    }
}

New-Item -ItemType Directory -Path $Uploads -Force | Out-Null
$Background = "$Uploads\$Id$Extension"

# Written every run so an updated image in SharePoint reaches the machine, but
# only when it actually differs, to keep a re-run quiet.
$NewHash = (Get-FileHash -InputStream (New-Object IO.MemoryStream -ArgumentList @(, $Bytes))).Hash
$OldHash = if (Test-Path $Background) { (Get-FileHash $Background).Hash }
if ($NewHash -eq $OldHash) {
    Write-Host "$Name is already installed as a Teams background, skipping."
    # Still worth restarting when asked: the usual reason the picker is missing a
    # background is that it was installed underneath a client already running.
    if ($RestartTeams) { Restart-Teams }
    return
}

$Image = Open-Image -Bytes $Bytes
if ($Image -and ($Image.Width -lt 1920 -or $Image.Height -lt 1080)) {
    Write-Host "$Name is only $($Image.Width)x$($Image.Height). Teams upscales a background to 1920x1080, so it will look soft." -ForegroundColor Yellow
}

# Files left over from an earlier run of this script with another extension.
Get-ChildItem "$Uploads\$Id*" -ErrorAction SilentlyContinue | Remove-Item -Force
[IO.File]::WriteAllBytes($Background, $Bytes)

$Thumbnail = "$Uploads\${Id}_thumb$Extension"
if ($Image) {
    $Height = [int][Math]::Round(280 * $Image.Height / $Image.Width)
    $Scaled = New-Object Drawing.Bitmap -ArgumentList $Image, 280, $Height
    $Scaled.Save($Thumbnail, $Image.RawFormat)
    $Scaled.Dispose()
    $Image.Dispose()
} else {
    # A full size thumbnail is only wasteful, not broken, so it beats failing.
    [IO.File]::WriteAllBytes($Thumbnail, $Bytes)
}

Write-Host "Installed $Name as a Teams background in $Uploads"
if ($RestartTeams) { Restart-Teams } else { Write-Host 'Restart Teams so it reads the new file.' }
Write-Host 'Then pick it under More > Video effects and settings. Teams remembers the choice,'
Write-Host 'which lives in its own database and is not something this script can set.'
Write-Host 'Remove it again with: ./set-teams-background.ps1 -Revert'
