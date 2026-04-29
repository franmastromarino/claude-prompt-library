# QA Manual — claude-prompt-library

## Prerequisites

- Claude Code CLI installed (`claude --version` must respond)
- `jq` installed (`jq --version`)
- `bash` 4+ (`bash --version`)
- GitHub account with repo access

## Installation for testing

```bash
# Option A: from marketplace (production)
claude plugin marketplace add franciscomastromarino/claude-prompt-library
claude plugin install claude-prompt-library@claude-prompt-library --scope user

# Option B: local development (no install)
git clone https://github.com/franciscomastromarino/claude-prompt-library.git
claude --plugin-dir ./claude-prompt-library
```

Verify installation:

```bash
claude plugin list
# Should show: claude-prompt-library@claude-prompt-library — Status: ✔ enabled
```

---

## Test plan

### 1. Skill detection

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 1.1 | Open a new Claude Code session | Session starts without errors | |
| 1.2 | Type `/prompt` and wait for autocomplete | Suggestion appears: `/prompt (prompt-library)` | |
| 1.3 | Press Enter on `/prompt` | Claude executes the skill without "Unknown skill" error | |
| 1.4 | Type `/prompt list` | Claude runs `prompt-lib list` and shows results | |

### 2. Empty library (initial state)

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 2.1 | `/prompt list` with empty library | Message: "No prompts saved yet" | |
| 2.2 | `/prompt load nonexistent` | Clear error message, no crash | |
| 2.3 | `/prompt search something` | "No results found" | |
| 2.4 | `/prompt delete nonexistent` | Clear error message, no crash | |

### 3. Save a prompt

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 3.1 | `/prompt save code-reviewer` | Claude asks for content, description, category and tags | |
| 3.2 | Provide content and metadata | Runs `prompt-lib save` and confirms "saved: code-reviewer" | |
| 3.3 | Verify file created | `~/.claude/plugins/data/prompt-library/prompts/code-reviewer.md` exists | |
| 3.4 | Verify index updated | `INDEX.json` contains entry with slug, name, description, category, tags, created | |
| 3.5 | `/prompt list` | Shows the newly saved prompt with all fields | |
| 3.6 | Verify autocomplete command created | `~/.claude/commands/prompt:code-reviewer.md` exists | |

### 4. Load a prompt

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 4.1 | `/prompt load code-reviewer` | Shows the full prompt content | |
| 4.2 | Verify frontmatter is displayed | Description, category and tags are visible | |
| 4.3 | Verify Claude offers options | Asks whether to use as-is or modify | |

### 5. Search prompts

Prerequisite: save at least 3 prompts with different categories and tags.

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 5.1 | `/prompt search` + partial name | Finds by slug | |
| 5.2 | `/prompt search` + tag | Finds by tag | |
| 5.3 | `/prompt search` + category | Finds by category | |
| 5.4 | `/prompt search` + word from content | Finds in content match | |
| 5.5 | `/prompt search` + nonexistent text | "No results found" | |
| 5.6 | Case-insensitive search | `API` and `api` return the same results | |

### 6. Edit a prompt

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 6.1 | `/prompt edit code-reviewer` | Claude gets the file path | |
| 6.2 | Request a change to the content | Claude reads the file and modifies it with Edit tool | |
| 6.3 | `/prompt load code-reviewer` | Shows the updated content | |

### 7. Delete a prompt

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 7.1 | `/prompt delete code-reviewer` | Claude confirms before deleting | |
| 7.2 | Confirm deletion | "deleted: code-reviewer" | |
| 7.3 | Verify file no longer exists | `ls` of the directory does not show the file | |
| 7.4 | Verify INDEX.json updated | Entry was removed | |
| 7.5 | `/prompt list` | No longer shows the deleted prompt | |
| 7.6 | Verify autocomplete command removed | `~/.claude/commands/prompt:code-reviewer.md` no longer exists | |

### 8. Autocomplete integration

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 8.1 | Save a prompt named `my-test` | `~/.claude/commands/prompt:my-test.md` is created | |
| 8.2 | Open a new Claude Code session | Session loads without errors | |
| 8.3 | Type `/prompt:` and wait for autocomplete | Saved prompts appear in the selector | |
| 8.4 | Select `/prompt:my-test` | Prompt content is injected into the conversation | |
| 8.5 | Run `prompt-lib sync` | All prompts regenerated in `~/.claude/commands/` | |
| 8.6 | Delete a prompt | Corresponding command file is removed | |

### 9. Edge cases

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 9.1 | Save prompt with spaces in name: `my long prompt` | Slugifies to `my-long-prompt` | |
| 9.2 | Save prompt with uppercase: `CodeReview` | Slugifies to `codereview` | |
| 9.3 | Save prompt with special characters: `test@#$%` | Slugifies correctly, no invalid characters | |
| 9.4 | Save prompt with same name as existing one | Overwrites the existing one, updates INDEX.json | |
| 9.5 | Save prompt with empty content (frontmatter only) | Saves correctly or shows clear error | |
| 9.6 | Prompt with very long content (>10KB) | Saves and loads without truncation | |
| 9.7 | Corrupted INDEX.json (delete manually) | `prompt-lib init` regenerates it | |
| 9.8 | Data directory does not exist | Created automatically on first use | |

### 10. Standalone CLI (without Claude)

Run outside of Claude Code to verify the CLI works independently:

```bash
export CLAUDE_PLUGIN_DATA="$HOME/.claude/plugins/data/prompt-library"
prompt-lib help
prompt-lib init
prompt-lib save test-cli <<'EOF'
---
description: Test from CLI
category: general
tags: [test]
---
Test content
EOF
prompt-lib list
prompt-lib load test-cli
prompt-lib search test
prompt-lib sync
prompt-lib delete test-cli
prompt-lib list
```

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 10.1 | `prompt-lib help` | Shows full help text | |
| 10.2 | All CRUD commands | Work without errors | |
| 10.3 | `prompt-lib sync` | Syncs all prompts to `~/.claude/commands/` | |
| 10.4 | Run without `CLAUDE_PLUGIN_DATA` | Uses fallback `~/.claude/plugins/data/prompt-library` | |
| 10.5 | Run without `jq` installed | Clear error indicating missing dependency | |

### 11. Install and uninstall

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 11.1 | `claude plugin install` from marketplace | Installs correctly | |
| 11.2 | `claude plugin list` | Shows plugin as enabled | |
| 11.3 | `claude plugin disable` | Disables plugin, skill no longer available | |
| 11.4 | `claude plugin enable` | Reactivates, skill available again | |
| 11.5 | `claude plugin uninstall` | Uninstalls cleanly | |
| 11.6 | Verify data persists after uninstall | `~/.claude/plugins/data/prompt-library/` still exists | |

---

## Suggested improvements

### High priority

1. **Dependency detection**: The script should verify that `jq` is installed and show a clear error if missing, instead of failing silently.

2. **`prompt-lib export` command**: Export one or all prompts to a project directory (`.claude/prompts/`) to share with the team.

3. **`prompt-lib import` command**: Import prompts from a `.md` file or directory, to migrate existing prompts.

4. **Overwrite confirmation**: When saving a prompt with a name that already exists, warn that it will be overwritten and ask for confirmation.

5. **Prompt versioning**: Save previous versions when editing (backup in `prompts/.history/<name>/<timestamp>.md`).

### Medium priority

6. **`prompt-lib stats` command**: Show statistics: total prompts, by category, most recent, most used.

7. **Tags as first-class citizen**: `prompt-lib tags` command to list all tags in use and how many prompts each one has.

8. **Configurable output format**: `prompt-lib list --json` for integration with other tools.

9. **Template variables support**: Placeholders like `{{name}}`, `{{context}}` that Claude fills in when loading.

10. **Favorites / pinned**: Mark prompts as favorites so they appear first in `list`.

### Low priority

11. **Cross-machine sync**: Sync the prompt library via git (a dedicated repo as storage).

12. **Project-level shared prompts**: In addition to `~/.claude/plugins/data/`, support `.claude/prompts/` at project level.

13. **Custom categories**: Allow categories beyond the predefined ones.

14. **Name autocompletion**: `prompt-lib load <TAB>` autocompletes existing prompt names.

---

## Onboarding process

Step-by-step guide for someone who has never used the plugin.

### Step 1: Context (30 seconds)

> **What is this?** A plugin for Claude Code that lets you save frequently used prompts and reuse them across any project. Think of it as a "bookmark" for prompts.

### Step 2: Installation (1 minute)

```bash
# Register the marketplace
claude plugin marketplace add franciscomastromarino/claude-prompt-library

# Install
claude plugin install claude-prompt-library@claude-prompt-library --scope user
```

Verify:
```bash
claude plugin list
# Look for: claude-prompt-library — Status: ✔ enabled
```

### Step 3: First use — save a prompt (2 minutes)

Open Claude Code and type:

```
/prompt save code-review
```

Claude will ask you for:
1. **Prompt content** — paste or type the prompt you want to save
2. **Description** — one line explaining what it's for
3. **Category** — choose from: `api`, `system`, `chat`, `agent`, `task`, `general`
4. **Tags** — comma-separated keywords (optional)

### Step 4: Retrieve a prompt (30 seconds)

```
/prompt load code-review
```

Claude shows the prompt and asks if you want to use it as-is or modify it.

### Step 5: Browse the library (30 seconds)

```
/prompt list           # see all
/prompt search api     # search by keyword
```

### Step 6: Quick access via autocomplete

After saving prompts, they become available in the Claude Code autocomplete. Type `/prompt:` and your saved prompts appear in the selector — just pick one.

To manually sync all prompts to autocomplete:
```
/prompt sync
```

### Step 7: Recommended daily workflow

```
New session → need a prompt you wrote before

  Option A: /prompt search <what you remember>
            /prompt load <name>
            → Claude loads it, ready to use

  Option B: Type /prompt: and pick from autocomplete
            → Instant, no typing needed

Finished writing a good prompt in the conversation

  /prompt save <descriptive-name>
  → Saved for next time
```

### Cheat sheet

```
┌─────────────────────────────────────────────────┐
│           claude-prompt-library                 │
├─────────────────────────────────────────────────┤
│  /prompt list          List all prompts         │
│  /prompt save <name>   Save a new prompt        │
│  /prompt load <name>   Load an existing prompt  │
│  /prompt search <q>    Search prompts           │
│  /prompt edit <name>   Edit a prompt            │
│  /prompt delete <name> Delete a prompt          │
│  /prompt sync          Sync to autocomplete     │
├─────────────────────────────────────────────────┤
│  /prompt:<name>        Quick load (autocomplete)│
├─────────────────────────────────────────────────┤
│  Categories: api | system | chat | agent        │
│              task | general                     │
└─────────────────────────────────────────────────┘
```
