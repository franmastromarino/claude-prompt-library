# claude-prompt-library

A Claude Code plugin to save, search, load and manage reusable prompts across projects.

## Installation

```bash
claude plugin install franmastromarino/claude-prompt-library --scope user
```

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

### Searching

```
/prompt search claude
```

Searches across names, descriptions, tags and file content.

## How it works

The plugin provides:

- **`bin/prompt-lib`** — A portable bash CLI that handles all CRUD operations deterministically
- **`skills/prompt/SKILL.md`** — A skill definition that gives Claude the `/prompt` interface

Prompts are stored as markdown files with YAML frontmatter in `${CLAUDE_PLUGIN_DATA}/prompts/`, a persistent directory that survives plugin updates.

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
```

## Requirements

- Claude Code CLI
- `bash`, `jq` (available on macOS and most Linux distributions)

## License

MIT
