# QA Manual — claude-prompt-library

## Prerequisites

- Claude Code CLI installed (`claude --version` must respond)
- `jq` installed (`jq --version`) — macOS/Linux only
- `bash` 3.2+ (`bash --version`) — macOS ships 3.2, Linux typically 4+
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

Tests are organized into two categories:
- **CLI tests** (sections 2, 5, 8, 9, 10) — can be run standalone via `prompt-lib` without Claude Code
- **Interactive skill tests** (sections 1, 3, 4, 6, 7) — require a live Claude Code session, must be run manually

### 1. Skill detection (manual only — requires interactive Claude Code session)

> Note: These tests verify the skill integration layer. Autocomplete is only available in the interactive Claude Code terminal, not in `--print` mode.

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 1.1 | Open a new Claude Code session | Session starts without errors | |
| 1.2 | Type `/prompt` and wait for autocomplete | Suggestion appears: `/prompt (prompt-library)` in the dropdown | |
| 1.3 | Select `/prompt` and press Enter | Claude responds (runs `prompt-lib list` or asks what to do) — no "Unknown skill" error | |
| 1.4 | Type `/prompt list` and press Enter | Claude runs `prompt-lib list` and shows a table or "No prompts saved yet" | |

### 2. Empty library (initial state) — CLI tests

These can be run via CLI or inside Claude Code.

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 2.1 | `prompt-lib list` with empty library | Message: "No prompts saved yet" | |
| 2.2 | `prompt-lib load nonexistent` | `error: prompt 'nonexistent' not found` (exit code 1) | |
| 2.3 | `prompt-lib search something` | "No results found" | |
| 2.4 | `prompt-lib delete nonexistent` | `error: prompt 'nonexistent' not found` (exit code 1) | |
| 2.5 | `prompt-lib refresh nonexistent` | `error: prompt 'nonexistent' not found` (exit code 1) | |

### 3. Save a prompt

**3a. CLI layer tests:**

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 3a.1 | Save with frontmatter via CLI heredoc | `prompt-lib save` outputs "saved: code-reviewer" | |
| 3a.2 | Verify file created | `~/.claude/plugins/data/prompt-library/prompts/code-reviewer.md` exists | |
| 3a.3 | Verify INDEX.json updated | Entry contains slug, name, description, category, tags, created | |
| 3a.4 | Verify autocomplete command created | `~/.claude/commands/prompt:code-reviewer.md` exists | |
| 3a.5 | `prompt-lib list` | Shows the newly saved prompt with all fields | |

**3b. Conversational skill tests (manual only — requires interactive Claude Code session):**

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 3b.1 | `/prompt save my-prompt` | Claude asks for content, description, category and tags | |
| 3b.2 | Provide content and metadata | Claude runs `prompt-lib save` and confirms with the `/prompt:<name>` shortcut | |

### 4. Load a prompt

**4a. CLI layer tests:**

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 4a.1 | `prompt-lib load code-reviewer` | Prints the full file content including frontmatter | |

**4b. Conversational skill tests (manual only — requires interactive Claude Code session):**

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 4b.1 | `/prompt load code-reviewer` | Claude displays the prompt content | |
| 4b.2 | Verify Claude offers options | Asks whether to use as-is or modify, and mentions `/prompt:<name>` shortcut | |

### 5. Search prompts — CLI tests

Prerequisite: save at least 3 prompts with different categories and tags.

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 5.1 | `prompt-lib search` + partial name | Finds by slug | |
| 5.2 | `prompt-lib search` + tag | Finds by tag | |
| 5.3 | `prompt-lib search` + category | Finds by category | |
| 5.4 | `prompt-lib search` + word from content | Finds in content match | |
| 5.5 | `prompt-lib search` + nonexistent text | "No results found" | |
| 5.6 | Case-insensitive search | `API` and `api` return the same results | |

### 6. Edit a prompt

**6a. CLI layer tests:**

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 6a.1 | `prompt-lib edit code-reviewer` | Prints the absolute file path | |
| 6a.2 | Manually edit the file, then run `prompt-lib refresh code-reviewer` | Outputs "refreshed: code-reviewer" | |
| 6a.3 | `prompt-lib list` | Shows updated description | |
| 6a.4 | Verify command file updated | `~/.claude/commands/prompt:code-reviewer.md` has new description | |

**6b. Conversational skill tests (manual only — requires interactive Claude Code session):**

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 6b.1 | `/prompt edit code-reviewer` | Claude gets file path, reads it, shows content | |
| 6b.2 | Request a change | Claude modifies the file with Edit tool | |
| 6b.3 | Verify auto-refresh (hook) or manual refresh | INDEX.json and command file are updated | |

### 7. Delete a prompt

**7a. CLI layer tests — `prompt-lib delete` deletes immediately, no confirmation:**

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 7a.1 | `prompt-lib delete code-reviewer` | Outputs "deleted: code-reviewer" (no confirmation prompt) | |
| 7a.2 | Verify file removed | `ls` of prompts directory does not show the file | |
| 7a.3 | Verify INDEX.json updated | Entry was removed | |
| 7a.4 | Verify autocomplete command removed | `~/.claude/commands/prompt:code-reviewer.md` no longer exists | |
| 7a.5 | `prompt-lib list` | No longer shows the deleted prompt | |

**7b. Conversational skill tests (manual only — requires interactive Claude Code session):**

> Note: The skill layer (Claude) should confirm before deleting. The CLI layer does not.

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 7b.1 | `/prompt delete code-reviewer` | Claude asks for confirmation before running the delete | |
| 7b.2 | Confirm | Claude runs `prompt-lib delete` and confirms deletion | |

### 8. Autocomplete integration — CLI + manual tests

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 8.1 | Save a prompt via CLI | `~/.claude/commands/prompt:<name>.md` is created automatically | |
| 8.2 | `prompt-lib sync` | All prompts regenerated in `~/.claude/commands/`, output shows count | |
| 8.3 | Delete a prompt via CLI | Corresponding command file is removed | |
| 8.4 | Open a new Claude Code session (manual) | Session loads without errors | |
| 8.5 | Type `/prompt:` and wait (manual) | Saved prompts appear in the autocomplete dropdown | |
| 8.6 | Select a prompt from autocomplete (manual) | Prompt content is injected into the conversation | |

### 9. Edge cases — CLI tests

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 9.1 | Save prompt with spaces in name: `my long prompt` | Slugifies to `my-long-prompt` | |
| 9.2 | Save prompt with uppercase: `CodeReview` | Slugifies to `codereview` | |
| 9.3 | Save prompt with special characters: `test@#$%` | Slugifies correctly, no invalid characters | |
| 9.4 | Save prompt with same name as existing one | Overwrites the existing one, updates INDEX.json | |
| 9.5 | Save prompt with empty content (frontmatter only) | Saves the file (frontmatter is valid content) | |
| 9.6 | Save raw text without frontmatter (no `---` block) | Saves correctly; metadata defaults to description="" category="general" tags="[]" | |
| 9.7 | Prompt with very long content (>10KB) | Saves and loads without truncation | |
| 9.8 | Corrupted INDEX.json (delete manually) | `prompt-lib init` regenerates it as empty `[]` | |
| 9.9 | Data directory does not exist | Created automatically on first use | |
| 9.10 | Concurrent writes to INDEX.json | Last write wins; no crash or corruption (jq atomic via temp file + mv) | |

### 10. Standalone CLI (without Claude Code)

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
prompt-lib refresh test-cli
prompt-lib sync
prompt-lib delete test-cli
prompt-lib list
```

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 10.1 | `prompt-lib help` | Shows full help text with all commands | |
| 10.2 | All CRUD commands | Work without errors | |
| 10.3 | `prompt-lib refresh test-cli` | Re-reads metadata and syncs command file | |
| 10.4 | `prompt-lib sync` | Syncs all prompts to `~/.claude/commands/` | |
| 10.5 | Run without `CLAUDE_PLUGIN_DATA` | Uses fallback `~/.claude/plugins/data/prompt-library` | |
| 10.6 | Run without `jq` installed | Clear error (bash exits with "jq: command not found") | |

### 11. Install and uninstall (manual only — each step requires a new session to verify)

> Note: Plugin enable/disable/uninstall effects are only visible after restarting Claude Code. Each verification step below requires opening a new session.

| # | Step | Expected result | Pass/Fail |
|---|------|----------------|-----------|
| 11.1 | `claude plugin install claude-prompt-library@claude-prompt-library --scope user` | Output: "Successfully installed" | |
| 11.2 | `claude plugin list` | Shows `claude-prompt-library@claude-prompt-library` with `Status: ✔ enabled` | |
| 11.3 | `claude plugin disable claude-prompt-library@claude-prompt-library` | Output: "Successfully disabled" | |
| 11.4 | `claude plugin list` | Shows `Status: ✘ disabled` | |
| 11.5 | Open new session, type `/prompt` | Skill does not appear in autocomplete | |
| 11.6 | `claude plugin enable claude-prompt-library@claude-prompt-library` | Output: "Successfully enabled" | |
| 11.7 | Open new session, type `/prompt` | Skill appears again in autocomplete | |
| 11.8 | `claude plugin uninstall claude-prompt-library@claude-prompt-library` | Output: "Successfully uninstalled" | |
| 11.9 | `claude plugin list` | Plugin no longer listed | |
| 11.10 | Verify data persists after uninstall | `~/.claude/plugins/data/prompt-library/` still exists with all prompts | |

---

## Suggested improvements

### High priority

1. **Dependency detection**: The bash script should verify that `jq` is installed at startup and show a clear error if missing, instead of failing with a cryptic "command not found".

2. **`prompt-lib export` command**: Export one or all prompts to a project directory (`.claude/prompts/`) to share with the team.

3. **`prompt-lib import` command**: Import prompts from a `.md` file or directory, to migrate existing prompts.

4. **Overwrite confirmation**: When saving a prompt with a name that already exists, warn that it will be overwritten and ask for confirmation (CLI flag `--force` to skip).

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

### Known limitations

15. **Concurrent writes**: INDEX.json writes use temp file + `mv` (atomic on POSIX), but two simultaneous writes could still race. Not critical for single-user usage.

16. **PostToolUse hook on Windows**: The auto-refresh hook (`refresh-prompt.sh`) only works on macOS/Linux. Windows users must run `prompt-lib sync` manually after editing.

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

### Step 7: Edit and refresh

```
/prompt edit code-review    # Claude edits the file
/prompt refresh code-review # update index + autocomplete (auto if hook is active)
```

### Step 8: Recommended daily workflow

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
┌──────────────────────────────────────────────────┐
│           claude-prompt-library                  │
├──────────────────────────────────────────────────┤
│  /prompt list           List all prompts         │
│  /prompt save <name>    Save a new prompt        │
│  /prompt load <name>    Load an existing prompt  │
│  /prompt search <q>     Search prompts           │
│  /prompt edit <name>    Edit a prompt            │
│  /prompt delete <name>  Delete a prompt          │
│  /prompt refresh <name> Update index after edit  │
│  /prompt sync           Sync all to autocomplete │
├──────────────────────────────────────────────────┤
│  /prompt:<name>         Quick load (autocomplete)│
├──────────────────────────────────────────────────┤
│  Categories: api | system | chat | agent         │
│              task | general                      │
└──────────────────────────────────────────────────┘
```
