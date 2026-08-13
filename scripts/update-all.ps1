# Updates everything the install scripts manage.
scoop update
scoop update *
winget upgrade --all --accept-source-agreements --accept-package-agreements
npm update -g
code --update-extensions
