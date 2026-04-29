---
name: prompt
description: Manage a personal prompt library. Save, list, load, search, and delete reusable prompts. Use when the user wants to store a prompt for later, browse saved prompts, load one into the conversation, or search their library by keyword or tag. Use when user mentions "save prompt", "prompt library", "load prompt", "my prompts", or "reusable prompt".
---

# Prompt Library Manager

You have access to `prompt-lib`, a CLI tool that manages a persistent prompt library.

## Handle the user's request

Run the appropriate command based on what the user asked. If no action is clear, run `prompt-lib list` and ask what they want to do.

### Available commands

| Command | Description |
|---------|-------------|
| `prompt-lib list` | Show all saved prompts with name, description, category and tags |
| `prompt-lib load <name>` | Print the full content of a saved prompt |
| `prompt-lib save <name>` | Save a prompt (reads content from stdin) |
| `prompt-lib search <query>` | Search prompts by name, description, tags or content |
| `prompt-lib delete <name>` | Delete a prompt and remove it from the index |
| `prompt-lib edit <name>` | Print path to prompt file for editing |
| `prompt-lib sync` | Sync all prompts to Claude Code autocomplete (`/prompt:<name>`) |

### Workflow

1. If no action is specified, run `prompt-lib list` and ask the user what they want to do.

2. **Saving a prompt** (`/prompt save <name>`):
   - Ask the user for the prompt content if not already in the conversation.
   - Ask for a short description (1 line) and optional tags (comma-separated).
   - Ask for a category: `api`, `system`, `chat`, `agent`, `task`, or `general`.
   - Write the prompt file using this format:

     ```
     prompt-lib save <name> <<'PROMPT_EOF'
     ---
     description: <description>
     category: <category>
     tags: [tag1, tag2]
     ---

     <prompt content here>
     PROMPT_EOF
     ```
   - After saving, tell the user: "Load it anytime with `/prompt:<name>`"

3. **Loading a prompt** (`/prompt load <name>`):
   - Run `prompt-lib load <name>` and display the content.
   - Ask if the user wants to use it as-is or modify it.
   - Tell the user they can load it directly next time with `/prompt:<name>` from the autocomplete.

4. **Editing a prompt** (`/prompt edit <name>`):
   - Run `prompt-lib edit <name>` to get the file path.
   - Read the file with the Read tool.
   - Help the user make changes, then write back with Edit tool.

5. **Searching** (`/prompt search <query>`):
   - Run the search and display results clearly.
