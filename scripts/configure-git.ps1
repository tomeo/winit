$Email = Read-Host -Prompt 'Git e-mail'
$FullName = Read-Host -Prompt 'Git full name'

git config --global user.email $Email
git config --global user.name $FullName

git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit"
git config --global alias.lola "log --graph --decorate --pretty=oneline --abbrev-commit --all"
git config --global alias.cs "! TMPFILE=`$(mktemp /tmp/git-commit-status-message.XXX); git status --porcelain | grep '^[MARCDT]' | sort | sed -re 's/^([[:upper:]])[[:upper:]]?[[:space:]]+/\1:\n/' | awk '!x[`$0]++' | sed -re 's/^([[:upper:]]:)`$/\n\1/' | sed -re 's/^M:`$/Modified: /' | sed -re 's/^A:`$/Added: /' | sed -re 's/^R:`$/Renamed: /' | sed -re 's/^C:`$/Copied: /' | sed -re 's/^D:`$/Deleted: /' | sed -re 's/^T:`$/File Type Changed: /' | xargs > `$TMPFILE; git commit -F `$TMPFILE; rm -f `$TMPFILE"
git config --global fetch.prune true
git config --global init.defaultBranch master
git config --global core.excludesfile ~/.gitignore
Add-Content -Path $env:USERPROFILE/.gitignore -Value '.hidden'