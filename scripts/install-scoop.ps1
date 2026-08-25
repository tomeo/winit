# Installs scoop, git, sudo and the extras/versions buckets.
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    iwr -useb get.scoop.sh | iex
}
scoop install git
scoop install sudo
scoop bucket add extras
scoop bucket add versions
