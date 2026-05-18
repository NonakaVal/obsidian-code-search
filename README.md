# Obsidian Code Search

Search, browse, and collect code blocks from your Obsidian vault — directly from the terminal or via a Rofi GUI. Built for Linux (X11/Wayland) with zero config needed.

Three scripts that work together:

| File | Role | Interface |
|---|---|---|
| `note_lib.sh` | Shared library (extraction, index, clipboard, save) | Sourced by the other two |
| `note_search.sh` | Search engine (3 modes: name, content, code blocks) | Terminal / fzf |
| `snippet-holder` | Snippet manager (browser, vault search, workspaces) | GUI / Rofi |

---

## Features

### note_search.sh — Terminal Search (fzf)

- **3 search modes**: by file name, by note content, or by code blocks across the entire vault
- **Code block index**: pre-indexes all code blocks for instant search (~0.2s for 2800+ blocks)
- **Rich preview**: syntax-highlighted markdown via glow, line numbers, search term highlighting
- **Save to workspace**: `ctrl-y` saves any code block to a chosen subfolder inside `01 Snippets/`
- **Multi-block files**: if a file has N code blocks, a sub-selector lets you pick which one
- **Folder selector**: pick from existing subfolders (with snippet counts) or create a new one
- **Keybinds**: `ctrl-r` reload, `ctrl-e` edit, `ctrl-o` toggle sort, `ctrl-y` save to folder

### snippet-holder — GUI Snippet Manager (Rofi)

- **File browser**: navigate `01 Snippets/` with subfolder support, breadcrumb-style
- **Vault-wide block search**: search all code blocks in your vault, then copy/type/save/open source
- **Workspace switching**: `Alt+w` to jump between subfolders without leaving navigation
- **Copy / Type**: copy to clipboard or use xdotool to type directly into your active app
- **Tags**: full Obsidian-compatible tag management (inline, block, scalar formats)
- **History & Favorites**: recent snippets and starred items
- **Settings**: configurable editor, sort order, history limit, preview lines
- **Export/Import**: tar.gz backup and restore

### note_lib.sh — Shared Library

- Code block extraction (TSV output: index, language, line range, preview)
- Block content/preview retrieval
- Save block as .md snippet (with frontmatter: source, block, language, added date, tags)
- List snippet folders with counts
- Clipboard copy (xclip / wl-copy, auto-detects X11 vs Wayland)
- xdotool typing with `--clearmodifiers`
- Code index build/search (TSV, ripgrep-powered, stale-check with configurable TTL)

---

## Requirements

| Tool | Version | Purpose |
|---|---|---|
| bash | 4+ | Runtime |
| fzf | 0.50+ | Terminal search interface |
| ripgrep (rg) | 14+ | Fast file/content search |
| rofi | 1.7+ | GUI menu for snippet-holder |
| glow | any | Markdown preview rendering |
| awk (gawk/mawk) | any | Parsing and extraction |
| xclip | any | Clipboard (X11) |
| xdotool | any | Type text into active window |
| wl-copy | any | Clipboard (Wayland, optional) |

Install on Debian/Ubuntu:

```bash
sudo apt install fzf ripgrep rofi xclip xdotool
# glow — download from https://github.com/charmbracelet/glow/releases
```

---

## Installation

```bash
# 1. Clone
git clone https://github.com/NonakaVal/obsidian-code-search.git
cd obsidian-code-search

# 2. Copy scripts to your PATH
cp note_lib.sh note_search.sh snippet-holder ~/.local/bin/
chmod +x ~/.local/bin/note_search.sh ~/.local/bin/snippet-holder

# 3. Source aliases (add to ~/.bashrc or ~/.zshrc)
source ~/.local/bin/note_search.sh
```

This gives you the shell aliases:
- `nfn` — search notes by file name
- `nfc` — search notes by content
- `nfb` — search code blocks
- `nf`  — mode selector (pick one of the three)

### Keybindings (optional, GNOME)

Register `Super+Shift+s` to open block search in a terminal:

```bash
# Using gsettings (GNOME)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', ..., \
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom31/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom31/ name 'note-search-blocks'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom31/ command \
  "konsole --profile rec -e bash -c 'source ~/.local/bin/note_search.sh && notes_fzf_blocks; exec bash'"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom31/ binding '<Super><Shift>s'
```

Register `Super+s` to open snippet-holder:

```bash
# Similar gsettings command with: rofi -show -modi "snippets:~/.local/bin/snippet-holder"
```

---

## Configuration

### Vault Path

Default vault: `~/Documentos/Notes/`

Override via environment variable:

```bash
export NOTES="$HOME/my-vault"
```

### Snippet Folder

Default: `$NOTES/01 Snippets/`

Subfolders inside `01 Snippets/` are used as workspaces for organizing saved blocks.

### snippet-holder Config

Located at `01 Snippets/.config/config`. Auto-created on first run with defaults:

```bash
NOTES_DIR="$HOME/Documentos/Notes/01 Snippets"
EDITOR_APP="mousepad"
DEFAULT_SORT="recent"
HISTORY_LIMIT="40"
PREVIEW_LINES="5"
```

All settings are editable through the GUI (Settings menu).

### Code Index

Location: `~/.local/share/note-workspaces/code-index.tsv`

Auto-built when stale (older than 24h). Manual rebuild: the index rebuilds on next search automatically, or press `ctrl-r` in fzf.

---

## Usage

### Terminal (note_search.sh)

```bash
# Mode selector
nf

# Direct modes
nfn          # Search by file name
nfc          # Search by content
nfb          # Search code blocks (indexed)
```

**fzf keybinds (all modes):**

| Key | Action |
|---|---|
| `ctrl-r` | Reload / refresh results |
| `ctrl-e` | Open file in editor |
| `ctrl-o` | Toggle sort order |
| `ctrl-y` | Save selected block to a folder |

### GUI (snippet-holder)

Launch:
```bash
snippet-holder
```

**Main menu options:**

| Option | Description |
|---|---|
| Navegar | File browser for `01 Snippets/` |
| Historico | Recently used snippets |
| Favoritos | Starred snippets |
| Buscar por tag | Filter by Obsidian tags |
| Buscar blocos (vault) | Search all code blocks in vault |
| Configuracoes | Edit settings via GUI |
| Exportar | Backup as tar.gz |
| Importar | Restore from tar.gz |

**Browser keybinds (Rofi):**

| Key | Action |
|---|---|
| `Alt+n` | New snippet |
| `Alt+g` | New folder/group |
| `Alt+o` | Toggle sort (recent / A-Z) |
| `Alt+q` | Go up one level |
| `Alt+w` | Switch to any subfolder |

**Block actions (vault search):**

| Action | Description |
|---|---|
| Copiar | Copy code to clipboard |
| Digitar | Type code into active app (xdotool, 500ms delay) |
| Salvar em pasta | Save as .md in chosen subfolder |
| Abrir fonte | Open source note in editor |

---

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Obsidian Vault              │
│          ~/Documentos/Notes/*.md             │
│              (2353 notes)                    │
└──────────────────┬──────────────────────────┘
                   │
          ┌────────┴────────┐
          │   note_lib.sh   │
          │  (shared lib)   │
          │                 │
          │ • Block extract │
          │ • Code index    │
          │ • Save block    │
          │ • Clipboard     │
          │ • xdotool type  │
          └───┬─────────┬───┘
              │         │
   ┌──────────▼──┐  ┌───▼──────────┐
   │note_search  │  │snippet-holder│
   │  (fzf/TTY)  │  │  (Rofi/GUI)  │
   │             │  │              │
   │ 3 modes:    │  │ Browser      │
   │ • name      │  │ Tags         │
   │ • content   │  │ History/Fav  │
   │ • blocks    │  │ Vault search │
   └─────────────┘  └──────────────┘
                          │
                   ┌──────▼──────┐
                   │ 01 Snippets/ │
                   │ (workspaces) │
                   │  └ folder A  │
                   │  └ folder B  │
                   └──────────────┘
```

### Saved Snippet Format

When a code block is saved to a folder, it creates an Obsidian-compatible .md file:

```markdown
---
source: "path/to/original/note.md"
block: 2
language: python
added: 2026-05-18
tags: []
---

\`\`\`python
def example():
    pass
\`\`\`
```

---

## License

MIT
