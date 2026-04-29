#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

# Auto-refresh prompt metadata after Edit/Write on a prompt file.
# Receives JSON on stdin from the PostToolUse hook event.

$input_json = [Console]::In.ReadToEnd()
if (-not $input_json) { exit 0 }

$data = $input_json | ConvertFrom-Json
$filePath = $data.tool_input.file_path
if (-not $filePath) { exit 0 }

# Only act on files inside the prompt library data directory
$dataDir = if ($env:CLAUDE_PLUGIN_DATA) { $env:CLAUDE_PLUGIN_DATA } else { Join-Path $HOME '.claude/plugins/data/prompt-library' }
$promptsDir = Join-Path $dataDir 'prompts'

if (-not $filePath.StartsWith($promptsDir)) { exit 0 }
if (-not $filePath.EndsWith('.md')) { exit 0 }

# Extract slug from filename
$slug = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

# Run refresh via prompt-lib
$promptLib = Join-Path $PSScriptRoot '..' 'bin' 'prompt-lib.ps1'
if ($env:CLAUDE_PLUGIN_ROOT) {
    $promptLib = Join-Path $env:CLAUDE_PLUGIN_ROOT 'bin' 'prompt-lib.ps1'
}

if (Test-Path $promptLib) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $promptLib refresh $slug 2>&1 | Out-Null
}

exit 0
