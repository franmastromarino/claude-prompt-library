# claude-prompt-library

A Claude Code plugin to save, search, load and manage reusable prompts across projects.

## Installation

### Via GitHub marketplace

```bash
# 1. Register the marketplace
claude plugin marketplace add franmastromarino/claude-prompt-library

# 2. Install the plugin
claude plugin install claude-prompt-library@claude-prompt-library --scope user
```

### Via official Claude marketplace

> Coming soon — submission pending approval.
>
> ```bash
> claude plugin install claude-prompt-library --scope user
> ```

## Usage

Invoke `/prompt` in any Claude Code session:

| Command | Description |
|---|---|
| `/prompt list` | List all saved prompts |
| `/prompt save <name>` | Save a prompt interactively |
| `/prompt load <name>` | Load a prompt into the conversation |
| `/prompt search <query>` | Search by name, tag, category or content |
| `/prompt delete <name>` | Delete a prompt |
| `/prompt edit <name>` | Edit an existing prompt |
| `/prompt sync` | Sync all prompts to autocomplete |

### Saving a prompt

```
/prompt save api-review
```

Claude will ask for the content, a short description, category and optional tags, then store it for later use.

### Loading a prompt

```
/prompt load api-review
```

The saved prompt is printed into the conversation, ready to use or modify.

### Quick access via autocomplete

Saved prompts are automatically registered as Claude Code commands. Type `/prompt:` and your prompts appear in the autocomplete selector — just pick one.

```
/prompt:api-review        → loads instantly
/prompt:code-reviewer     → loads instantly
```

To manually sync all prompts to autocomplete:

```
/prompt sync
```

### Searching

```
/prompt search claude
```

Searches across names, descriptions, tags and file content.

## How it works

The plugin provides:

- **`bin/prompt-lib`** — Bash CLI for macOS/Linux (requires `jq`)
- **`bin/prompt-lib.ps1`** — PowerShell CLI for Windows (no external dependencies)
- **`bin/prompt-lib.cmd`** — Windows wrapper that invokes the PowerShell script
- **`skills/prompt/SKILL.md`** — A skill definition that gives Claude the `/prompt` interface

Prompts are stored as markdown files with YAML frontmatter in `${CLAUDE_PLUGIN_DATA}/prompts/`, a persistent directory that survives plugin updates.

When saving a prompt, the CLI also generates a command file in `~/.claude/commands/` so the prompt appears in Claude Code's native autocomplete as `/prompt:<name>`.

### Prompt format

```markdown
---
description: System prompt for code review API
category: api
tags: [review, claude, api]
---

You are a code review assistant...
```

### Categories

`api` | `system` | `chat` | `agent` | `task` | `general`

## Development

```bash
# Test locally
claude --plugin-dir ./

# Run the CLI directly
./bin/prompt-lib help
./bin/prompt-lib list
./bin/prompt-lib sync
```

## Platform support

| Platform | CLI | Auto-refresh hook |
|----------|-----|-------------------|
| macOS / Linux | `prompt-lib` (bash + jq) | Yes |
| Windows | `prompt-lib.cmd` (PowerShell 5.1+) | Manual sync needed |

### Requirements

- Claude Code CLI
- **macOS/Linux**: `bash`, `jq`
- **Windows**: PowerShell 5.1+ (included in Windows 10+)

## Privacy

This plugin stores all data locally on your machine (`~/.claude/plugins/data/prompt-library/`). No data is collected, transmitted, or shared with third parties. All prompt content remains entirely under your control.

## License

MIT
