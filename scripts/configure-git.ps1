# Sets git identity, aliases, global gitignore and diff-so-fancy config.
param(
    [string]$Email,
    [string]$FullName
)

# Resolve identity: parameter, then existing config, then prompt.
if (-not $Email) { $Email = git config --global user.email }
if (-not $Email) { $Email = Read-Host -Prompt 'Git e-mail' }
if (-not $FullName) { $FullName = git config --global user.name }
if (-not $FullName) { $FullName = Read-Host -Prompt 'Git full name' }

git config --global user.email $Email
git config --global user.name $FullName

git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit"
git config --global alias.lola "log --graph --decorate --pretty=oneline --abbrev-commit --all"
git config --global alias.cs "! TMPFILE=`$(mktemp /tmp/git-commit-status-message.XXX); git status --porcelain | grep '^[MARCDT]' | sort | sed -re 's/^([[:upper:]])[[:upper:]]?[[:space:]]+/\1:\n/' | awk '!x[`$0]++' | sed -re 's/^([[:upper:]]:)`$/\n\1/' | sed -re 's/^M:`$/Modified: /' | sed -re 's/^A:`$/Added: /' | sed -re 's/^R:`$/Renamed: /' | sed -re 's/^C:`$/Copied: /' | sed -re 's/^D:`$/Deleted: /' | sed -re 's/^T:`$/File Type Changed: /' | xargs > `$TMPFILE; git commit -F `$TMPFILE; rm -f `$TMPFILE"
git config --global alias.yolo --% "!f() { git add . && git commit -m \"${1:-updates}\" && git push origin HEAD; }; f"
git config --global alias.stats "shortlog -s -n --all"
git config --global fetch.prune true
git config --global init.defaultBranch main
git config --global core.autocrlf true
git config --global core.safecrlf false

# Global gitignore: .hidden dirs are ignored everywhere. Only add the line once.
git config --global core.excludesfile ~/.gitignore
$GitignorePath = "$env:USERPROFILE\.gitignore"
if (-not (Test-Path $GitignorePath) -or -not (Select-String -Path $GitignorePath -Pattern '^\.hidden$' -Quiet)) {
    Add-Content -Path $GitignorePath -Value '.hidden'
}

# diff so fancy
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
git config --global interactive.diffFilter "diff-so-fancy --patch"
git config --global color.ui true

# Color Settings for better visibility
git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "yellow bold"
git config --global color.diff.frag       "yellow bold"
git config --global color.diff.func       "blue bold"
git config --global color.diff.commit     "cyan bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"

Write-Host "Git configured for $FullName <$Email>" -ForegroundColor Green
