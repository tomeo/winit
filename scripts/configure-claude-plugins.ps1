# Installs Claude Code plugins from Anthropic's official marketplace in user
# scope, so every repo on the machine has them:
# - pyright-lsp and typescript-lsp give the agent type errors, go-to-definition
#   and find-references instead of grep. They only wire the language servers up;
#   the servers themselves are npm packages that install-nodejs.ps1 installs.
# - microsoft-docs looks things up in Microsoft Learn, which covers Graph.
# Safe to re-run: an installed plugin is left alone. -Remove uninstalls them.
param([switch]$Remove)

$Marketplace = 'claude-plugins-official'
$MarketplaceSource = 'anthropics/claude-plugins-official'
$Plugins = @('pyright-lsp', 'typescript-lsp', 'microsoft-docs')

# claude.cmd first, for the same reason as in configure-claude-mcp.ps1: the
# claude.ps1 shim mangles arguments on the way through.
$Claude = 'claude.cmd'
if (-not (Get-Command $Claude -ErrorAction SilentlyContinue)) {
    $Claude = 'claude'
    if (-not (Get-Command $Claude -ErrorAction SilentlyContinue)) {
        throw 'Claude Code is not installed, run ./install-nodejs.ps1 first.'
    }
}

function Get-InstalledIds {
    $Json = & $Claude plugin list --json | Out-String
    if ($LASTEXITCODE -ne 0) { throw "claude plugin list failed with exit code $LASTEXITCODE." }
    return @(($Json | ConvertFrom-Json) | ForEach-Object { $_.id })
}

$Installed = Get-InstalledIds

if ($Remove) {
    foreach ($Plugin in $Plugins) {
        $Id = "$Plugin@$Marketplace"
        if ($Installed -notcontains $Id) {
            Write-Host "$Id is not installed, nothing to remove."
            continue
        }
        & $Claude plugin uninstall $Id
        if ($LASTEXITCODE -ne 0) { throw "claude plugin uninstall $Id failed with exit code $LASTEXITCODE." }
    }
    return
}

# A fresh Claude Code normally knows the official marketplace already, but add
# it if it is missing rather than failing on every install below.
$Marketplaces = & $Claude plugin marketplace list | Out-String
if ($Marketplaces -notmatch [regex]::Escape($Marketplace)) {
    & $Claude plugin marketplace add $MarketplaceSource
    if ($LASTEXITCODE -ne 0) { throw "claude plugin marketplace add failed with exit code $LASTEXITCODE." }
}

foreach ($Plugin in $Plugins) {
    $Id = "$Plugin@$Marketplace"
    if ($Installed -contains $Id) {
        Write-Host "$Id is already installed, skipping."
        continue
    }
    & $Claude plugin install $Id
    if ($LASTEXITCODE -ne 0) { throw "claude plugin install $Id failed with exit code $LASTEXITCODE." }
}

Write-Host 'New Claude Code sessions pick the plugins up.'
