#!/usr/bin/env bash

# note_lib.sh — Shared library for note_search.sh and snippet-holder
# Code block extraction, clipboard/typing, code index, block-to-folder save
#
# Usage: source /home/val/.local/bin/note_lib.sh

NOTE_LIB_VAULT="${NOTE_LIB_VAULT:-${NOTES:-$HOME/Documentos/Notes}}"
NOTE_LIB_SNIPPETS="$NOTE_LIB_VAULT/01 Snippets"
NOTE_LIB_INDEX_FILE="$HOME/.local/share/note-workspaces/code-index.tsv"
NOTE_LIB_INDEX_MAX_AGE=86400


# =============================================================================
# Utility
# =============================================================================

note_lib_safe_filename() {
    local name="$1"
    name="${name//[\/:*?\"<>|]/-}"
    while [[ "$name" == *[[:space:]] ]]; do
        name="${name%?}"
    done
    printf '%s' "$name"
}

_note_lib_read_field() {
    local file="$1" field="$2"
    [[ ! -f "$file" ]] && return 1
    awk -v field="$field" '
        BEGIN { in_front = 0 }
        /^---[[:space:]]*$/ {
            if (!in_front) { in_front = 1; next }
            else exit
        }
        in_front && index($0, field ":") == 1 {
            val = $0
            sub(/^[^:]*:[[:space:]]*/, "", val)
            gsub(/^"|"$/, "", val)
            print val
            exit
        }
    ' "$file"
}

note_lib_ensure_dirs() {
    mkdir -p "$(dirname "$NOTE_LIB_INDEX_FILE")" "$NOTE_LIB_SNIPPETS"
}


# =============================================================================
# Code Block Extraction
# =============================================================================

# Output TSV per block: block_index \t language \t line_start \t line_end \t preview
note_lib_extract_blocks() {
    local file="$1"
    [[ ! -f "$file" ]] && return 1
    awk '
        BEGIN { in_block = 0; block_idx = 0 }
        /^```/ {
            if (!in_block) {
                in_block = 1; block_idx++
                lang = $0; sub(/^```/, "", lang)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", lang)
                line_start = NR + 1; first_line = ""
                next
            } else {
                preview = (first_line != "") ? first_line : "(empty)"
                if (length(preview) > 80) preview = substr(preview, 1, 77) "..."
                printf "%d\t%s\t%d\t%d\t%s\n", block_idx, lang, line_start, NR - 1, preview
                in_block = 0; next
            }
        }
        in_block && NR >= line_start && first_line == "" { first_line = $0 }
    ' "$file"
}

note_lib_block_content() {
    local file="$1" target="${2:-1}"
    [[ ! -f "$file" ]] && return 1
    awk -v target="$target" '
        /^```/ {
            if (!in_block) { in_block = 1; block_idx++; next }
            else { if (block_idx == target) exit; in_block = 0; next }
        }
        in_block && block_idx == target { print }
    ' "$file"
}

note_lib_block_preview() {
    local file="$1" target="${2:-1}" max="${3:-15}"
    note_lib_block_content "$file" "$target" | head -n "$max"
}


# =============================================================================
# Block Save — create .md file in a target folder
# =============================================================================

# Save a code block as a .md snippet file inside a target directory.
# Creates the directory if it doesn't exist.
# Returns: path of the created file on stdout.
# Usage: note_lib_save_block <source_file> [block_index] <target_dir>
note_lib_save_block() {
    local source_file="$1"
    local block_index="${2:-1}"
    local target_dir="$3"
    [[ ! -f "$source_file" ]] && return 1
    [[ -z "$target_dir" ]] && return 1

    mkdir -p "$target_dir"

    local language content block_info source_rel
    source_rel="${source_file#$NOTE_LIB_VAULT/}"

    block_info=$(note_lib_extract_blocks "$source_file" | awk -v idx="$block_index" '$1 == idx')
    if [[ -n "$block_info" ]]; then
        language=$(printf '%s' "$block_info" | cut -f2)
        content=$(note_lib_block_content "$source_file" "$block_index")
    else
        language="text"
        content=$(cat "$source_file")
    fi

    local base="${source_file##*/}"
    local item_name
    item_name=$(note_lib_safe_filename "${base%.md}")
    if (( block_index > 1 )); then
        item_name="${item_name}-bloco-${block_index}"
    fi

    local item_file="$target_dir/${item_name}.md" counter=1
    while [[ -f "$item_file" ]]; do
        item_file="$target_dir/${item_name}-${counter}.md"
        ((counter++))
    done

    {
        printf '%s\n' '---'
        printf 'source: "%s"\n' "$source_rel"
        printf 'block: %s\n' "$block_index"
        printf 'language: %s\n' "${language:-text}"
        printf 'added: %s\n' "$(date +%Y-%m-%d)"
        printf 'tags: []\n'
        printf '%s\n\n' '---'
        printf '%s%s\n' '```' "${language:-}"
        printf '%s\n' "$content"
        printf '%s\n' '```'
    } > "$item_file"

    printf '%s' "$item_file"
}

# List subfolders inside 01 Snippets (workspaces = folders).
note_lib_list_snippet_folders() {
    local snippets_dir="${1:-$NOTE_LIB_SNIPPETS}"
    [[ ! -d "$snippets_dir" ]] && return 0
    local d
    for d in "$snippets_dir"/*/; do
        [[ -d "$d" ]] || continue
        local name
        name="$(basename "$d")"
        [[ "$name" == .* ]] && continue
        local count
        count=$(find "$d" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l)
        printf '%s\t%s\n' "$name" "$count"
    done
}


# =============================================================================
# Clipboard & Typing
# =============================================================================

note_lib_clipboard_copy() {
    local text="$1"
    if command -v wl-copy >/dev/null 2>&1 && [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        printf '%s' "$text" | wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s' "$text" | xclip -selection clipboard
    elif command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$text" | wl-copy
    else
        return 1
    fi
}

note_lib_type_text() {
    local text="$1" delay="${2:-50}"
    if ! command -v xdotool >/dev/null 2>&1; then
        note_lib_clipboard_copy "$text"
        return 1
    fi
    if (( ${#text} > 5000 )); then
        text="${text:0:5000}"
    fi
    xdotool type --delay "$delay" --clearmodifiers -- "$text"
}


# =============================================================================
# Code Index
# =============================================================================

# Index format (TSV): file_path \t block_index \t language \t preview \t line_start \t line_end
note_lib_build_code_index() {
    local vault="${1:-$NOTE_LIB_VAULT}"
    local index_file="$NOTE_LIB_INDEX_FILE"
    mkdir -p "$(dirname "$index_file")"

    local files=()
    while IFS= read -r f; do
        [[ "$f" =~ /(\.obsidian|\.config|\.data|\.cache|01 Snippets)/ ]] && continue
        files+=("$f")
    done < <(rg --files -g "*.md" "$vault" 2>/dev/null)

    if (( ${#files[@]} == 0 )); then
        : > "$index_file"
        return 0
    fi

    local tmp="${index_file}.tmp"
    awk -v prefix="$vault/" '
        FNR == 1 {
            in_block = 0; block_idx = 0
            rel = FILENAME
            n = index(rel, prefix)
            if (n == 1) rel = substr(rel, length(prefix) + 1)
        }
        /^```/ {
            if (!in_block) {
                in_block = 1; block_idx++
                lang = $0; sub(/^```/, "", lang)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", lang)
                line_start = FNR + 1; first_line = ""
                next
            } else {
                preview = (first_line != "") ? first_line : "(empty)"
                if (length(preview) > 80) preview = substr(preview, 1, 77) "..."
                printf "%s\t%d\t%s\t%s\t%d\t%d\n", rel, block_idx, lang, preview, line_start, FNR - 1
                in_block = 0; next
            }
        }
        in_block && FNR >= line_start && first_line == "" { first_line = $0 }
    ' "${files[@]}" > "$tmp"

    mv "$tmp" "$index_file"
}

note_lib_index_age() {
    local index_file="$NOTE_LIB_INDEX_FILE"
    if [[ ! -f "$index_file" ]]; then echo "999999999"; return; fi
    local now file_ts
    now=$(date +%s)
    file_ts=$(stat -c %Y "$index_file" 2>/dev/null || echo 0)
    echo $(( now - file_ts ))
}

note_lib_index_stale() {
    local age; age=$(note_lib_index_age)
    (( age > NOTE_LIB_INDEX_MAX_AGE ))
}

note_lib_search_index() {
    local query="$1" index_file="$NOTE_LIB_INDEX_FILE"
    [[ ! -f "$index_file" ]] && return 1
    [[ -z "$query" ]] && return 1
    rg --no-line-number --color=never --smart-case -- "$query" "$index_file" 2>/dev/null
}
