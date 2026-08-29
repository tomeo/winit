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

## Re-run

From an existing clone, the same script pulls the latest version and runs the whole setup again:

```Powershell
./bootstrap.ps1
```

Everything skips what is already in place, so a re-run only fixes what has drifted.

## Run scripts individually

./scripts/menu.ps1 shows a numbered menu of all scripts with their descriptions and runs the one you pick (./scripts/menu.ps1 5 runs number 5 directly).

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

## Clone your repos

./scripts/clone-repos.ps1 lists every repo on your GitHub account, marks the ones already cloned, and clones the ones you pick into ~/code:

```Powershell
./scripts/clone-repos.ps1
```

Pick by number, with commas and ranges (1,4,9-12), or all. -Pick takes the same string without prompting, -Owner lists another account's repos, and -Root clones somewhere other than ~/code. Repos already on disk are skipped, so it is safe to re-run.

It is deliberately not part of init.ps1: which repos you want differs per machine. It clones over SSH, so run configure-github-ssh.ps1 first.

## Maintenance

* ./scripts/check-drift.ps1 compares what is actually installed (scoop, npm, VS Code extensions, winget) with what the scripts install and reports the diff. Run it now and then to keep the scripts honest.
* ./scripts/update-all.ps1 updates everything the scripts manage: scoop apps, winget apps, global npm packages and VS Code extensions.
* ./scripts/clean-all.ps1 runs all the clean scripts below in one go.
* ./scripts/clean-desktop.ps1 removes shortcuts (.lnk/.url) that installers drop on the desktop, including the public desktop (one sudo prompt, only when needed). Real files and folders are left alone.
* ./scripts/clean-downloads.ps1 moves everything in Downloads older than 30 days (-OlderThanDays to change) to the Recycle Bin, so it can be undone.
* ./scripts/clean-caches.ps1 reclaims disk space from the scoop, npm and pip caches, old scoop app versions, and %TEMP% files older than a week.
