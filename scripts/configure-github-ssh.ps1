# Sets up SSH auth against GitHub: generates a key if missing, authenticates
# gh (opens a browser on first run), uploads the key and switches this repo's
# remote to SSH. Safe to re-run: it starts by asking GitHub whether SSH already
# works and does nothing if it does, so a machine that authenticates with some
# other key does not get a second one.
param([string]$Email)

if (-not $Email) { $Email = git config --global user.email }

$SshDir = "$env:USERPROFILE\.ssh"
$Key = "$SshDir\id_ed25519"
New-Item -ItemType Directory -Force $SshDir | Out-Null

# Whether GitHub accepts an existing key, whichever one ssh picks. GitHub denies
# shell access even on success, so the exit code says nothing: match the greeting.
# accept-new records the host key so a first run never stops on a yes/no prompt.
function Test-GitHubSsh {
    # A denied login writes to stderr, which 2>&1 turns into error records, so
    # keep the caller's ErrorActionPreference from making that terminate us.
    $ErrorActionPreference = 'Continue'
    $Reply = ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | Out-String
    return $Reply -match 'successfully authenticated'
}

$AlreadyWorking = Test-GitHubSsh
if ($AlreadyWorking) {
    Write-Host "SSH auth against GitHub already works, nothing to set up"
} elseif (Test-Path $Key) {
    Write-Host "SSH key already exists, skipping keygen"
} else {
    # Windows PowerShell, and pwsh in Legacy mode, drop '' when passing it to a
    # native exe, which leaves -N without its argument. Quote it explicitly there.
    $NoPassphrase = if ($PSNativeCommandArgumentPassing -eq 'Standard') { '' } else { '""' }
    ssh-keygen -t ed25519 -C $Email -f $Key -N $NoPassphrase
    if (-not (Test-Path $Key)) { throw "ssh-keygen did not produce $Key" }
}

if (-not $AlreadyWorking) {
    $null = gh auth status
    if ($LASTEXITCODE -ne 0) {
        # Ask for admin:public_key upfront: the default token lacks it, and adding
        # it afterwards costs a second round of the interactive device flow.
        gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key
    }

    # Upload the public key unless it is already on the account.
    $KeyMaterial = ((Get-Content "$Key.pub") -split ' ')[1]
    $Existing = gh ssh-key list
    if ($Existing -match [regex]::Escape($KeyMaterial)) {
        Write-Host "SSH key is already on GitHub, skipping upload"
    } else {
        gh ssh-key add "$Key.pub" --title $env:COMPUTERNAME
        if ($LASTEXITCODE -ne 0) {
            # Safety net for machines already logged in with a narrower token.
            gh auth refresh --hostname github.com --scopes admin:public_key
            gh ssh-key add "$Key.pub" --title $env:COMPUTERNAME
        }
    }

    if (-not (Test-GitHubSsh)) { throw "SSH auth against GitHub still fails after setup" }
    Write-Host "SSH auth against GitHub verified"
}

# Switch this repo's remote to SSH now that pushing works.
$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$Url = git -C $RepoRoot remote get-url origin
if ($Url -like 'https://github.com/*') {
    git -C $RepoRoot remote set-url origin ($Url -replace '^https://github\.com/', 'git@github.com:')
    Write-Host "Switched winit remote to SSH"
}
