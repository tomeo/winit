# Clones repos from your GitHub account into ~\code, letting you pick which ones.
# Lists every repo, marks the ones already cloned, then takes a selection like
# "1,4,9-12" or "all". Safe to re-run: repos already on disk are left alone.
# -Pick skips the prompt, so ./clone-repos.ps1 -Pick all runs unattended.
param(
    [string]$Owner,
    [string]$Root = "$env:USERPROFILE\code",
    [string]$Pick,
    [int]$Limit = 200
)

$null = gh auth status
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Not logged in to GitHub. Run ./configure-github-ssh.ps1 first.' -ForegroundColor Yellow
    return
}

# gh clones with the protocol it is configured for, which configure-github-ssh
# sets to ssh, so private repos work without a second credential prompt.
$OwnerArg = if ($Owner) { @($Owner) } else { @() }
# ConvertFrom-Json sends the whole array down the pipeline as a single object
# in Windows PowerShell, so capture it before sorting.
$Json = gh repo list @OwnerArg --limit $Limit --json name,nameWithOwner,isPrivate,updatedAt | ConvertFrom-Json
$Repos = @($Json | Sort-Object name)
if (-not $Repos) {
    Write-Host 'No repos found.' -ForegroundColor Yellow
    return
}

Write-Host ""
for ($i = 0; $i -lt $Repos.Count; $i++) {
    $Repo = $Repos[$i]
    $Repo | Add-Member -NotePropertyName Target -NotePropertyValue (Join-Path $Root $Repo.name)
    $Visibility = if ($Repo.isPrivate) { 'private' } else { 'public' }
    $Updated = ([datetime]$Repo.updatedAt).ToString('yyyy-MM-dd')
    Write-Host ("{0,3}. " -f ($i + 1)) -NoNewline
    Write-Host ("{0,-40}" -f $Repo.name) -NoNewline
    Write-Host ("{0,-8} {1}  " -f $Visibility, $Updated) -NoNewline -ForegroundColor DarkGray
    if (Test-Path $Repo.Target) { Write-Host 'cloned' -ForegroundColor Green } else { Write-Host '' }
}

Write-Host ""
if (-not $Pick) {
    $Pick = Read-Host 'Clone which? (e.g. 1,4,9-12 or all, blank to quit)'
}
if (-not $Pick) { return }

# Expand "1,4,9-12" and "all" into a sorted set of list positions.
$Wanted = @()
if ($Pick.Trim() -eq 'all') {
    $Wanted = 1..$Repos.Count
} else {
    foreach ($Part in ($Pick -split '[,\s]+' | Where-Object { $_ })) {
        if ($Part -match '^(\d+)-(\d+)$') {
            $Wanted += [int]$Matches[1]..[int]$Matches[2]
        } elseif ($Part -match '^\d+$') {
            $Wanted += [int]$Part
        } else {
            Write-Host "Ignoring '$Part', not a number or range." -ForegroundColor Yellow
        }
    }
}
$Wanted = @($Wanted | Sort-Object -Unique | Where-Object { $_ -ge 1 -and $_ -le $Repos.Count })
if (-not $Wanted) {
    Write-Host 'Nothing selected.' -ForegroundColor Yellow
    return
}

New-Item -ItemType Directory -Force $Root | Out-Null
$Cloned = 0
$Failed = @()
foreach ($Number in $Wanted) {
    $Repo = $Repos[$Number - 1]
    if (Test-Path $Repo.Target) {
        Write-Host "$($Repo.name) is already cloned, skipping"
        continue
    }
    Write-Host "Cloning $($Repo.nameWithOwner)" -ForegroundColor Cyan
    gh repo clone $Repo.nameWithOwner $Repo.Target
    if ($LASTEXITCODE -eq 0) { $Cloned++ } else { $Failed += $Repo.name }
}

Write-Host ""
Write-Host "$Cloned repo(s) cloned into $Root."
if ($Failed) { Write-Host "Failed: $($Failed -join ', ')" -ForegroundColor Yellow }
