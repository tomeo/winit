# Initialise Windows

Scripts to init Windows.

## New machine

Open a regular (non-admin) PowerShell and run:

```Powershell
iwr -useb https://raw.githubusercontent.com/tomeo/winit/master/bootstrap.ps1 | iex
```

This installs scoop and git, clones the repo to ~/code/winit and runs scripts/init.ps1, which runs everything below in order. Expect UAC prompts for the elevated steps (global fonts, WSL, caps lock remap) and interactive prompts from configure-git.ps1. Reboot when it finishes.

## Run scripts individually

The scripts can also be run one by one from a regular (non-admin) PowerShell, in this order:

```Powershell
./scripts/install-scoop.ps1
./scripts/install-apps-scoop.ps1
./scripts/install-apps-winget.ps1
./scripts/install-fonts.ps1
./scripts/install-nodejs.ps1
./scripts/install-vscode.ps1
./scripts/configure-git.ps1
./scripts/configure-windows-terminal.ps1
./scripts/set-keyboard-layouts.ps1
./scripts/install-wsl.ps1
./scripts/remap-caps-lock-to-ctrl.ps1
```

Notes:

* Don't use an elevated shell for the scoop scripts, the scoop installer refuses to run as admin.
* install-wsl.ps1 and remap-caps-lock-to-ctrl.ps1 need an elevated shell (init.ps1 runs them via sudo).
* install-fonts.ps1 must run before configure-windows-terminal.ps1 (the terminal profile uses FiraCode Nerd Font).
* install-nodejs.ps1 must run before install-vscode.ps1 (the settings script runs on node).
* remap-caps-lock-to-ctrl.ps1 requires a reboot to take effect.
