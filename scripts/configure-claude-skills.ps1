# Installs third-party agent skills for Claude Code in user scope, so every repo
# on the machine has them. Today that is herdr's own skill, which teaches the
# agent to drive herdr (split panes, run commands, read output, start helper
# agents) from inside a herdr pane. It only triggers when herdr is mentioned and
# stops by itself when HERDR_ENV is not set, so it costs nothing outside herdr.
# Safe to re-run: an installed skill is left alone. -Update pulls the latest
# versions, -Remove takes them out again.
param([switch]$Update, [switch]$Remove)

# Source repo and skill name, as `npx skills add <repo> --skill <name>` takes them.
$Skills = @(
    @{ Repo = 'herdrdev/herdr'; Name = 'herdr' }
)

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw 'npx is not installed, run ./install-nodejs.ps1 first.'
}

$SkillsDir = Join-Path $HOME '.claude\skills'

foreach ($Skill in $Skills) {
    $Name = $Skill.Name
    $Installed = Test-Path (Join-Path $SkillsDir "$Name\SKILL.md")

    if ($Remove) {
        if (-not $Installed) {
            Write-Host "$Name is not installed, nothing to remove."
            continue
        }
        npx -y skills remove $Name --global --agent claude-code --yes
        if ($LASTEXITCODE -ne 0) { throw "skills remove $Name failed with exit code $LASTEXITCODE." }
        Write-Host "Removed $Name."
        continue
    }

    if ($Installed -and -not $Update) {
        Write-Host "$Name is already installed, skipping. -Update pulls the latest version."
        continue
    }

    # --copy rather than the default symlink: creating a symlink on Windows needs
    # Developer Mode or elevation, and without either the skill silently fails to
    # land in ~\.claude\skills. A copy also means an update is an explicit act
    # (-Update) rather than whatever the canonical copy happens to hold.
    npx -y skills add $Skill.Repo --skill $Name --global --agent claude-code --copy --yes
    if ($LASTEXITCODE -ne 0) { throw "skills add $Name failed with exit code $LASTEXITCODE." }

    if (-not (Test-Path (Join-Path $SkillsDir "$Name\SKILL.md"))) {
        throw "skills add $Name reported success, but $SkillsDir\$Name\SKILL.md does not exist."
    }
    Write-Host "Installed $Name in $SkillsDir\$Name. New Claude Code sessions pick it up."
}
