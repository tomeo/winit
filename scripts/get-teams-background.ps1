# Downloads the Teams background image from SharePoint, for one account only, and
# leaves it on disk for a one-time upload into Teams. It does nothing unless the
# machine is signed in as the account the image belongs to, checked against the
# Windows UPN. This repo is public, so the picture is fetched at run time rather
# than committed: the share link is not a secret, the picture behind it is. The
# download needs a token, which comes from the Azure CLI (install-apps-winget.ps1).
#
# The upload into Teams is not scriptable, hence a script that only fetches a
# file. Build 26213 keeps custom backgrounds in the service, at
# teams.microsoft.com/maglev/custom-video-background/upload/v2, which makes the
# local Backgrounds\Uploads folder a download cache: a file dropped there never
# reaches the picker. That upload wants a skype token, and every authz endpoint
# that used to mint one now answers 410. One manual upload is enough though, on
# any machine: the service roams the background to every other one.
param(
    [string]$Url = 'https://infospobik.sharepoint.com/:i:/s/VartexAB/IQBqC9Z3qqL2TrNCXhJrOfzIAZSV_c0orjGz2S4wXuIhMyw?e=1XOlFF',
    [string]$Upn = 'tommy.ivarsson@vartex.se',
    [switch]$Open
)

$Directory = "$env:LOCALAPPDATA\winit\teams-background"

# Full path on purpose: git's usr\bin is ahead of System32 on the PATH and its
# own whoami does not understand /upn. Fails on a local account, hence the 2>$null.
$Current = & "$env:SystemRoot\System32\whoami.exe" /upn 2>$null
if ($Current -ne $Upn) {
    Write-Host "Signed in as $(if ($Current) { $Current } else { 'a local account' }), not $Upn. Skipping the Teams background."
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

# Graph addresses a sharing link as an unpadded base64url of the URL itself, which
# saves having to know the site, library and path behind it.
$ShareId = 'u!' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Url)).TrimEnd('=').Replace('/', '_').Replace('+', '-')
$Item = Invoke-RestMethod "https://graph.microsoft.com/v1.0/shares/$ShareId/driveItem" -Headers @{ Authorization = "Bearer $(Get-GraphToken)" }
# The download URL is pre-authenticated, so it takes no Authorization header.
$Bytes = (Invoke-WebRequest $Item.'@microsoft.graph.downloadUrl' -UseBasicParsing).Content

New-Item -ItemType Directory -Path $Directory -Force | Out-Null
$File = Join-Path $Directory $Item.name

# Fetched every run so an updated image in SharePoint reaches the machine, but
# only written when it actually differs, to keep a re-run quiet.
$NewHash = (Get-FileHash -InputStream (New-Object IO.MemoryStream -ArgumentList @(, $Bytes))).Hash
$OldHash = if (Test-Path $File) { (Get-FileHash $File).Hash }
if ($NewHash -eq $OldHash) {
    Write-Host "$($Item.name) is already in $Directory, unchanged in SharePoint."
} else {
    [IO.File]::WriteAllBytes($File, $Bytes)
    Write-Host "Downloaded $($Item.name) to $Directory"

    # Teams renders a background at 1920x1080, so a smaller one arrives upscaled.
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $Stream = New-Object IO.MemoryStream -ArgumentList @(, $Bytes)
        $Image = [Drawing.Image]::FromStream($Stream)
        if ($Image.Width -lt 1920 -or $Image.Height -lt 1080) {
            Write-Host "It is only $($Image.Width)x$($Image.Height). Teams upscales a background to 1920x1080, so it will look soft." -ForegroundColor Yellow
        }
        $Image.Dispose(); $Stream.Dispose()
    } catch {
        Write-Host "Could not read its dimensions ($($_.Exception.Message))."
    }
}

if ($Open) { explorer.exe "/select,$File" }
Write-Host 'Upload it once in Teams, under More > Video effects and settings > Add new.'
Write-Host 'Teams roams the background from there, so this is per account, not per machine.'
