# Initialise Windows

Scripts to init Windows.

## New machine

Open a regular (non-admin) PowerShell and run:

```Powershell
iwr -useb https://raw.githubusercontent.com/tomeo/winit/master/bootstrap.ps1 | iex
```

This installs scoop and git, clones the repo to ~/code/winit and runs scripts/init.ps1. The flow:

1. Any missing input (git e-mail and name) is asked for upfront.
2. Everything then runs unattended, apart from two things: the GitHub SSH step opens a browser for gh auth on the first run, and there is one UAC prompt at the end for the elevated steps (WSL and the caps lock remap).
3. Reboot when it finishes.

The whole thing is safe to re-run: already installed apps are skipped (including apps winget can't see because they were installed via scoop), config steps are idempotent, and the current Windows Terminal settings are backed up to settings.json.bak before being overwritten.

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
./scripts/configure-github-ssh.ps1
./scripts/configure-dotfiles.ps1
./scripts/configure-windows-terminal.ps1
./scripts/configure-explorer.ps1
./scripts/set-keyboard-layouts.ps1
./scripts/set-default-browser.ps1
./scripts/install-wsl.ps1
./scripts/remap-caps-lock-to-ctrl.ps1
```

Notes:

* Don't use an elevated shell for the scoop scripts, the scoop installer refuses to run as admin.
* install-wsl.ps1 and remap-caps-lock-to-ctrl.ps1 need an elevated shell (init.ps1 runs them via sudo).
* install-nodejs.ps1 must run before install-vscode.ps1 (the settings script runs on node).
* remap-caps-lock-to-ctrl.ps1 requires a reboot to take effect.

## Maintenance

* ./scripts/check-drift.ps1 compares what is actually installed (scoop, npm, VS Code extensions, winget) with what the scripts install and reports the diff. Run it now and then to keep the scripts honest.
* ./scripts/update-all.ps1 updates everything the scripts manage: scoop apps, winget apps, global npm packages and VS Code extensions.
