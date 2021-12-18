# Initialise Windows

Scripts to init Windows.

## Prereqs

```Powershell
Set-ExecutionPolicy AllSigned
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
```

## Run initialise

Open PowerShell as administrator:
```Powershell
./scripts/remap-caps-lock-to-ctrl.ps1
./scripts/set-keyboard-layouts.ps1
./scripts/install-scoop.ps1
./scripts/install-fonts.ps1
./scripts/configure-git.ps1
./scripts/configure-windows-terminal.ps1
./scripts/install-apps.ps1
./scripts/install-vscode.ps1
```
