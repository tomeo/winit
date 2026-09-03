# Registers the Chrome DevTools MCP server with Claude Code in user scope, so
# every repo on the machine gets a real browser to drive. The web-perf skill
# depends on it and cannot run at all without it, and HTTP-level tools cannot see
# anything a page renders with JavaScript. User scope rather than a project
# .mcp.json on purpose: this is a property of the machine, and a project file
# would make Chrome a dependency for everyone who opens that repo.
# Safe to re-run: an existing registration is left alone. -Remove undoes it.
param([switch]$Remove)

# The name is not free to choose. The web-perf skill calls navigate_page and
# performance_start_trace, which Claude Code exposes as mcp__chrome-devtools__*,
# so registering under any other name leaves the skill without its tools.
$Name = 'chrome-devtools'

# @latest matches the house style, where scoop and winget track latest too. Pin
# a version here instead if reproducible machines ever matter more than currency.
$Package = 'chrome-devtools-mcp@latest'

# Resolved once, .cmd first, and used for all three branches below. The npm shim
# first on PATH is claude.ps1, and a bare -- does not survive that hop: it is
# dropped on the way into the script, so the shim splats $args without it and
# claude reads npx's -y as a flag of its own rather than passing it on. A .cmd
# shim forwards %* untouched. Do not "tidy" this back to plain claude.
$Claude = 'claude.cmd'
if (-not (Get-Command $Claude -ErrorAction SilentlyContinue)) {
    # An install that is not the npm one can leave claude without a .cmd shim.
    $Claude = 'claude'
    if (-not (Get-Command $Claude -ErrorAction SilentlyContinue)) {
        throw 'Claude Code is not installed, run ./install-nodejs.ps1 first.'
    }
    Write-Host "No claude.cmd on PATH, falling back to $Claude. An 'unknown option -y' below is that shim eating the separator."
}

# `claude mcp get` exits 0 whether the server is registered or not, so the exit
# code says nothing and the absence is only visible in the text it prints.
function Test-Registered {
    $Output = & $Claude mcp get $Name 2>&1 | Out-String
    return $Output -notmatch 'No MCP server named'
}

if ($Remove) {
    if (-not (Test-Registered)) {
        Write-Host "$Name is not registered with Claude Code, nothing to remove."
        return
    }
    & $Claude mcp remove $Name --scope user
    Write-Host "Removed $Name. The web-perf skill has no browser until it is added back."
    return
}

if (Test-Registered) {
    Write-Host "$Name is already registered with Claude Code, skipping."
    return
}

# Deliberately no --userDataDir and no --browserUrl. Left alone the server starts
# its own Chrome against an isolated profile under
# ~\.cache\chrome-devtools-mcp\chrome-profile. Pointed at the signed-in profile
# it would inherit every session cookie on the machine and could act as the user
# in each service they are logged into, which is a wholly different risk class
# than a tool that only reads pages.
& $Claude mcp add --scope user $Name -- npx -y $Package
if ($LASTEXITCODE -ne 0) { throw "claude mcp add failed with exit code $LASTEXITCODE." }

Write-Host "Registered $Name in user scope, so it is available in every repo."
Write-Host 'It downloads Chrome on its first run, which takes a minute.'
Write-Host 'Remove it again with: ./configure-claude-mcp.ps1 -Remove'
