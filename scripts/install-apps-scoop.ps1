# CLI and dev tools. GUI apps are installed via install-apps-winget.ps1.
scoop install 7zip
scoop install jq
scoop install pandoc
scoop install go
scoop install terraform
scoop install postgresql
scoop install dbmate
scoop install python
scoop install versions/python312
scoop install bind
scoop install telnet

# Kept on scoop on purpose: configure-windows-terminal.ps1 copies settings.json
# into the scoop install's settings directory.
scoop install windows-terminal
