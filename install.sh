#!/usr/bin/env bash
#
# install.sh — Instala obsidian-code-search no sistema
#
# Uso:
#   ./install.sh              # instalação normal
#   ./install.sh --check      # só verifica dependências
#   ./install.sh --uninstall  # remove os arquivos instalados
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
DATA_DIR="$HOME/.local/share/note-workspaces"
NOTES_DIR="${NOTES:-$HOME/Documentos/Notes}"
SNIPPETS_DIR="$NOTES_DIR/01 Snippets"

# ── Cores ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { local fmt="$1"; shift; printf "${BLUE}${fmt}${NC}\n" "$@"; }
ok()    { local fmt="$1"; shift; printf "${GREEN}✓ ${fmt}${NC}\n" "$@"; }
warn()  { local fmt="$1"; shift; printf "${YELLOW}⚠ ${fmt}${NC}\n" "$@"; }
err()   { local fmt="$1"; shift; printf "${RED}✗ ${fmt}${NC}\n" "$@"; }

# ── Verificar dependências ───────────────────────────────────────────
check_deps() {
    local missing=0

    local deps=(
        "bash:bash 4+:runtime"
        "fzf:fzf 0.50+:interface terminal"
        "rg:ripgrep 14+:busca de conteúdo"
        "rofi:rofi 1.7+:interface GUI"
        "glow:glow:preview markdown"
        "awk:awk (gawk/mawk):processamento de texto"
        "xclip:xclip:clipboard X11"
        "xdotool:xdotool:autodigitação"
    )

    printf '\n'
    info "Verificando dependências..."
    printf '%s\n' "----------------------------------------------"

    for dep in "${deps[@]}"; do
        IFS=':' read -r cmd name purpose <<< "$dep"
        if command -v "$cmd" &>/dev/null; then
            ok "%-20s %-25s (%s)" "$cmd" "$name" "$purpose"
        else
            err "%-20s %-25s (%s) — NÃO ENCONTRADO" "$cmd" "$name" "$purpose"
            missing=$((missing + 1))
        fi
    done

    printf '%s\n' "----------------------------------------------"

    if [[ $missing -gt 0 ]]; then
        err "Faltam $missing dependências."
        printf '\n'
        info "Instalar no Debian/Ubuntu:"
        printf '  sudo apt install fzf ripgrep rofi xclip xdotool gawk\n'
        printf '  # glow: https://github.com/charmbracelet/glow/releases\n'
        return 1
    fi

    ok "Todas as dependências encontradas."
    return 0
}

# ── Criar diretórios ─────────────────────────────────────────────────
setup_dirs() {
    mkdir -p "$BIN_DIR"
    mkdir -p "$DATA_DIR"
    ok "Diretórios criados: $BIN_DIR, $DATA_DIR"
}

# ── Instalar scripts ─────────────────────────────────────────────────
install_scripts() {
    info "Instalando scripts em $BIN_DIR..."

    # note_lib.sh — biblioteca compartilhada
    cp "$SCRIPT_DIR/note_lib.sh" "$BIN_DIR/note_lib.sh"
    chmod 644 "$BIN_DIR/note_lib.sh"
    ok "note_lib.sh → $BIN_DIR/note_lib.sh"

    # note_search.sh — busca no terminal
    cp "$SCRIPT_DIR/note_search.sh" "$BIN_DIR/note_search.sh"
    chmod 755 "$BIN_DIR/note_search.sh"
    ok "note_search.sh → $BIN_DIR/note_search.sh"

    # snippet-holder — gerenciador GUI
    # Se o dotfile repo existe, cria symlink; senão copia
    local dotfile_snippet="$HOME/Documentos/Github/dotfile/bin/snippet-holder"
    local target="$BIN_DIR/snippet-holder"

    if [[ -f "$dotfile_snippet" ]]; then
        # Remover arquivo antigo antes de criar symlink
        if [[ -L "$target" ]]; then
            rm "$target"
        elif [[ -f "$target" ]]; then
            rm "$target"
        fi
        ln -s "$dotfile_snippet" "$target"
        ok "snippet-holder → symlink para $dotfile_snippet"
    else
        cp "$SCRIPT_DIR/snippet-holder" "$target"
        chmod 755 "$target"
        ok "snippet-holder → $BIN_DIR/snippet-holder (cópia)"
    fi
}

# ── Configurar aliases ───────────────────────────────────────────────
setup_aliases() {
    local shell_rc=""
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_rc="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        shell_rc="$HOME/.zshrc"
    else
        warn "Não encontrei .bashrc ou .zshrc. Adicione manualmente:"
        printf '  source %s/note_search.sh\n' "$BIN_DIR"
        return
    fi

    # Verificar se já existe
    if grep -q 'source.*note_search.sh' "$shell_rc" 2>/dev/null; then
        ok "Aliases já configurados em $shell_rc"
        return
    fi

    printf '\n# Obsidian Code Search\n' >> "$shell_rc"
    printf 'source %s/note_search.sh\n' "$BIN_DIR" >> "$shell_rc"
    ok "Aliases adicionados ao $shell_rc"
    info "Reinicie o terminal ou execute: source $shell_rc"
}

# ── Configurar diretório de snippets ─────────────────────────────────
setup_snippets() {
    if [[ ! -d "$SNIPPETS_DIR" ]]; then
        mkdir -p "$SNIPPETS_DIR"
        ok "Criado: $SNIPPETS_DIR"
    else
        ok "Snippets dir já existe: $SNIPPETS_DIR"
    fi

    # Criar config padrão se não existe
    local config_file="$SNIPPETS_DIR/.config/config"
    if [[ ! -f "$config_file" ]]; then
        mkdir -p "$SNIPPETS_DIR/.config"
        cat > "$config_file" << 'CONFIG'
NOTES_DIR="$HOME/Documentos/Notes/01 Snippets"
EDITOR_APP="mousepad"
DEFAULT_SORT="recent"
HISTORY_LIMIT="40"
PREVIEW_LINES="5"
CONFIG
        ok "Config padrão criado: $config_file"
    fi
}

# ── Desinstalar ──────────────────────────────────────────────────────
uninstall() {
    info "Removendo instalação..."
    local removed=0

    for f in note_lib.sh note_search.sh snippet-holder; do
        if [[ -e "$BIN_DIR/$f" || -L "$BIN_DIR/$f" ]]; then
            rm "$BIN_DIR/$f"
            ok "Removido: $BIN_DIR/$f"
            removed=$((removed + 1))
        fi
    done

    if [[ $removed -gt 0 ]]; then
        printf '\n'
        warn "Os aliases no .bashrc/.zshrc não foram removidos automaticamente."
        warn "Remova manualmente a linha 'source %s/note_search.sh'" "$BIN_DIR"
        warn "Diretório de dados preservado: $DATA_DIR"
    else
        warn "Nada para remover."
    fi
}

# ── Resumo ───────────────────────────────────────────────────────────
show_summary() {
    printf '\n'
    printf '%s\n' "=============================================="
    info "Instalação concluída!"
    printf '%s\n' "=============================================="
    printf '\n'
    printf '  Aliases disponíveis:\n'
    printf '    nf   — seletor de modo\n'
    printf '    nfn  — buscar por nome\n'
    printf '    nfc  — buscar por conteúdo\n'
    printf '    nfb  — buscar blocos de código\n'
    printf '\n'
    printf '  GUI:\n'
    printf '    snippet-holder\n'
    printf '\n'
    printf '  Vault: %s\n' "$NOTES_DIR"
    printf '  Dados: %s\n' "$DATA_DIR"
    printf '\n'
    info "Reinicie o terminal para usar os aliases."
}

# ── Main ─────────────────────────────────────────────────────────────
main() {
    case "${1:-}" in
        --check)
            check_deps
            exit $?
            ;;
        --uninstall)
            uninstall
            exit 0
            ;;
        --help|-h)
            printf 'Uso: %s [--check|--uninstall|--help]\n' "$(basename "$0")"
            exit 0
            ;;
    esac

    printf '\n'
    info "Obsidian Code Search — Instalador"
    printf '%s\n' "=============================================="

    check_deps || exit 1

    setup_dirs
    install_scripts
    setup_snippets
    setup_aliases

    show_summary
}

main "$@"
