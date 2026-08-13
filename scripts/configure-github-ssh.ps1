# Sets up SSH auth against GitHub: generates a key if missing, authenticates
# gh (opens a browser on first run), uploads the key and switches this repo's
# remote to SSH. Safe to re-run.
param([string]$Email)

if (-not $Email) { $Email = git config --global user.email }

$SshDir = "$env:USERPROFILE\.ssh"
$Key = "$SshDir\id_ed25519"
New-Item -ItemType Directory -Force $SshDir | Out-Null

if (Test-Path $Key) {
    Write-Host "SSH key already exists, skipping keygen"
} else {
    ssh-keygen -t ed25519 -C $Email -f $Key -N ''
}

$null = gh auth status
if ($LASTEXITCODE -ne 0) {
    gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key
}

# Upload the public key unless it is already on the account.
$KeyMaterial = ((Get-Content "$Key.pub") -split ' ')[1]
$Existing = gh ssh-key list
if ($Existing -match [regex]::Escape($KeyMaterial)) {
    Write-Host "SSH key is already on GitHub, skipping upload"
} else {
    gh ssh-key add "$Key.pub" --title $env:COMPUTERNAME
    if ($LASTEXITCODE -ne 0) {
        # The default token lacks the admin:public_key scope, fix and retry.
        gh auth refresh --hostname github.com --scopes admin:public_key
        gh ssh-key add "$Key.pub" --title $env:COMPUTERNAME
    }
}

# Switch this repo's remote to SSH now that pushing works.
$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$Url = git -C $RepoRoot remote get-url origin
if ($Url -like 'https://github.com/*') {
    git -C $RepoRoot remote set-url origin ($Url -replace '^https://github\.com/', 'git@github.com:')
    Write-Host "Switched winit remote to SSH"
}
