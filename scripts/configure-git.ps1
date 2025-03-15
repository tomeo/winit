# Check if Git user email is already set
$Email = git config --global user.email
$FullName = git config --global user.name

if (-not $Email) {
    $Email = Read-Host -Prompt 'Git e-mail'
    git config --global user.email $Email
} else {
    Write-Host "Git e-mail is already set to: $Email"
}

if (-not $FullName) {
    $FullName = Read-Host -Prompt 'Git full name'
    git config --global user.name $FullName
} else {
    Write-Host "Git full name is already set to: $FullName"
}

git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit"
git config --global alias.lola "log --graph --decorate --pretty=oneline --abbrev-commit --all"
git config --global alias.cs "! TMPFILE=`$(mktemp /tmp/git-commit-status-message.XXX); git status --porcelain | grep '^[MARCDT]' | sort | sed -re 's/^([[:upper:]])[[:upper:]]?[[:space:]]+/\1:\n/' | awk '!x[`$0]++' | sed -re 's/^([[:upper:]]:)`$/\n\1/' | sed -re 's/^M:`$/Modified: /' | sed -re 's/^A:`$/Added: /' | sed -re 's/^R:`$/Renamed: /' | sed -re 's/^C:`$/Copied: /' | sed -re 's/^D:`$/Deleted: /' | sed -re 's/^T:`$/File Type Changed: /' | xargs > `$TMPFILE; git commit -F `$TMPFILE; rm -f `$TMPFILE"
git config --global alias.stats "shortlog -s -n --all"
git config --global fetch.prune true
git config --global init.defaultBranch master
git config --global core.excludesfile ~/.gitignore
git config --global core.autocrlf true
git config --global core.safecrlf false
Add-Content -Path $env:USERPROFILE/.gitignore -Value '.hidden'

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

Write-Host "Git has been configured successfully!" -ForegroundColor Green