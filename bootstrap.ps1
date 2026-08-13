# Bootstraps a fresh Windows machine.
# Run in a regular (non-admin) PowerShell:
#   iwr -useb https://raw.githubusercontent.com/tomeo/winit/master/bootstrap.ps1 | iex

try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch {}

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    iwr -useb get.scoop.sh | iex
}
scoop install git
scoop bucket add extras
scoop bucket add versions

$repo = "$env:USERPROFILE\code\winit"
if (Test-Path $repo) {
    git -C $repo pull
} else {
    git clone https://github.com/tomeo/winit.git $repo
}

& "$repo\scripts\init.ps1"
