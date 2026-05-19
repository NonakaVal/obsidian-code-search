# Vault Conventions

Documento de referencia que formaliza os padroes de nomenclatura e organizacao do vault Obsidian. Este documento descreve as convenções existentes — não impõe mudanças.

---

## Estrutura de Pastas (Folder Structure)

O vault utiliza um sistema inspirado em PARA com prefixos numerados para controle de ordenacao.

### Pastas com prefixo numerado

Prefixos numerados garantem ordem fixa no file explorer. Lacunas na numeracao (02, 07) reservam espaco para expansao futura.

| Prefixo | Pasta | Arquivos | Descricao |
|---------|-------|----------|-----------|
| 01 | Snippets | 31 | Code block workspaces. Subpastas = workspaces (ver secao Workspaces) |
| 03 | Config | 4 | Notas de configuracao |
| 04 | Workflow | 8 | Documentacao de workflows |
| 05 | Toolbox | 17 | Ferramentas e funcoes (subpastas: Functions, Image Wag) |
| 06 | Work | 175 | Notas relacionadas a trabalho |
| 08 | Focus Areas | 7 | Topicos de foco atual |

### Outras pastas raiz

Sem prefixo numerado. Ordenacao alfabetica.

| Pasta | Arquivos | Descricao |
|-------|----------|-----------|
| Knowlegde | 1191 | Base de conhecimento (maior pasta do vault) |
| X | 286 | Templates. Subpastas: `X/Template/Format/`, `X/Template/Snippet/` |
| + | 49 | Capturas rapidas (quick captures) |
| Calendar & Review | 517 | Daily notes e reviews |
| Write | 29 | Projetos de escrita |
| V-01 a V-05 | — | Pipeline de producao de video: Ideia, Inspiracoes, Roteiro, Edit, Review |
| Memos | 21 | Memos rapidos |
| Workspaces | 4 | Workspaces de projeto |
| Index & Bases | 6 | Notas indice |
| TaskNotes | 2 | Notas de tarefas |
| z-Media | 1 | Arquivos de midia |

**Convencao:** O prefixo `z-` ordena pastas para o final do file explorer.

---

## Nomenclatura de Arquivos (File Naming)

### Prefixos de arquivo

| Prefixo | Quantidade | Uso | Exemplos |
|---------|-----------|-----|----------|
| `py-` | 7 | Referencias Python | `py-importing-data.md`, `py-pandas-groupby-method.md` |
| `hub-` | 12 | Notas hub/indice que conectam topicos | `hub-python`, `hub-data-wrangling` |
| `flow-` | 8 | Descricoes de workflow/processo | `flow-git-workflow` |
| `arch-` | 3 | Notas de arquitetura | `arch-system-design` |
| `rg-` | 2 | Relacionado a ripgrep | `rg-search-patterns` |
| `board-` | 2 | Boards/dashboards | `board-weekly-review` |

### Estilo de nomenclatura

- Separacao por hifens (`kebab-case`)
- Nomes em ingles
- Nomes descritivos e especificos
- Sem prefixo de data (datas ficam no frontmatter)
- Nomes refletem conteudo, nao formato

---

## Blocos de Codigo (Code Blocks)

Distribuicao de linguagens nos blocos de codigo (2830 blocos em 961 arquivos):

| Linguagem | Quantidade | Notas |
|-----------|-----------|-------|
| (sem label) | 820 | Deveriam especificar a linguagem |
| python | 480 | Maior grupo com label |
| css | 397 | Estilizacao Obsidian |
| bash | 200 | Comandos shell |
| dataview | 178 | Queries Dataview |
| dataviewjs | 147 | Dataview JS |
| javascript | 65 | Codigo JS |
| json | 61 | Configuracoes JSON |
| sql | 54 | Queries SQL |
| ruby | 42 | Codigo Ruby |
| text | 41 | Texto generico |
| button | 37 | Plugin Buttons |
| md | 31 | Markdown |

**Convencao:** Sempre especificar a linguagem no code block para permitir busca. Os 820 blocos sem label sao mais dificeis de encontrar via search.

Exemplo correto:

````markdown
```python
df.groupby("column").mean()
```
````

Exemplo a evitar:

````markdown
```
df.groupby("column").mean()
```
````

---

## Tags

### Estado atual

A maioria das notas tem `tags: []` vazio ou formato bloco. Tags sao usadas de forma inconsistente.

### Uso observado

- **Templates** (`X/Template/Format/`) — definem a estrutura de tags
- **05 Toolbox** — tags como `learning/review`, `component`
- **01 Snippets** — blocos salvos recebem `tags: []`

### Recomendacoes (nao obrigatórias)

- Usar tags hierarquicas: `python/dataframe`, `bash/system`, `workflow/git`
- Categorizar por dominio: `learning`, `component`, `reference`
- Manter tags curtas e buscaveis
- Ser consistente dentro de cada hub/topic

---

## Frontmatter

### Padroes gerais

| Campo | Formato | Exemplo |
|-------|---------|---------|
| title | Texto | `title: Pandas GroupBy` |
| tags | Lista (bloco ou inline) | `tags: [python, dataframe]` |
| dateCreated | Data com wikilink | `dateCreated: "[[2026-05-05]]"` |
| id | Numerico (notas antigas) | `id: 12345` |
| subject | Hub notes como wikilinks | `subject: "[[hub-python]]"` |
| connections | Notas relacionadas como wikilinks | `connections: "[[note-a]], [[note-b]]"` |

### Frontmatter de snippets salvos (01 Snippets)

Campos especificos para blocos de codigo salvos:

```yaml
---
source: path/to/original/file.md
block: 3
language: python
added: 2026-05-05
tags: [python, dataframe]
---
```

| Campo | Descricao |
|-------|-----------|
| source | Caminho relativo do arquivo original |
| block | Indice numerico do bloco no arquivo |
| language | Linguagem do code block |
| added | Data em que foi salvo (YYYY-MM-DD) |
| tags | Lista de tags |

---

## Workspaces (01 Snippets)

Subpastas de `01 Snippets` funcionam como workspaces independentes.

| Workspace | Arquivos | Descricao |
|-----------|----------|-----------|
| 00 Shell commands | 8 | Comandos shell/bash |
| 01 Prompts | 0 | Prompts de IA |
| 03 Scripts | 6 | Scripts completos |
| 04 hendoff sessions | 2 | Notas de handoff |
| 05 Paths | 2 | Referencias de caminhos de arquivo |
| pandas | 2 | Especifico para Pandas |

**Convencoes:**

- Prefixos numerados ordenam workspaces
- Nomes descritivos para o proposito do workspace
- Workspaces sem numero para categorias ad-hoc

---

## Dicas de Busca (Search Tips)

### Busca por prefixo

Usar os prefixos de arquivo para buscar por categoria:

- `py-` para encontrar referencias Python
- `hub-` para encontrar notas indice
- `flow-` para encontrar workflows
- `arch-` para encontrar notas de arquitetura

### Busca por bloco de codigo

- Especificar a linguagem no code block para que seja indexavel
- A linguagem e indexada no `code-index.tsv`
- Blocos sem label (820) sao dificeis de buscar

### Navegacao via hub notes

- Hub notes (`hub-*`) funcionam como pontos de entrada para topicos
- Conectam notas relacionadas via wikilinks e campo `subject` no frontmatter
- Usar hub notes como ponto de partida para explorar um topico

### Wikilinks e conexoes

- Wikilinks (`[[note-name]]`) criam conexoes entre notas
- Aparecem no graph view e no backlinks panel
- Campo `connections` no frontmatter para conexoes explicitas

### Qualidade de preview

- Primeiras linhas da nota aparecem no preview
- Linhas iniciais descritivas melhoram a qualidade do preview
- Evitar comecar notas com metadata ou texto generico

### Indexacao automatica

- Code blocks sao indexados via `note_search.sh`
- O indice inclui: caminho do arquivo, linguagem, conteudo do bloco
- Manter code blocks com label garante indexacao correta
