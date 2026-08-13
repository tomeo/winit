# Compares what is actually installed with what the scripts install.
# Read-only. Run it now and then to keep the scripts honest.
$ScriptFiles = Get-ChildItem $PSScriptRoot -Filter '*.ps1' |
    Where-Object { $_.Name -ne 'check-drift.ps1' } |
    Select-Object -ExpandProperty FullName

function Get-Scripted {
    param([string]$Pattern)
    Select-String -Path $ScriptFiles -Pattern $Pattern | ForEach-Object { $_.Matches[0].Groups[1].Value }
}

function Show-Drift {
    param([string]$Title, [string[]]$Installed, [string[]]$Scripted)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    $Installed = @($Installed | Where-Object { $_ } | ForEach-Object { $_.ToLower() })
    $Scripted = @($Scripted | Where-Object { $_ } | ForEach-Object { $_.ToLower() })
    $NotScripted = @($Installed | Where-Object { $Scripted -notcontains $_ })
    $NotInstalled = @($Scripted | Where-Object { $Installed -notcontains $_ })
    if ($NotScripted) {
        Write-Host 'Installed but not in scripts:' -ForegroundColor Yellow
        $NotScripted | ForEach-Object { Write-Host "  $_" }
    }
    if ($NotInstalled) {
        Write-Host 'In scripts but not installed:' -ForegroundColor Yellow
        $NotInstalled | ForEach-Object { Write-Host "  $_" }
    }
    if (-not $NotScripted -and -not $NotInstalled) {
        Write-Host 'In sync' -ForegroundColor Green
    }
}

# Scoop installs of apps the winget script covers count as scripted, but only
# when actually installed: missing ones are the winget section's job to report.
$WingetLines = Select-String -Path "$PSScriptRoot\install-apps-winget.ps1" -Pattern '^Install-App (\S+)(?: (\S+))?$'
$WingetScoopNames = $WingetLines | ForEach-Object { $_.Matches[0].Groups[2].Value } |
    Where-Object { $_ -and (Test-Path "$env:USERPROFILE\scoop\apps\$_") }

# Scoop. dark and innounp are auto-installed dependencies, not drift.
# The bucket prefix (versions/python312) is stripped before comparing.
$ScoopScripted = @(Get-Scripted 'scoop install (\S+)' | ForEach-Object { ($_ -split '/')[-1] }) + $WingetScoopNames
$ScoopInstalled = (scoop list).Name | Where-Object { $_ -notin 'dark', 'innounp' }
Show-Drift 'Scoop' $ScoopInstalled $ScoopScripted

# npm. npm itself ships with node.
$NpmDeps = (npm ls -g --depth=0 --json | ConvertFrom-Json).dependencies
$NpmInstalled = $NpmDeps.PSObject.Properties.Name | Where-Object { $_ -ne 'npm' }
Show-Drift 'npm (global)' $NpmInstalled (Get-Scripted 'npm i -g (\S+)')

# VS Code extensions.
Show-Drift 'VS Code extensions' (code --list-extensions) (Get-Scripted '--install-extension (\S+)')

# Winget is only checked one way: the installed list is too noisy (system
# components, runtimes) to diff against, so only missing apps are reported.
Write-Host ""
Write-Host '=== Winget (script side only) ===' -ForegroundColor Cyan
$MissingWinget = @()
foreach ($Line in $WingetLines) {
    $Id = $Line.Matches[0].Groups[1].Value
    $ScoopName = $Line.Matches[0].Groups[2].Value
    if ($ScoopName -and (Test-Path "$env:USERPROFILE\scoop\apps\$ScoopName")) { continue }
    $null = winget list -e --id $Id --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { $MissingWinget += $Id }
}
if ($MissingWinget) {
    Write-Host 'In script but not installed:' -ForegroundColor Yellow
    $MissingWinget | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host 'All script apps installed' -ForegroundColor Green
}
