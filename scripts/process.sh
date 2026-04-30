#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# process.sh — обработка raw/{JIRA-ID}/ через Ollama → knowledge/
# Артефакты: HLD | AN (IT Bazaar) | SPFA | ADR (EACMF)
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

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[process]${NC} $*"; }
info() { echo -e "${BLUE}[process]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}    $*"; }
err()  { echo -e "${RED}[error]${NC}   $*" >&2; }

if [[ -z "$JIRA" ]]; then
  err "Использование: $0 <JIRA-ID>"
  err "Пример: $0 ARCH-123"
  exit 1
fi

RAW_JIRA="$RAW_DIR/$JIRA"
KNOWLEDGE_JIRA="$KNOWLEDGE_DIR/projects/$JIRA"

if [[ ! -d "$RAW_JIRA" ]]; then
  err "Папка не найдена: $RAW_JIRA"
  err "Сначала запусти: ./scripts/ingest.sh $JIRA /path/to/folder"
  exit 1
fi

if ! curl -s "$OLLAMA_URL" > /dev/null 2>&1; then
  err "Ollama не запущена. Запусти: ollama serve &"
  exit 1
fi

if [[ ! -f "$CLAUDE_MD" ]]; then
  err "CLAUDE.md не найден: $CLAUDE_MD"
  exit 1
fi

mkdir -p "$KNOWLEDGE_JIRA"
SYSTEM_PROMPT="$(cat "$CLAUDE_MD")"
COUNT_OK=0; COUNT_SKIP=0

log "Тикет: $JIRA"
log "Модель: $MODEL"
echo ""

mark_processed() {
  sed -i '' 's/^processed: false/processed: true/' "$1"
}

get_frontmatter() {
  grep "^${2}:" "$1" | head -1 | sed "s/^${2}: *//" | tr -d '"'
}

call_ollama() {
  local prompt="$1"
  curl -s -X POST "$OLLAMA_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "$MODEL" \
      --arg system "$SYSTEM_PROMPT" \
      --arg prompt "$prompt" \
      '{model: $model, system: $system, prompt: $prompt, stream: false, options: {temperature: 0.1, num_ctx: 8192}}'
    )" | jq -r '.response // empty'
}

update_knowledge_file() {
  local filename="$1"
  local header="$2"
  local content="$3"
  local target="$KNOWLEDGE_JIRA/${filename}"

  [[ -z "$content" || "$content" == "null" ]] && return
  echo "$content" | grep -qi "НЕТ ДАННЫХ\|нет данных\|NO DATA" && return

  if [[ ! -f "$target" ]]; then
    printf "# %s — %s\n\n%s\n" "$header" "$JIRA" "$content" > "$target"
    log "Создан: $(basename $target)"
  else
    printf "\n---\n\n%s\n" "$content" >> "$target"
    log "Обновлён: $(basename $target)"
  fi
}

detect_doc_type() {
  local name
  name="$(basename "$1" | tr '[:upper:]' '[:lower:]')"
  if echo "$name" | grep -qi "spfa\|feasibility\|vendor\|assessment\|rfp"; then
    echo "spfa"
  elif echo "$name" | grep -qi "hld\|high.level"; then
    echo "hld"
  elif echo "$name" | grep -qi "bazaar\|справка\|an-\|pre.anal"; then
    echo "an"
  else
    echo "generic"
  fi
}

# --- основной цикл ---
while IFS= read -r -d '' filepath; do
  filename="$(basename "$filepath")"
  processed="$(get_frontmatter "$filepath" "processed")"

  if [[ "$processed" == "true" ]]; then
    info "Пропускаю (уже обработан): $filename"
    ((COUNT_SKIP++))
    continue
  fi

  log "Обрабатываю: $filename"
  doc_type="$(detect_doc_type "$filepath")"
  info "Тип: $doc_type"

  content="$(awk '/^---/{found++; if(found==2){skip=0; next}} found<2{next} {print}' "$filepath" | head -c 6000)"

  if [[ -z "$(echo "$content" | tr -d '[:space:]')" ]]; then
    warn "Пустой контент: $filename"
    mark_processed "$filepath"
    ((COUNT_SKIP++))
    continue
  fi

  ref="[[${filename%.md}]]"
  echo ""

  info "→ 1/7 Бизнес-контекст..."
  update_knowledge_file "business-context.md" "Бизнес-контекст" \
    "$(call_ollama "Документ: $ref

$content

---
Извлеки бизнес-контекст: Problem Statement, бизнес-цели, границы scope, архитектурные принципы.
Формат: ## BC-XXX [название]
- **Problem Statement**: ...
- **Бизнес-цели**: ...
- **Границы**: in scope — ...; out of scope — ...
- **Источник**: $ref
- **Теги**: #business-context
Если нет — ответь точно: НЕТ ДАННЫХ")"

  info "→ 2/7 Требования (FR/NFR/Security)..."
  update_knowledge_file "requirements.md" "Требования" \
    "$(call_ollama "Документ: $ref

$content

---
Извлеки требования: функциональные (BR), NFR, требования безопасности, ограничения, assumptions.
Формат: ## BR-XXX [название]
- **Тип**: Functional|NFR|Security|Constraint|Assumption
- **Описание**: ...
- **Приоритет**: Must|Should|Could
- **Источник**: $ref
- **Теги**: #requirement
Если нет — ответь точно: НЕТ ДАННЫХ")"

  info "→ 3/7 Архитектура (AS-IS/TO-BE/интеграции)..."
  update_knowledge_file "architecture.md" "Архитектура решения" \
    "$(call_ollama "Документ: $ref

$content

---
Извлеки архитектурные элементы: AS-IS, TO-BE, интеграционные точки, interfaces inventory, end-to-end сценарии.
Формат: ## ARCH-XXX [название]
- **Тип**: AS-IS|TO-BE|Integration|Scenario
- **Описание**: ...
- **Системы**: ...
- **Протокол**: REST|SOAP|gRPC|MQ|...
- **Источник**: $ref
- **Теги**: #architecture
Если нет — ответь точно: НЕТ ДАННЫХ")"

  info "→ 4/7 ADR..."
  update_knowledge_file "adrs.md" "Architecture Decision Records" \
    "$(call_ollama "Документ: $ref

$content

---
Извлеки архитектурные решения (ADR): явные или подразумеваемые выборы с обоснованием и отклонёнными альтернативами.
Формат: ## ADR-XXX [название]
- **Статус**: Proposed|Accepted|Deprecated
- **Контекст**: ...
- **Решение**: ...
- **Альтернативы отклонены**: вариант — причина
- **Последствия**: ...
- **Источник**: $ref
- **Теги**: #adr #decision
Если нет — ответь точно: НЕТ ДАННЫХ")"

  info "→ 5/7 Риски..."
  update_knowledge_file "risks.md" "Риски" \
    "$(call_ollama "Документ: $ref

$content

---
Извлеки риски: технические, интеграционные, безопасности, реализуемости, вендорские.
Формат: ## R-XXX [название]
- **Категория**: Technical|Integration|Security|Vendor|Timeline
- **Влияние**: High|Medium|Low
- **Вероятность**: High|Medium|Low
- **Митигация**: ...
- **Источник**: $ref
- **Теги**: #risk
Если нет — ответь точно: НЕТ ДАННЫХ")"

  info "→ 6/7 Открытые вопросы..."
  update_knowledge_file "open-questions.md" "Открытые вопросы" \
    "$(call_ollama "Документ: $ref

$content

---
Извлеки открытые вопросы, gap'ы, неопределённости, blocker'ы.
Формат: ## Q-XXX [вопрос]
- **Контекст**: ...
- **Влияние на**: HLD|ADR|Requirements|Architecture
- **Владелец**: роль (не имя)
- **Срочность**: Blocker|High|Normal
- **Источник**: $ref
- **Теги**: #open-question
Если нет — ответь точно: НЕТ ДАННЫХ")"

  info "→ 7/7 Стейкхолдеры..."
  update_knowledge_file "stakeholders.md" "Стейкхолдеры" \
    "$(call_ollama "Документ: $ref

$content

---
Извлеки стейкхолдеров. Только роли, без реальных имён.
Формат: ## S-XXX [роль]
- **Роль**: Product Owner|Architect|Stakeholder|...
- **Проект**: $JIRA
- **Интересы**: ...
- **RACI**: Responsible|Accountable|Consulted|Informed
- **Источник**: $ref
- **Теги**: #stakeholder
Если нет — ответь точно: НЕТ ДАННЫХ")"

  if [[ "$doc_type" == "spfa" ]]; then
    info "→ SPFA оценка вендора..."
    update_knowledge_file "spfa-assessment.md" "SPFA Оценка вендора" \
      "$(call_ollama "Документ: $ref

$content

---
Извлеки оценку вендорского продукта: кандидаты лонг/шорт-лист, точки интеграции, техническая проверка, TCO, итоговый балл.
Формат: ## SPFA-XXX [название продукта]
- **Статус**: Лонг-лист|Шорт-лист|Рекомендован|Отклонён
- **Причина**: ...
- **Ключевые находки**: ...
- **TCO**: ...
- **Источник**: $ref
- **Теги**: #spfa #vendor
Если нет — ответь точно: НЕТ ДАННЫХ")"
  fi

  mark_processed "$filepath"
  ((COUNT_OK++))
  echo ""

done < <(find "$RAW_JIRA" -name "*.md" -type f -print0)

echo ""
log "=== Готово ==="
echo -e "  ${GREEN}✓ Обработано:${NC} $COUNT_OK"
echo -e "  ${YELLOW}⊘ Пропущено:${NC}  $COUNT_SKIP"
echo ""
log "База знаний: $KNOWLEDGE_JIRA"
echo ""
log "Созданные файлы:"
ls "$KNOWLEDGE_JIRA/" 2>/dev/null | while read f; do echo "  - $f"; done
