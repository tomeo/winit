# Initialise Windows

Scripts to init Windows.

## New machine

Open a regular (non-admin) PowerShell and run:

```Powershell
iwr -useb https://raw.githubusercontent.com/tomeo/winit/master/bootstrap.ps1 | iex
```

This installs scoop and git, clones the repo to ~/code/tomeo/winit and runs scripts/init.ps1. The flow:

1. Any missing input (git e-mail and name) is asked for upfront.
2. Everything then runs unattended, apart from three things: the GitHub SSH step opens a browser for gh auth on the first run, the Teams background step opens one for az login if the Azure CLI has no session, and there is one UAC prompt at the end for the elevated steps (WSL, the caps lock remap and switching off Windows Hello face).
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
./scripts/configure-claude-mcp.ps1
./scripts/install-vscode.ps1
./scripts/configure-git.ps1
./scripts/configure-github-ssh.ps1
./scripts/configure-dotfiles.ps1
./scripts/configure-windows-terminal.ps1
./scripts/configure-explorer.ps1
./scripts/configure-taskbar.ps1
./scripts/set-keyboard-layouts.ps1
./scripts/set-default-browser.ps1
./scripts/set-power-and-lock.ps1
./scripts/get-teams-background.ps1
./scripts/install-wsl.ps1
./scripts/remap-caps-lock-to-ctrl.ps1
./scripts/disable-hello-face.ps1
```

Notes:

* Don't use an elevated shell for the scoop scripts, the scoop installer refuses to run as admin.
* install-wsl.ps1, remap-caps-lock-to-ctrl.ps1 and disable-hello-face.ps1 need elevation (init.ps1 runs them via sudo in one go; disable-hello-face.ps1 also sudo's itself when run from a regular shell).
* get-teams-background.ps1 downloads the Teams background image to %LOCALAPPDATA%\winit\teams-background and stops there, because the upload into Teams cannot be scripted: build 26213 keeps custom backgrounds in the service, which makes the local Backgrounds\Uploads folder a download cache rather than a drop folder, and every authz endpoint that used to mint a token for the upload API now answers 410. Upload the file once under More > Video effects and settings > Add new and the service roams it to every machine, so it is one upload per account rather than per machine. The script only does anything when the machine is signed in as the work account the image belongs to (its -Upn default); on any other account it says so and skips. The image itself is not in this repo, which is public, but fetched from SharePoint on each run. -Open opens Explorer with the downloaded file selected.
* install-nodejs.ps1 must run before install-vscode.ps1 (the settings script runs on node).
* configure-claude-mcp.ps1 registers the Chrome DevTools MCP server with Claude Code in user scope, which gives every repo on the machine a browser to drive; the web-perf skill cannot run without it. The server has to be registered as chrome-devtools, because that is the name the skill's tool calls resolve to. It runs after install-nodejs.ps1, which installs the claude CLI it needs. -Remove unregisters it again.
* remap-caps-lock-to-ctrl.ps1 requires a reboot to take effect.
* disable-hello-face.ps1 takes the camera out of Windows Hello so sign-in is PIN and password. It disables only the face recognition unit (a software device on top of the IR camera), so the normal camera keeps working in Teams and the fingerprint reader is untouched. The face enrolment stays in the biometric database, so -Revert re-enables the device and face sign-in is back without setting it up again.
* configure-taskbar.ps1 hides the search box, task view, chat and copilot buttons and unpins everything from the taskbar, leaving Start and the running apps. It restarts Explorer to apply, and backs the old taskbar up to %LOCALAPPDATA%\winit\taskbar first, so -Revert puts the pins and buttons back. Widgets is left alone: Windows 11 25H2 refuses writes to TaskbarDa, so the only way to hide that button is the machine-wide policy.
* set-power-and-lock.ps1 stops the machine from sleeping on AC and locks it after 5 minutes idle instead, so background jobs survive an idle lunch. -LockAfterMinutes changes the delay, -Revert undoes it. Battery is left alone.

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
