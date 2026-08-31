# Bootstraps a fresh Windows machine, or re-runs the setup from a local clone.
# Fresh machine, in a regular (non-admin) PowerShell:
#   iwr -useb https://raw.githubusercontent.com/tomeo/winit/master/bootstrap.ps1 | iex
# Already cloned: ./bootstrap.ps1 from the repo.

try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch {}

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    iwr -useb get.scoop.sh | iex
}
scoop install git
scoop bucket add extras
scoop bucket add versions

# $PSScriptRoot is only set when run as a file, i.e. from a local clone.
if ($PSScriptRoot) {
    $repo = $PSScriptRoot
    git -C $repo pull
} else {
    $repo = "$env:USERPROFILE\code\tomeo\winit"
    if (Test-Path $repo) {
        git -C $repo pull
    } else {
        git clone https://github.com/tomeo/winit.git $repo
    }
}

& "$repo\scripts\init.ps1"
