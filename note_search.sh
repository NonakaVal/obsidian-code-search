#!/usr/bin/env bash


NOTES="$HOME/Documentos/Notes"
PREVIEW_MAX_LINES=120

export NOTES
export PREVIEW_MAX_LINES

source "$HOME/.local/bin/note_lib.sh"

_note_title() {
  local base="${1##*/}"
  local name="${base%.md}"
  name="${name//_/ }"
  printf '%s' "${name//-/ }"
}

_preview_note() {
  local file="$1"
  local name modified lines

  name=$(_note_title "$file")
  modified=$(date -r "$file" "+%d %b %Y  %H:%M" 2>/dev/null || stat -c "%y" "$file" | cut -d. -f1)
  lines=$(wc -l < "$file" 2>/dev/null || echo 0)

  printf "\033[1;32m━━━  %s\033[0m \033[90m│\033[0m \033[36m%s linhas\033[0m \033[90m│\033[0m \033[33m%s\033[0m\n\n" \
    "$name" "$lines" "$modified"

  if (( lines > PREVIEW_MAX_LINES )); then
    glow -s dark "$file" 2>/dev/null | head -n "$PREVIEW_MAX_LINES" \
      || head -n "$PREVIEW_MAX_LINES" "$file"
    printf "\n\033[90m  ─── ⋯ %d de %d linhas ───\033[0m\n" "$PREVIEW_MAX_LINES" "$lines"
  else
    glow -s dark "$file" 2>/dev/null || cat "$file"
  fi
}

_preview_note_line() {
  local file="$1"
  local line="${2:-1}"
  local query="${3:-}"
  local name start end

  [[ -z "$file" || ! -f "$file" ]] && return

  name=$(_note_title "$file")
  start=$(( line > 8 ? line - 8 : 1 ))
  end=$(( line + 35 ))

  printf "\033[1;32m━━━  %s\033[0m \033[90m│\033[0m \033[36mlinha %s\033[0m\n\n" "$name" "$line"

  local output
  output=$(awk -v s="$start" -v e="$end" -v t="$line" \
    'NR>=s && NR<=e {
       n = sprintf("%5d", NR)
       if (NR == t) printf "\033[1;36m%s ▸\033[0m \033[1m%s\033[0m\n", n, $0
       else printf "\033[2;36m%s │\033[0m %s\n", n, $0
     }' "$file")

  if [[ -n "$query" ]]; then
    printf '%s\n' "$output" \
      | GREP_COLORS='mt=01;33' grep -E --color=always -i "${query}|\$" 2>/dev/null \
      || printf '%s\n' "$output"
  else
    printf '%s\n' "$output"
  fi
}

_list_notes_by_name() {
  cd "$NOTES" || return
  local this_year
  this_year=$(date +%Y)

  rg --files -g "*.md" |
    while IFS= read -r path; do
      local label folder modified lines base

      base="${path##*/}"
      label="${base%.md}"
      label="${label//_/ }"
      label="${label//-/ }"

      folder="${path%/*}"
      [[ "$folder" == "$path" ]] && folder="."
      folder="${folder#./}"

      modified=$(date -r "$path" "+%Y %d/%m %H:%M" 2>/dev/null)
      local file_year="${modified%% *}"
      local rest="${modified#* }"
      if [[ "$file_year" == "$this_year" ]]; then
        modified="$rest"
      else
        modified="${rest%% *}/${file_year}"
      fi

      lines=$(wc -l < "$path" 2>/dev/null || echo 0)

      if ((${#folder} > 25)); then
        folder="…/${folder##*/}"
      fi

      printf "%s\t\033[1;32m󰎚 %-38s\033[0m \033[36m%3sl\033[0m\033[90m · \033[33m%s\033[0m\033[90m · \033[34m%s\033[0m\n" \
        "$path" "$label" "$lines" "$modified" "$folder"
    done
}

_search_notes_by_content_query() {
  local q="$1"

  [[ -z "$q" ]] && return

  rg \
    --line-number \
    --no-heading \
    --smart-case \
    -m 5 \
    --glob "*.md" \
    -- "$q" . 2>/dev/null |
    while IFS=: read -r path line text; do
      local label folder base

      path="${path#./}"
      base="${path##*/}"
      label="${base%.md}"
      label="${label//_/ }"
      label="${label//-/ }"
      folder="${path%/*}"
      [[ "$folder" == "$path" ]] && folder="."
      folder="${folder#./}"
      text="${text//$'\t'/    }"

      printf "%s\t%s\t\033[1;32m󰎚 %-34s\033[0m \033[36mL%-4s\033[0m\033[90m · \033[34m%-20s\033[0m \033[37m%s\033[0m\n" \
        "$path" "$line" "$label" "$line" "$folder" "$text"
    done
}

_list_code_blocks() {
  local query="${1:-}"

  if [[ -n "$query" ]]; then
    note_lib_search_index "$query"
  else
    cat "$NOTE_LIB_INDEX_FILE" 2>/dev/null
  fi | awk -F'\t' '{
    file = $1; idx = $2; lang = ($3 != "" ? $3 : "text"); preview = $4
    label = file; sub(/.*\//, "", label); sub(/\.md$/, "", label)
    gsub(/_/, " ", label); gsub(/-/, " ", label)
    folder = file; sub(/\/[^/]*$/, "", folder)
    if (folder == file) folder = "."
    if (length(folder) > 25) { sub(/.*\//, "\xe2\x80\xa6/", folder) }
    printf "%s\t%s\t%s\t\033[1;32m󰎧 %-32s\033[0m \033[36mbloco %s\033[0m\033[90m · \033[33m%s\033[0m\033[90m · \033[34m%s\033[0m \033[37m%s\033[0m\n", \
      file, idx, lang, label, idx, lang, folder, preview
  }'
}

_preview_block() {
  local file="$1" block_idx="${2:-1}" query="${3:-}"
  local name="${file##*/}"
  name="${name%.md}"
  name="${name//_/ }"
  name="${name//-/ }"

  local content
  content=$(note_lib_block_content "$NOTES/$file" "$block_idx")
  local total
  total=$(wc -l <<< "$content")

  printf "\033[1;32m━━━  %s\033[0m \033[90m│\033[0m \033[36mbloco %s\033[0m \033[90m│\033[0m \033[33m%s linhas\033[0m\n\n" \
    "$name" "$block_idx" "$total"

  if [[ -n "$query" ]]; then
    printf '%s\n' "$content" \
      | GREP_COLORS='mt=01;33' grep -E --color=always -i "${query}|\$" 2>/dev/null \
      || printf '%s\n' "$content"
  else
    printf '%s\n' "$content"
  fi
}

_folder_selector() {
    local check_source="${1:-}"
    local check_block="${2:-}"
  source "$HOME/.local/bin/note_lib.sh"
  local snippets="$NOTE_LIB_SNIPPETS"
  local folders
  folders=$(note_lib_list_snippet_folders "$snippets")

    # Build membership info if source/block provided
    local membership_info=""
    if [ -n "$check_source" ] && [ -n "$check_block" ]; then
        note_lib_ensure_workspace_cache
        local containing_ws
        containing_ws=$(note_lib_block_in_workspace "$check_source" "$check_block")
        if [ -n "$containing_ws" ]; then
            membership_info="$containing_ws"
        fi
    fi

    local entries=""
    local ws_num=1
  [[ -n "$folders" ]] && while IFS=$'\t' read -r name count; do
        local indicator=""
        if [ -n "$membership_info" ]; then
            if echo "$membership_info" | grep -qFx "$name"; then
                indicator=" ✓ contains this block"
            fi
        fi
        entries="${entries}${ws_num}. 📁 ${name} (${count} snippets)${indicator}\n"
        ((ws_num++))
  done <<< "$folders"
  entries="$(printf "%b📁 . (raiz)\n+ criar nova pasta" "$entries")"

  local choice
  choice=$(printf '%b' "$entries" | fzf \
    --height=40% --border=rounded \
    --prompt='Salvar em > ' \
    --header='Selecione a pasta de destino' \
    --color='bg:#0d1117,bg+:#161b22,fg:#39d353,fg+:#aff5b4,hl:#58a6ff,hl+:#79c0ff,prompt:#ffa657,info:#8b949e,border:#30363d')
  [[ -z "$choice" ]] && return 1

  if [[ "$choice" == "+ criar nova pasta" ]]; then
    local name
    name=$(fzf --height=20% --border=rounded --prompt='Nome pasta > ' --no-info \
      --color='bg:#0d1117,bg+:#161b22,fg:#39d353,fg+:#aff5b4,hl:#58a6ff,hl+:#79c0ff,prompt:#39d353,info:#8b949e,border:#30363d' \
      --print-query </dev/null 2>&1 | head -1)
    [[ -z "$name" ]] && return 1
    local clean
    clean=$(note_lib_safe_filename "$name")
    printf '%s' "$snippets/$clean"
  elif [[ "$choice" == "📁 . (raiz)" ]]; then
    printf '%s' "$snippets"
    else
        local folder_name
        folder_name=$(echo "$choice" | sed 's/^[0-9]*\. 📁 //' | sed 's/^📁 //' | sed 's/ ([0-9]* snippets.*$//' | sed 's/ ✓.*$//')
        printf '%s' "$snippets/$folder_name"
  fi
}

_send_to_workspace_name() {
  local rel_path="$1"
  source "$HOME/.local/bin/note_lib.sh"

  local block_count
  block_count=$(note_lib_extract_blocks "$NOTES/$rel_path" | wc -l)
  local block_idx=1

  if (( block_count == 0 )); then
    block_idx=0
  elif (( block_count > 1 )); then
    block_idx=$(_block_selector "$rel_path")
    [[ -z "$block_idx" ]] && return 0
  fi

  local target_dir
  target_dir=$(_folder_selector "$rel_path" "$block_idx") || return 0
  [[ -z "$target_dir" ]] && return 0

  if (( block_idx == 0 )); then
    note_lib_save_block "$NOTES/$rel_path" 1 "$target_dir"
  else
    note_lib_save_block "$NOTES/$rel_path" "$block_idx" "$target_dir"
  fi

  notify-send "note_search" "✓ salvo em '$(basename "$target_dir")/'" 2>/dev/null || true
}

_send_to_workspace_content() {
  local rel_path="$1" line="$2"
  source "$HOME/.local/bin/note_lib.sh"

  local block_idx
  block_idx=$(note_lib_extract_blocks "$NOTES/$rel_path" \
    | awk -v target="$line" '$3 <= target && $4 >= target { print $1; exit }')

  if [[ -z "$block_idx" ]]; then
    block_idx=1
  fi

  local target_dir
  target_dir=$(_folder_selector "$rel_path" "$block_idx") || return 0
  [[ -z "$target_dir" ]] && return 0

  note_lib_save_block "$NOTES/$rel_path" "$block_idx" "$target_dir"
  notify-send "note_search" "✓ salvo em '$(basename "$target_dir")/'" 2>/dev/null || true
}

_send_to_workspace_block() {
  local rel_path="$1" block_idx="${2:-1}"
  source "$HOME/.local/bin/note_lib.sh"

  local target_dir
  target_dir=$(_folder_selector "$rel_path" "$block_idx") || return 0
  [[ -z "$target_dir" ]] && return 0

  note_lib_save_block "$NOTES/$rel_path" "$block_idx" "$target_dir"
  notify-send "note_search" "✓ salvo em '$(basename "$target_dir")/'" 2>/dev/null || true
}

_block_selector() {
  local file="$1"
  local blocks
  blocks=$(note_lib_extract_blocks "$NOTES/$file")

  local choice
  choice=$(
    printf '%s\n' "$blocks" | while IFS=$'\t' read -r idx lang start end preview; do
      printf "bloco %s\t%s\t%s\n" "$idx" "${lang:-text}" "$preview"
    done | fzf \
      --height=40% --border=rounded \
      --with-nth=1..3 --delimiter=$'\t' \
      --prompt='Bloco > ' \
      --color='bg:#0d1117,bg+:#161b22,fg:#39d353,fg+:#aff5b4,hl:#58a6ff,hl+:#79c0ff,prompt:#ffa657,info:#8b949e,border:#30363d'
  )
  [[ -n "$choice" ]] && awk '{print $2}' <<< "$choice"
}

export -f _note_title
export -f _preview_note
export -f _preview_note_line
export -f _list_notes_by_name
export -f _search_notes_by_content_query
export -f _list_code_blocks
export -f _preview_block
export -f _folder_selector
export -f _block_selector
export -f _send_to_workspace_name
export -f _send_to_workspace_content
export -f _send_to_workspace_block

notes_fzf_name() {
  cd "$NOTES" || return

  local selected

  selected=$(
    _list_notes_by_name |
      fzf \
        --with-nth=2 \
        --delimiter=$'\t' \
        --preview='bash -c '\''_preview_note "$1"'\'' _ {1}' \
        --preview-window='right:65%:wrap:border-left' \
        --bind='ctrl-r:reload(bash -c '\''_list_notes_by_name'\'')' \
        --bind='ctrl-e:execute(${EDITOR:-nano} {1} < /dev/tty > /dev/tty 2>&1)' \
        --bind='ctrl-o:toggle-sort' \
        --bind='ctrl-y:execute(bash -c '\''source ~/.local/bin/note_search.sh && _send_to_workspace_name "$1"'\'' _ {1})' \
        --header='ctrl-r atualizar  ·  ctrl-e editar  ·  ctrl-o ordenar  ·  ctrl-y workspace' \
        --ansi \
        --prompt='Nome > ' \
        --height=95% \
        --border=rounded \
        --color='bg:#0d1117,bg+:#161b22,fg:#39d353,fg+:#aff5b4,hl:#58a6ff,hl+:#79c0ff,prompt:#39d353,info:#8b949e,border:#30363d'
  )

  [[ -n "$selected" ]] && cut -f1 <<< "$selected"
}

notes_fzf_content() {
  cd "$NOTES" || return

  local selected

  selected=$(
    printf '' |
      fzf \
        --disabled \
        --ansi \
        --delimiter=$'\t' \
        --with-nth=3 \
        --bind='change:reload:bash -c '\''_search_notes_by_content_query "$1"'\'' _ {q}' \
        --preview='bash -c '\''_preview_note_line "$1" "$2" "$3"'\'' _ {1} {2} {q}' \
        --preview-window='right:68%:wrap:border-left' \
        --bind='ctrl-r:reload:bash -c '\''_search_notes_by_content_query "$1"'\'' _ {q}' \
        --bind='ctrl-e:execute(${EDITOR:-nano} {1} < /dev/tty > /dev/tty 2>&1)' \
        --bind='ctrl-o:toggle-sort' \
        --bind='ctrl-y:execute(bash -c '\''source ~/.local/bin/note_search.sh && _send_to_workspace_content "$1" "$2"'\'' _ {1} {2})' \
        --header='ctrl-r atualizar  ·  ctrl-e editar  ·  ctrl-o ordenar  ·  ctrl-y workspace' \
        --prompt='Conteúdo > ' \
        --height=95% \
        --border=rounded \
        --color='bg:#0d1117,bg+:#161b22,fg:#39d353,fg+:#aff5b4,hl:#58a6ff,hl+:#79c0ff,prompt:#ffa657,info:#8b949e,border:#30363d'
  )

  [[ -n "$selected" ]] && cut -f1 <<< "$selected"
}

notes_fzf_blocks() {
  cd "$NOTES" || return

  if note_lib_index_stale; then
    note_lib_build_code_index
  fi

  local selected
  selected=$(
    _list_code_blocks |
      fzf \
        --disabled \
        --ansi \
        --delimiter=$'\t' \
        --with-nth=4 \
        --bind='change:reload:bash -c '\''source ~/.local/bin/note_search.sh && _list_code_blocks "$1"'\'' _ {q}' \
        --bind='ctrl-r:reload:bash -c '\''source ~/.local/bin/note_search.sh && note_lib_build_code_index && _list_code_blocks "$1"'\'' _ {q}' \
        --preview='bash -c '\''source ~/.local/bin/note_search.sh && _preview_block "$1" "$2" "$3"'\'' _ {1} {2} {q}' \
        --preview-window='right:65%:wrap:border-left' \
        --bind='ctrl-e:execute(${EDITOR:-nano} {1} < /dev/tty > /dev/tty 2>&1)' \
        --bind='ctrl-o:toggle-sort' \
        --bind='ctrl-y:execute(bash -c '\''source ~/.local/bin/note_search.sh && _send_to_workspace_block "$1" "$2"'\'' _ {1} {2})' \
        --header='ctrl-r atualizar  ·  ctrl-e editar  ·  ctrl-o ordenar  ·  ctrl-y workspace' \
        --prompt='Blocos > ' \
        --height=95% \
        --border=rounded \
        --color='bg:#0d1117,bg+:#161b22,fg:#39d353,fg+:#aff5b4,hl:#58a6ff,hl+:#79c0ff,prompt:#f778ba,info:#8b949e,border:#30363d'
  )

  [[ -n "$selected" ]] && cut -f1 <<< "$selected"
}

nf() {
  local mode

  mode=$(
    printf "nome\t󰈙  Buscar por nome do arquivo\nconteudo\t󰱼  Buscar dentro do conteúdo das notas\nblocos\t󰎧  Buscar blocos de código\n" |
      fzf \
        --with-nth=2 \
        --delimiter=$'\t' \
        --ansi \
        --prompt='Modo > ' \
        --height=40% \
        --border=rounded \
        --color='bg:#0d1117,bg+:#161b22,fg:#39d353,fg+:#aff5b4,hl:#58a6ff,hl+:#79c0ff,prompt:#39d353,info:#8b949e,border:#30363d'
  )

  case "$mode" in
    nome*) notes_fzf_name ;;
    conteudo*) notes_fzf_content ;;
    blocos*) notes_fzf_blocks ;;
  esac
}

alias nfn='notes_fzf_name'
alias nfc='notes_fzf_content'
alias nfb='notes_fzf_blocks'
