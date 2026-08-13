# Runs all scripts in order. Normally invoked by ../bootstrap.ps1,
# but can be run on its own from a regular (non-admin) PowerShell.
Push-Location $PSScriptRoot

# Gather all input upfront so the rest of the run is unattended.
$GitEmail = git config --global user.email
if (-not $GitEmail) { $GitEmail = Read-Host -Prompt 'Git e-mail' }
$GitFullName = git config --global user.name
if (-not $GitFullName) { $GitFullName = Read-Host -Prompt 'Git full name' }

$Failed = @()
function Invoke-Step {
    param([string]$Title, [scriptblock]$Action)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    try {
        & $Action
    } catch {
        Write-Host $_ -ForegroundColor Red
        $script:Failed += $Title
    }
}

Invoke-Step 'Scoop, buckets and sudo'   { ./install-scoop.ps1 }
Invoke-Step 'CLI and dev tools (scoop)' { ./install-apps-scoop.ps1 }
Invoke-Step 'Apps (winget)'             { ./install-apps-winget.ps1 }
Invoke-Step 'Fonts'                     { ./install-fonts.ps1 }
Invoke-Step 'Node.js and npm packages'  { ./install-nodejs.ps1 }
Invoke-Step 'VS Code'                   { ./install-vscode.ps1 }
Invoke-Step 'Git config'                { ./configure-git.ps1 -Email $GitEmail -FullName $GitFullName }
Invoke-Step 'GitHub SSH'                { ./configure-github-ssh.ps1 -Email $GitEmail }
Invoke-Step 'Dotfiles'                  { ./configure-dotfiles.ps1 }
Invoke-Step 'Windows Terminal config'   { ./configure-windows-terminal.ps1 }
Invoke-Step 'Explorer settings'         { ./configure-explorer.ps1 }
Invoke-Step 'Keyboard layouts'          { ./set-keyboard-layouts.ps1 }

# The steps that need elevation run in one go: a single UAC prompt.
Invoke-Step 'WSL and caps lock remap (elevated)' {
    sudo powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$PSScriptRoot\install-wsl.ps1'; & '$PSScriptRoot\remap-caps-lock-to-ctrl.ps1'"
}

Pop-Location
Write-Host ""
if ($Failed) {
    Write-Host "Done, but these steps reported errors: $($Failed -join ', ')" -ForegroundColor Yellow
} else {
    Write-Host "Done. Reboot to apply the caps lock remap and finish the WSL install." -ForegroundColor Green
}
