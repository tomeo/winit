# Numbered menu of all scripts in this folder: lists each one with the
# description from its first comment line, then runs the one you pick.
# Pass a number to skip the prompt: ./menu.ps1 5. Scripts run with their defaults.
param([int]$Number = 0)

$All = Get-ChildItem $PSScriptRoot -Filter '*.ps1' |
    Where-Object { $_.Name -ne 'menu.ps1' } |
    Sort-Object Name
$Groups = [ordered]@{
    'Maintenance (recurring)'          = @($All | Where-Object { $_.Name -match '^(check|clean|update)-' })
    'Setup (one-time, safe to re-run)' = @($All | Where-Object { $_.Name -notmatch '^(check|clean|update)-' })
}

$Scripts = @()
foreach ($Group in $Groups.GetEnumerator()) {
    Write-Host ""
    Write-Host "=== $($Group.Key) ===" -ForegroundColor Cyan
    foreach ($Script in $Group.Value) {
        $Scripts += $Script
        $FirstLine = Get-Content $Script.FullName -TotalCount 1
        $Description = if ($FirstLine -like '#*') { $FirstLine -replace '^#\s*', '' } else { '' }
        Write-Host ("{0,3}. " -f $Scripts.Count) -NoNewline
        Write-Host ("{0,-28}" -f $Script.BaseName) -NoNewline
        Write-Host $Description -ForegroundColor DarkGray
    }
}

Write-Host ""
if (-not $Number) {
    $Answer = Read-Host 'Run which script? (number, blank to quit)'
    if ($Answer -notmatch '^\d+$') { return }
    $Number = [int]$Answer
}
if ($Number -lt 1 -or $Number -gt $Scripts.Count) {
    Write-Host "No script with number $Number." -ForegroundColor Yellow
    return
}

$Chosen = $Scripts[$Number - 1]
Write-Host "=== $($Chosen.BaseName) ===" -ForegroundColor Cyan
& $Chosen.FullName
