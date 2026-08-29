# Clones GitHub repos into ~\code\<owner>, letting you pick the owner and the
# repos. First asks whether to list your own repos or one of your orgs', then
# lists them, marks the ones already cloned and takes a selection like
# "1,4,9-12" or "all". Grouping by owner keeps same-named repos from different
# owners apart. Safe to re-run: repos already on disk are left alone, including
# ones cloned straight into ~\code before this script grouped them by owner.
# -Owner and -Pick skip the prompts, so -Owner Vartex-AB -Pick all is unattended.
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

# Which account to list: your own, or one of the orgs you belong to. Asked only
# when -Owner was not passed, and skipped entirely when you are in no orgs.
if (-not $Owner) {
    $Login = gh api user --jq .login
    if (-not $Login) {
        Write-Host 'Could not read your GitHub login. Pass -Owner instead.' -ForegroundColor Yellow
        return
    }
    # read:org is missing from gh's default token on some machines, so treat a
    # failed lookup as "no orgs" rather than stopping the script.
    $Orgs = @(gh api user/orgs --jq '.[].login' 2>$null)
    if ($LASTEXITCODE -ne 0) { $Orgs = @() }

    if ($Orgs) {
        $Owners = @($Login) + $Orgs
        Write-Host ""
        for ($i = 0; $i -lt $Owners.Count; $i++) {
            Write-Host ("{0,3}. " -f ($i + 1)) -NoNewline
            Write-Host ("{0,-40}" -f $Owners[$i]) -NoNewline
            if ($i -eq 0) { Write-Host 'your own repos' -ForegroundColor DarkGray }
            else { Write-Host 'organisation' -ForegroundColor DarkGray }
        }
        Write-Host ""
        $Answer = Read-Host "Repos from which owner? (number, blank for $Login)"
        if ($Answer -match '^\d+$' -and [int]$Answer -ge 1 -and [int]$Answer -le $Owners.Count) {
            $Owner = $Owners[[int]$Answer - 1]
        } elseif ($Answer) {
            Write-Host "No owner with number $Answer, listing $Login instead." -ForegroundColor Yellow
        }
    }
    # Listing your own login shows the same repos, private ones included, as
    # listing no owner at all, so from here on $Owner is always set.
    if (-not $Owner) { $Owner = $Login }
}

# gh clones with the protocol it is configured for, which configure-github-ssh
# sets to ssh, so private repos work without a second credential prompt.
# ConvertFrom-Json sends the whole array down the pipeline as a single object
# in Windows PowerShell, so capture it before sorting.
$Json = gh repo list $Owner --limit $Limit --json name,nameWithOwner,isPrivate,updatedAt | ConvertFrom-Json
$Repos = @($Json | Sort-Object name)
if (-not $Repos) {
    Write-Host "No repos found for $Owner." -ForegroundColor Yellow
    return
}

# Where a repo would go, and where an earlier run may already have put it. Repos
# cloned before this script grouped them by owner sit directly under $Root, so
# accept one of those as the existing checkout when its origin matches, rather
# than cloning a second copy under the owner folder.
$OwnerRoot = Join-Path $Root $Owner
function Find-ExistingClone {
    param($Repo)
    if (Test-Path $Repo.Target) { return $Repo.Target }
    $Flat = Join-Path $Root $Repo.name
    if (Test-Path (Join-Path $Flat '.git')) {
        $Url = git -C $Flat remote get-url origin 2>$null
        if ($Url -like "*$($Repo.nameWithOwner)*") { return $Flat }
    }
    return $null
}

Write-Host ""
Write-Host "$($Repos.Count) repo(s) for $Owner" -ForegroundColor Cyan
for ($i = 0; $i -lt $Repos.Count; $i++) {
    $Repo = $Repos[$i]
    $Repo | Add-Member -NotePropertyName Target -NotePropertyValue (Join-Path $OwnerRoot $Repo.name)
    $Repo | Add-Member -NotePropertyName Existing -NotePropertyValue (Find-ExistingClone $Repo)
    $Visibility = if ($Repo.isPrivate) { 'private' } else { 'public' }
    $Updated = ([datetime]$Repo.updatedAt).ToString('yyyy-MM-dd')
    Write-Host ("{0,3}. " -f ($i + 1)) -NoNewline
    Write-Host ("{0,-40}" -f $Repo.name) -NoNewline
    Write-Host ("{0,-8} {1}  " -f $Visibility, $Updated) -NoNewline -ForegroundColor DarkGray
    if (-not $Repo.Existing) { Write-Host '' }
    elseif ($Repo.Existing -eq $Repo.Target) { Write-Host 'cloned' -ForegroundColor Green }
    else { Write-Host "cloned in $(Split-Path $Repo.Existing -Parent)" -ForegroundColor Green }
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

New-Item -ItemType Directory -Force $OwnerRoot | Out-Null
$Cloned = 0
$Failed = @()
foreach ($Number in $Wanted) {
    $Repo = $Repos[$Number - 1]
    if ($Repo.Existing) {
        Write-Host "$($Repo.name) is already cloned at $($Repo.Existing), skipping"
        continue
    }
    Write-Host "Cloning $($Repo.nameWithOwner)" -ForegroundColor Cyan
    gh repo clone $Repo.nameWithOwner $Repo.Target
    if ($LASTEXITCODE -eq 0) { $Cloned++ } else { $Failed += $Repo.name }
}

Write-Host ""
Write-Host "$Cloned repo(s) cloned into $OwnerRoot."
if ($Failed) { Write-Host "Failed: $($Failed -join ', ')" -ForegroundColor Yellow }
