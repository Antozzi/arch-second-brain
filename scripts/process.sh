#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# process.sh v2 — оптимизированный: 1 запрос вместо 7, таймаут, фильтр мусора
# Использование: ./scripts/process.sh ARCH-123
# =============================================================================

JIRA="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DIR="$(dirname "$SCRIPT_DIR")"
RAW_DIR="$BRAIN_DIR/raw"
KNOWLEDGE_DIR="$BRAIN_DIR/knowledge"
CLAUDE_MD="$BRAIN_DIR/CLAUDE.md"
MODEL="llama3.1:8b"
OLLAMA_URL="http://localhost:11434/api/generate"
MAX_CHARS=4000    # лимит контента на файл
TIMEOUT=90        # секунд на один запрос

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[process]${NC} $*"; }
info() { echo -e "${BLUE}[process]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}    $*"; }
err()  { echo -e "${RED}[error]${NC}   $*" >&2; }

if [[ -z "$JIRA" ]]; then
  err "Использование: $0 <JIRA-ID>"
  exit 1
fi

RAW_JIRA="$RAW_DIR/$JIRA"
KNOWLEDGE_JIRA="$KNOWLEDGE_DIR/projects/$JIRA"

[[ ! -d "$RAW_JIRA" ]] && { err "Папка не найдена: $RAW_JIRA"; exit 1; }
curl -s --max-time 5 "$OLLAMA_URL" > /dev/null 2>&1 || { err "Ollama не запущена. Запусти: ollama serve &"; exit 1; }
[[ ! -f "$CLAUDE_MD" ]] && { err "CLAUDE.md не найден"; exit 1; }

mkdir -p "$KNOWLEDGE_JIRA"
SYSTEM_PROMPT="$(cat "$CLAUDE_MD")"
COUNT_OK=0; COUNT_SKIP=0; COUNT_ERR=0

log "Тикет: $JIRA | Модель: $MODEL | Лимит: ${MAX_CHARS} символов | Таймаут: ${TIMEOUT}с"
echo ""

# --- файлы без архитектурного смысла — пропускаем ---
is_noise() {
  local name
  name="$(basename "$1" | tr '[:upper:]' '[:lower:]')"
  case "$name" in
    *zoom*|*git-setup*|*quick-start*|*howto*|\
    *project-info*|*project-structure*|\
    *index.md*) return 0 ;;
  esac
  return 1
}

mark_processed() {
  sed -i '' 's/^processed: false/processed: true/' "$1"
}

get_frontmatter() {
  grep "^${2}:" "$1" | head -1 | sed "s/^${2}: *//" | tr -d '"'
}

# --- один запрос → JSON со всеми измерениями ---
call_ollama_single() {
  local content="$1"
  local ref="$2"
  local doc_type="$3"

  local spfa_instruction=""
  [[ "$doc_type" == "spfa" ]] && spfa_instruction='
8. "spfa": массив SPFA оценок вендора (если есть): [{id, vendor, status, findings, tco, source}]'

  local prompt="Документ: $ref
Тип: $doc_type

$content

---
Проанализируй документ и извлеки знания в формате JSON.
Верни ТОЛЬКО валидный JSON без markdown-обёртки, без пояснений.

Структура ответа:
{
  \"business_context\": [{\"id\": \"BC-001\", \"title\": \"\", \"problem\": \"\", \"goals\": \"\", \"scope_in\": \"\", \"scope_out\": \"\", \"source\": \"$ref\", \"tags\": \"#business-context\"}],
  \"requirements\": [{\"id\": \"BR-001\", \"title\": \"\", \"type\": \"Functional|NFR|Security|Constraint|Assumption\", \"description\": \"\", \"priority\": \"Must|Should|Could\", \"source\": \"$ref\", \"tags\": \"#requirement\"}],
  \"architecture\": [{\"id\": \"ARCH-001\", \"title\": \"\", \"type\": \"AS-IS|TO-BE|Integration|Scenario\", \"description\": \"\", \"systems\": \"\", \"protocol\": \"\", \"source\": \"$ref\", \"tags\": \"#architecture\"}],
  \"adrs\": [{\"id\": \"ADR-001\", \"title\": \"\", \"status\": \"Proposed|Accepted\", \"context\": \"\", \"decision\": \"\", \"alternatives\": \"\", \"consequences\": \"\", \"source\": \"$ref\", \"tags\": \"#adr\"}],
  \"risks\": [{\"id\": \"R-001\", \"title\": \"\", \"category\": \"Technical|Integration|Security|Vendor|Timeline\", \"impact\": \"High|Medium|Low\", \"probability\": \"High|Medium|Low\", \"mitigation\": \"\", \"source\": \"$ref\", \"tags\": \"#risk\"}],
  \"open_questions\": [{\"id\": \"Q-001\", \"question\": \"\", \"context\": \"\", \"affects\": \"HLD|ADR|Requirements|Architecture\", \"owner\": \"\", \"urgency\": \"Blocker|High|Normal\", \"source\": \"$ref\", \"tags\": \"#open-question\"}],
  \"stakeholders\": [{\"id\": \"S-001\", \"role\": \"\", \"project\": \"$JIRA\", \"interests\": \"\", \"raci\": \"Responsible|Accountable|Consulted|Informed\", \"source\": \"$ref\", \"tags\": \"#stakeholder\"}]${spfa_instruction}
}

Правила:
- Если данных для категории нет — верни пустой массив []
- НЕ используй реальные имена людей — только роли
- Каждое поле source = \"$ref\"
- Только факты из документа; домыслы помечай тегом #hypothesis"

  curl -s --max-time "$TIMEOUT" -X POST "$OLLAMA_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "$MODEL" \
      --arg system "$SYSTEM_PROMPT" \
      --arg prompt "$prompt" \
      '{model: $model, system: $system, prompt: $prompt, stream: false, options: {temperature: 0.1, num_ctx: 8192}}'
    )" | jq -r '.response // empty'
}

# --- JSON → markdown файлы ---
json_to_files() {
  local json="$1"

  # вырезаем JSON если модель добавила текст вокруг
  json="$(echo "$json" | sed -n '/^{/,/^}/p' | head -200)"
  [[ -z "$json" ]] && return

  # функция записи секции
  write_section() {
    local key="$1" file="$2" header="$3"
    local items
    items="$(echo "$json" | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  items=d.get('$key',[])
  if not items: sys.exit(0)
  for i in items:
    print('## ' + i.get('id','?') + ' ' + (i.get('title') or i.get('role') or i.get('question','?')))
    for k,v in i.items():
      if k not in ('id','title','role','question') and v:
        print('- **' + k.capitalize() + '**: ' + str(v))
    print()
except: pass
" 2>/dev/null)"
    [[ -z "$items" ]] && return
    local target="$KNOWLEDGE_JIRA/$file"
    if [[ ! -f "$target" ]]; then
      printf "# %s — %s\n\n%s\n" "$header" "$JIRA" "$items" > "$target"
      log "Создан: $file"
    else
      printf "\n---\n\n%s\n" "$items" >> "$target"
      log "Обновлён: $file"
    fi
  }

  write_section "business_context"  "business-context.md"  "Бизнес-контекст"
  write_section "requirements"      "requirements.md"       "Требования"
  write_section "architecture"      "architecture.md"       "Архитектура решения"
  write_section "adrs"              "adrs.md"               "Architecture Decision Records"
  write_section "risks"             "risks.md"              "Риски"
  write_section "open_questions"    "open-questions.md"     "Открытые вопросы"
  write_section "stakeholders"      "stakeholders.md"       "Стейкхолдеры"
  write_section "spfa"              "spfa-assessment.md"    "SPFA Оценка вендора"
}

detect_doc_type() {
  local name
  name="$(basename "$1" | tr '[:upper:]' '[:lower:]')"
  echo "$name" | grep -qi "spfa\|feasibility\|vendor\|assessment" && echo "spfa" && return
  echo "$name" | grep -qi "hld\|high.level" && echo "hld" && return
  echo "$name" | grep -qi "bazaar\|справка\|an-" && echo "an" && return
  echo "generic"
}

# --- основной цикл ---
TOTAL="$(find "$RAW_JIRA" -name "*.md" -type f | wc -l | tr -d ' ')"
CURRENT=0

while IFS= read -r -d '' filepath; do
  filename="$(basename "$filepath")"
  ((CURRENT++))
  processed="$(get_frontmatter "$filepath" "processed")"

  if [[ "$processed" == "true" ]]; then
    info "[$CURRENT/$TOTAL] Пропускаю (обработан): $filename"
    ((COUNT_SKIP++))
    continue
  fi

  if is_noise "$filepath"; then
    info "[$CURRENT/$TOTAL] Пропускаю (не архитектурный): $filename"
    mark_processed "$filepath"
    ((COUNT_SKIP++))
    continue
  fi

  log "[$CURRENT/$TOTAL] Обрабатываю: $filename"

  content="$(awk '/^---/{found++; if(found==2){skip=0; next}} found<2{next} {print}' "$filepath" | head -c $MAX_CHARS)"

  if [[ -z "$(echo "$content" | tr -d '[:space:]')" ]]; then
    warn "Пустой контент — пропускаю"
    mark_processed "$filepath"
    ((COUNT_SKIP++))
    continue
  fi

  doc_type="$(detect_doc_type "$filepath")"
  ref="[[${filename%.md}]]"

  info "  → 1 запрос (тип: $doc_type, размер: $(echo "$content" | wc -c | tr -d ' ') символов)..."

  response="$(call_ollama_single "$content" "$ref" "$doc_type")"

  if [[ -z "$response" ]]; then
    warn "  Таймаут или пустой ответ — пропускаю: $filename"
    ((COUNT_ERR++))
  else
    json_to_files "$response"
    ((COUNT_OK++))
  fi

  mark_processed "$filepath"
  echo ""

done < <(find "$RAW_JIRA" -name "*.md" -type f -print0)

echo ""
log "=== Готово ==="
echo -e "  ${GREEN}✓ Обработано:${NC}  $COUNT_OK"
echo -e "  ${YELLOW}⊘ Пропущено:${NC}   $COUNT_SKIP"
echo -e "  ${RED}✗ Таймауты:${NC}    $COUNT_ERR"
echo ""
log "База знаний: $KNOWLEDGE_JIRA"
ls "$KNOWLEDGE_JIRA/" 2>/dev/null | while read f; do echo "  - $f"; done
