# Installs GUI apps via winget, skipping anything already installed.
# Skip detection covers winget, manual installers and scoop. Safe to re-run.
function Install-App {
    param([string]$Id, [string]$ScoopName, [string]$Source)

    if ($ScoopName -and (Test-Path "$env:USERPROFILE\scoop\apps\$ScoopName")) {
        Write-Host "$Id is already installed via scoop, skipping"
        return
    }
    $null = winget list -e --id $Id --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$Id is already installed, skipping"
        return
    }
    $Flags = @('-e', '--id', $Id, '--accept-source-agreements', '--accept-package-agreements')
    if ($Source) { $Flags += '--source', $Source }
    winget install @Flags
}

# GUI apps
Install-App Google.Chrome googlechrome
Install-App SlackTechnologies.Slack slack
Install-App Spotify.Spotify spotify
Install-App VideoLAN.VLC vlc
Install-App calibre.calibre calibre
Install-App Obsidian.Obsidian obsidian
Install-App SumatraPDF.SumatraPDF sumatrapdf
Install-App PDFgear.PDFgear pdfgear
Install-App DBeaver.DBeaver.Community dbeaver
Install-App mRemoteNG.mRemoteNG mremoteng
Install-App WinSCP.WinSCP winscp
Install-App JAMSoftware.TreeSize.Free treesize-free
Install-App Anthropic.Claude
Install-App Microsoft.AzureVPNClient
# WhatsApp is Store-only, hence the msstore source and product id.
Install-App 9NKSQGP7F2NH -Source msstore

# Dev tools
Install-App GitHub.cli
Install-App Microsoft.AzureCLI
Install-App Google.CloudSDK gcloud
Install-App Microsoft.DotNet.SDK.8
Install-App Microsoft.DotNet.SDK.10
# cloudflared: Cloudflare Access client. `access login` + `access token` reach
# apps behind Access from a terminal. (Also does Tunnels; we only want the client.)
Install-App Cloudflare.cloudflared

# The cloudflared MSI does not add itself to PATH, so the binary is unusable by
# name even after a successful install. User PATH, so no elevation is needed.
$CloudflaredDir = "${env:ProgramFiles(x86)}\cloudflared"
if (Test-Path "$CloudflaredDir\cloudflared.exe") {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (($UserPath -split ";") -notcontains $CloudflaredDir) {
        $NewPath = if ([string]::IsNullOrWhiteSpace($UserPath)) { $CloudflaredDir } else { "$($UserPath.TrimEnd(";"));$CloudflaredDir" }
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
        Write-Host "Added $CloudflaredDir to the user PATH"
    } else {
        Write-Host "cloudflared is already on the user PATH, skipping"
    }
}
