#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# prompt-lib — Personal prompt library manager (PowerShell)
# Storage: ${CLAUDE_PLUGIN_DATA}/prompts/

# ── Config ──────────────────────────────────────────────────────────

$DataDir = if ($env:CLAUDE_PLUGIN_DATA) { $env:CLAUDE_PLUGIN_DATA } else { Join-Path $HOME '.claude/plugins/data/prompt-library' }
$PromptsDir = Join-Path $DataDir 'prompts'
$IndexFile = Join-Path $DataDir 'INDEX.json'
$CommandsDir = Join-Path $HOME '.claude/commands'
$CommandPrefix = 'prompt:'

# ── Helpers ─────────────────────────────────────────────────────────

function Ensure-Dirs {
    if (-not (Test-Path $PromptsDir)) { New-Item -ItemType Directory -Path $PromptsDir -Force | Out-Null }
    if (-not (Test-Path $IndexFile)) { '[]' | Set-Content -Path $IndexFile -Encoding UTF8 }
}

function Get-Slug {
    param([string]$Name)
    $Name.ToLower() -replace '[^a-z0-9_-]', '-' -replace '-+', '-' -replace '^-|-$', ''
}

function Get-PromptPath {
    param([string]$Slug)
    Join-Path $PromptsDir "$Slug.md"
}

function Read-Index {
    Get-Content -Path $IndexFile -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-Index {
    param($Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $IndexFile -Encoding UTF8
}

function Parse-Frontmatter {
    param([string]$Content)
    $result = @{ description = ''; category = 'general'; tags = '[]' }
    $lines = $Content -split "`n"
    if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') { return $result }

    $inFrontmatter = $false
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '---') {
            if ($inFrontmatter) { break }
            $inFrontmatter = $true
            continue
        }
        if (-not $inFrontmatter) { continue }
        if ($trimmed -match '^description:\s*(.+)$') { $result.description = $Matches[1] }
        if ($trimmed -match '^category:\s*(.+)$') { $result.category = $Matches[1] }
        if ($trimmed -match '^tags:\s*(.+)$') { $result.tags = $Matches[1] }
    }
    return $result
}

function Get-BodyAfterFrontmatter {
    param([string]$Content)
    $lines = $Content -split "`n"
    if ($lines[0].Trim() -ne '---') { return $Content }
    $count = 0
    $startIndex = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $count++ }
        if ($count -eq 2) { $startIndex = $i + 1; break }
    }
    if ($startIndex -ge $lines.Count) { return '' }
    ($lines[$startIndex..($lines.Count - 1)]) -join "`n"
}

function Sync-Command {
    param([string]$Slug)
    if (-not (Test-Path $CommandsDir)) { New-Item -ItemType Directory -Path $CommandsDir -Force | Out-Null }
    $filepath = Get-PromptPath $Slug
    if (-not (Test-Path $filepath)) { return }

    $content = Get-Content -Path $filepath -Raw -Encoding UTF8
    $meta = Parse-Frontmatter $content
    $description = if ($meta.description) { $meta.description } else { "Load prompt: $Slug" }
    $body = Get-BodyAfterFrontmatter $content

    $cmdContent = @"
---
description: "$description"
---

$body
"@
    $cmdFile = Join-Path $CommandsDir "${CommandPrefix}${Slug}.md"
    $cmdContent | Set-Content -Path $cmdFile -Encoding UTF8
}

function Remove-Command {
    param([string]$Slug)
    $cmdFile = Join-Path $CommandsDir "${CommandPrefix}${Slug}.md"
    if (Test-Path $cmdFile) { Remove-Item -Path $cmdFile -Force }
}

function Write-Error-And-Exit {
    param([string]$Message)
    Write-Host "error: $Message" -ForegroundColor Red
    exit 1
}

# ── Commands ────────────────────────────────────────────────────────

function Cmd-Init {
    Ensure-Dirs
    Write-Host "Prompt library initialized at $DataDir"
}

function Cmd-Save {
    param([string]$Name)
    if (-not $Name) { Write-Error-And-Exit 'usage: prompt-lib save <name>' }
    Ensure-Dirs

    $slug = Get-Slug $Name
    $filepath = Get-PromptPath $slug

    # Read content from stdin
    $content = @($input) -join "`n"
    if (-not $content.Trim()) { Write-Error-And-Exit 'no content provided (pipe content via stdin)' }

    $content | Set-Content -Path $filepath -Encoding UTF8

    # Extract metadata
    $meta = Parse-Frontmatter $content
    $created = Get-Date -Format 'yyyy-MM-dd'

    # Update index
    $index = @(Read-Index | Where-Object { $_.slug -ne $slug })
    $entry = [PSCustomObject]@{
        slug        = $slug
        name        = $Name
        description = $meta.description
        category    = $meta.category
        tags        = $meta.tags
        created     = $created
    }
    $index += $entry
    Write-Index $index

    Sync-Command $slug

    Write-Host "saved: $slug -> $filepath"
    Write-Host "command: /${CommandPrefix}${slug} (available in autocomplete)"
}

function Cmd-List {
    Ensure-Dirs
    $index = @(Read-Index)

    if ($index.Count -eq 0) {
        Write-Host 'No prompts saved yet. Use ''prompt-lib save <name>'' to add one.'
        return
    }

    Write-Host "Prompt Library ($($index.Count) prompts)"
    Write-Host ([string]::new([char]0x2500, 45))
    foreach ($entry in $index) {
        $line = "  {0,-20} {1,-10} {2,-25} {3}" -f $entry.slug, $entry.category, $entry.tags, $entry.description
        Write-Host $line
    }
    Write-Host ''
}

function Cmd-Load {
    param([string]$Name)
    if (-not $Name) { Write-Error-And-Exit 'usage: prompt-lib load <name>' }
    Ensure-Dirs

    $slug = Get-Slug $Name
    $filepath = Get-PromptPath $slug

    if (-not (Test-Path $filepath)) { Write-Error-And-Exit "prompt '$slug' not found" }

    Get-Content -Path $filepath -Raw -Encoding UTF8
}

function Cmd-Search {
    param([string]$Query)
    if (-not $Query) { Write-Error-And-Exit 'usage: prompt-lib search <query>' }
    Ensure-Dirs

    Write-Host "Searching for: $Query"
    Write-Host ([string]::new([char]0x2500, 45))

    $queryLower = $Query.ToLower()
    $index = @(Read-Index)
    $found = $false

    # Search index metadata
    $metaMatches = @($index | Where-Object {
        $_.slug.ToLower().Contains($queryLower) -or
        $_.description.ToLower().Contains($queryLower) -or
        $_.tags.ToLower().Contains($queryLower) -or
        $_.category.ToLower().Contains($queryLower)
    })

    if ($metaMatches.Count -gt 0) {
        Write-Host 'Matches:'
        foreach ($m in $metaMatches) {
            Write-Host ("  {0,-20} {1,-10} {2}" -f $m.slug, $m.category, $m.description)
        }
        $found = $true
    }

    # Search file content
    $contentMatches = @()
    if (Test-Path $PromptsDir) {
        Get-ChildItem -Path $PromptsDir -Filter '*.md' | ForEach-Object {
            $fileContent = Get-Content -Path $_.FullName -Raw -Encoding UTF8
            if ($fileContent.ToLower().Contains($queryLower)) {
                $contentMatches += $_.BaseName
            }
        }
    }

    if ($contentMatches.Count -gt 0) {
        Write-Host ''
        Write-Host 'Content matches:'
        foreach ($slug in $contentMatches) {
            Write-Host "  $slug"
        }
        $found = $true
    }

    if (-not $found) {
        Write-Host 'No results found.'
    }
}

function Cmd-Delete {
    param([string]$Name)
    if (-not $Name) { Write-Error-And-Exit 'usage: prompt-lib delete <name>' }
    Ensure-Dirs

    $slug = Get-Slug $Name
    $filepath = Get-PromptPath $slug

    if (-not (Test-Path $filepath)) { Write-Error-And-Exit "prompt '$slug' not found" }

    Remove-Item -Path $filepath -Force
    Remove-Command $slug

    $index = @(Read-Index | Where-Object { $_.slug -ne $slug })
    Write-Index $index

    Write-Host "deleted: $slug"
}

function Cmd-Edit {
    param([string]$Name)
    if (-not $Name) { Write-Error-And-Exit 'usage: prompt-lib edit <name>' }
    Ensure-Dirs

    $slug = Get-Slug $Name
    $filepath = Get-PromptPath $slug

    if (-not (Test-Path $filepath)) { Write-Error-And-Exit "prompt '$slug' not found" }

    Write-Host $filepath
}

function Cmd-Refresh {
    param([string]$Name)
    if (-not $Name) { Write-Error-And-Exit 'usage: prompt-lib refresh <name>' }
    Ensure-Dirs

    $slug = Get-Slug $Name
    $filepath = Get-PromptPath $slug

    if (-not (Test-Path $filepath)) { Write-Error-And-Exit "prompt '$slug' not found" }

    $content = Get-Content -Path $filepath -Raw -Encoding UTF8
    $meta = Parse-Frontmatter $content

    # Update index entry
    $index = @(Read-Index | ForEach-Object {
        if ($_.slug -eq $slug) {
            $_.description = $meta.description
            $_.category = $meta.category
            $_.tags = $meta.tags
        }
        $_
    })
    Write-Index $index

    Sync-Command $slug

    Write-Host "refreshed: $slug"
}

function Cmd-Sync {
    Ensure-Dirs
    if (-not (Test-Path $CommandsDir)) { New-Item -ItemType Directory -Path $CommandsDir -Force | Out-Null }

    # Remove old prompt commands
    Get-ChildItem -Path $CommandsDir -Filter "${CommandPrefix}*.md" -ErrorAction SilentlyContinue | Remove-Item -Force

    # Regenerate from index
    $index = @(Read-Index)
    $count = 0
    foreach ($entry in $index) {
        Sync-Command $entry.slug
        $count++
    }

    Write-Host "synced $count prompts to $CommandsDir"
    Write-Host "prompts are available as /${CommandPrefix}<name> in Claude Code autocomplete"
}

function Cmd-Help {
    @"
prompt-lib — Personal prompt library manager

Usage:
  prompt-lib save <name>      Save a prompt (reads from stdin)
  prompt-lib list              List all saved prompts
  prompt-lib load <name>      Print a saved prompt
  prompt-lib search <query>   Search by name, tag, category or content
  prompt-lib delete <name>    Delete a prompt
  prompt-lib edit <name>      Print path to prompt file for editing
  prompt-lib refresh <name>   Re-read metadata and sync after editing
  prompt-lib sync             Sync all prompts to Claude Code autocomplete
  prompt-lib init             Initialize the prompt library
  prompt-lib help             Show this help

Examples:
  "my prompt content" | prompt-lib save my-prompt
  prompt-lib list
  prompt-lib load my-prompt
  prompt-lib search "claude"
"@ | Write-Host
}

# ── Main ────────────────────────────────────────────────────────────

$action = if ($args.Count -gt 0) { $args[0] } else { 'help' }
$name = if ($args.Count -gt 1) { $args[1] } else { '' }

switch ($action) {
    'save'    { Cmd-Save $name }
    'list'    { Cmd-List }
    'load'    { Cmd-Load $name }
    'search'  { Cmd-Search $name }
    'delete'  { Cmd-Delete $name }
    'edit'    { Cmd-Edit $name }
    'refresh' { Cmd-Refresh $name }
    'sync'    { Cmd-Sync }
    'init'    { Cmd-Init }
    'help'    { Cmd-Help }
    default   { Write-Error-And-Exit "unknown command: $action (run 'prompt-lib help')" }
}
