#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# process.sh — обработка raw/{JIRA-ID}/ через Ollama → knowledge/
# Использование: ./scripts/process.sh ARCH-42
# =============================================================================

JIRA="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DIR="$(dirname "$SCRIPT_DIR")"
RAW_DIR="$BRAIN_DIR/raw"
KNOWLEDGE_DIR="$BRAIN_DIR/knowledge"
CLAUDE_MD="$BRAIN_DIR/CLAUDE.md"
MODEL="llama3.1:8b"
OLLAMA_URL="http://localhost:11434/api/generate"

# --- цвета ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[process]${NC} $*"; }
info() { echo -e "${BLUE}[process]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}    $*"; }
err()  { echo -e "${RED}[error]${NC}   $*" >&2; }

# --- проверка аргументов ---
if [[ -z "$JIRA" ]]; then
  err "Использование: $0 <JIRA-ID>"
  err "Пример: $0 ARCH-42"
  exit 1
fi

RAW_JIRA="$RAW_DIR/$JIRA"
KNOWLEDGE_JIRA="$KNOWLEDGE_DIR/projects/$JIRA"

if [[ ! -d "$RAW_JIRA" ]]; then
  err "Папка не найдена: $RAW_JIRA"
  err "Сначала запусти: ./scripts/ingest.sh $JIRA /path/to/folder"
  exit 1
fi

# --- проверка Ollama ---
if ! curl -s "$OLLAMA_URL" > /dev/null 2>&1; then
  err "Ollama не запущена. Запусти: ollama serve &"
  exit 1
fi

# --- проверка CLAUDE.md ---
if [[ ! -f "$CLAUDE_MD" ]]; then
  err "CLAUDE.md не найден: $CLAUDE_MD"
  exit 1
fi

# --- создаём папки knowledge ---
mkdir -p "$KNOWLEDGE_JIRA"
SYSTEM_PROMPT="$(cat "$CLAUDE_MD")"

# --- счётчики ---
COUNT_OK=0
COUNT_SKIP=0

log "Тикет: $JIRA"
log "Модель: $MODEL"
echo ""

# --- функция: обновить processed: true ---
mark_processed() {
  local file="$1"
  # совместимо с macOS sed
  sed -i '' 's/^processed: false/processed: true/' "$file"
}

# --- функция: извлечь значение из frontmatter ---
get_frontmatter() {
  local file="$1"
  local key="$2"
  grep "^${key}:" "$file" | head -1 | sed "s/^${key}: *//" | tr -d '"'
}

# --- функция: вызов Ollama ---
call_ollama() {
  local prompt="$1"
  local response

  response=$(curl -s -X POST "$OLLAMA_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "$MODEL" \
      --arg system "$SYSTEM_PROMPT" \
      --arg prompt "$prompt" \
      '{model: $model, system: $system, prompt: $prompt, stream: false, options: {temperature: 0.1, num_ctx: 8192}}'
    )" | jq -r '.response // empty')

  echo "$response"
}

# --- функция: обновить файл knowledge ---
update_knowledge_file() {
  local entity_type="$1"   # stakeholders | risks | decisions | open-questions
  local jira="$2"
  local content="$3"
  local target="$KNOWLEDGE_JIRA/${entity_type}.md"

  if [[ -z "$content" || "$content" == "null" ]]; then
    warn "Нет данных для $entity_type"
    return
  fi

  if [[ ! -f "$target" ]]; then
    # создаём новый файл
    cat > "$target" <<EOF
# $(echo "$entity_type" | tr '-' ' ' | sed 's/\b./\u&/g') — $jira

$content
EOF
    log "Создан: $target"
  else
    # добавляем в конец существующего
    echo "" >> "$target"
    echo "---" >> "$target"
    echo "" >> "$target"
    echo "$content" >> "$target"
    log "Обновлён: $target"
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

  # читаем контент файла (убираем frontmatter)
  content="$(awk '/^---/{found++; if(found==2){skip=0; next}} found<2{next} {print}' "$filepath")"

  if [[ -z "$(echo "$content" | tr -d '[:space:]')" ]]; then
    warn "Пустой контент: $filename"
    mark_processed "$filepath"
    ((COUNT_SKIP++))
    continue
  fi

  # ограничиваем размер контекста (первые 6000 символов)
  content_truncated="$(echo "$content" | head -c 6000)"
  source_ref="[[${filename%.md}]]"

  echo ""
  info "→ Извлекаю стейкхолдеров..."
  stakeholders=$(call_ollama "Документ: $source_ref

$content_truncated

---
Задача: извлеки ТОЛЬКО стейкхолдеров из этого документа.
Формат каждого: ## S-XXX Название роли
- **Роль**: ...
- **Проект**: $JIRA
- **Интересы**: ...
- **Источник**: $source_ref
- **Теги**: #stakeholder

Если стейкхолдеров нет — ответь: НЕТ ДАННЫХ")

  info "→ Извлекаю риски..."
  risks=$(call_ollama "Документ: $source_ref

$content_truncated

---
Задача: извлеки ТОЛЬКО риски из этого документа.
Формат каждого: ## R-XXX Название риска
- **Влияние**: High|Medium|Low
- **Вероятность**: High|Medium|Low
- **Митигация**: ...
- **Источник**: $source_ref
- **Теги**: #risk

Если рисков нет — ответь: НЕТ ДАННЫХ")

  info "→ Извлекаю решения..."
  decisions=$(call_ollama "Документ: $source_ref

$content_truncated

---
Задача: извлеки ТОЛЬКО архитектурные решения и выборы из этого документа.
Формат каждого: ## D-XXX Название решения
- **Решение**: ...
- **Обоснование**: ...
- **Отклонено**: ...
- **Источник**: $source_ref
- **Теги**: #decision

Если решений нет — ответь: НЕТ ДАННЫХ")

  info "→ Извлекаю открытые вопросы..."
  questions=$(call_ollama "Документ: $source_ref

$content_truncated

---
Задача: извлеки ТОЛЬКО открытые вопросы и неопределённости из этого документа.
Формат каждого: ## Q-XXX Вопрос
- **Контекст**: ...
- **Владелец**: роль, не имя
- **Источник**: $source_ref
- **Теги**: #open-question

Если вопросов нет — ответь: НЕТ ДАННЫХ")

  # записываем только непустые результаты
  [[ "$stakeholders" != *"НЕТ ДАННЫХ"* ]] && update_knowledge_file "stakeholders" "$JIRA" "$stakeholders"
  [[ "$risks" != *"НЕТ ДАННЫХ"* ]]        && update_knowledge_file "risks" "$JIRA" "$risks"
  [[ "$decisions" != *"НЕТ ДАННЫХ"* ]]    && update_knowledge_file "decisions" "$JIRA" "$decisions"
  [[ "$questions" != *"НЕТ ДАННЫХ"* ]]    && update_knowledge_file "open-questions" "$JIRA" "$questions"

  mark_processed "$filepath"
  ((COUNT_OK++))
  echo ""

done < <(find "$RAW_JIRA" -name "*.md" -type f -print0)

# --- итог ---
echo ""
log "=== Готово ==="
echo -e "  ${GREEN}✓ Обработано:${NC} $COUNT_OK"
echo -e "  ${YELLOW}⊘ Пропущено:${NC}  $COUNT_SKIP"
echo ""
log "База знаний: $KNOWLEDGE_JIRA"
log "Открыть в Obsidian: open '$BRAIN_DIR'"
