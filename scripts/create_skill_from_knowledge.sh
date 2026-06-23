#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# create_skill_from_knowledge.sh — создание доменного скилла из базы знаний проекта
# Использование: ./scripts/create_skill_from_knowledge.sh JIRA-ID [skill-name]
# Пример:        ./scripts/create_skill_from_knowledge.sh ARCH-123 siem-domain
# =============================================================================

if [[ -f "$(dirname "$0")/../.env" ]]; then
  set -a
  source "$(dirname "$0")/../.env"
  set +a
fi

JIRA="${1:-}"
SKILL_NAME="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$BRAIN_DIR/skills"
KNOWLEDGE_DIR="$BRAIN_DIR/knowledge/projects/$JIRA"
MODEL="${OLLAMA_MODEL:-llama3.1:8b}"
OLLAMA_URL="http://localhost:11434/api/generate"
MAX_KNOWLEDGE_CHARS=12000
TIMEOUT=120

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[skill]${NC}  $*"; }
info() { echo -e "${BLUE}[skill]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}   $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

# --- валидация ---
if [[ -z "$JIRA" ]]; then
  err "Использование: $0 <JIRA-ID> [skill-name]"
  exit 1
fi

if [[ ! -d "$KNOWLEDGE_DIR" ]]; then
  err "База знаний не найдена: $KNOWLEDGE_DIR"
  err "Сначала обработай проект через process.sh"
  exit 1
fi

# Автоимя скилла
if [[ -z "$SKILL_NAME" ]]; then
  SKILL_NAME="$(echo "$JIRA" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')-domain"
  info "Имя скилла автоматически: $SKILL_NAME"
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"
SKILL_FILE="$SKILL_DIR/SKILL.md"

if [[ -f "$SKILL_FILE" ]]; then
  warn "Скилл уже существует: $SKILL_FILE"
  read -r -p "Перезаписать? (y/N): " confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { info "Отменено."; exit 0; }
fi

# --- проверка Ollama ---
curl -s --max-time 5 "$OLLAMA_URL" > /dev/null 2>&1 || {
  err "Ollama не запущена. Запусти: ollama serve &"
  exit 1
}

# --- собираем знания из всех .md файлов проекта ---
log "Читаю базу знаний проекта $JIRA..."

KNOWLEDGE_TEXT=""
FILE_COUNT=0

for f in "$KNOWLEDGE_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  fname="$(basename "$f")"
  content="$(cat "$f")"
  KNOWLEDGE_TEXT="$KNOWLEDGE_TEXT

### $fname
$content"
  ((FILE_COUNT++))
done

if [[ $FILE_COUNT -eq 0 ]]; then
  err "Нет .md файлов в $KNOWLEDGE_DIR"
  exit 1
fi

log "Файлов знаний: $FILE_COUNT"

# Обрезаем до лимита
KNOWLEDGE_TEXT="$(echo "$KNOWLEDGE_TEXT" | head -c $MAX_KNOWLEDGE_CHARS)"
TOTAL_CHARS="${#KNOWLEDGE_TEXT}"
info "Символов в контексте: $TOTAL_CHARS"

# --- промпт ---
PROMPT="Ты извлекаешь предметную экспертизу из базы знаний проекта для создания AI-скилла.

Проект: $JIRA

БАЗА ЗНАНИЙ ПРОЕКТА:
$KNOWLEDGE_TEXT

---
Твоя задача — извлечь ПРЕДМЕТНУЮ ЭКСПЕРТИЗУ (domain knowledge): ключевые понятия, методы и правила домена,
которые помогут модели лучше извлекать структурированные знания из похожих документов.

Создай SKILL.md. Верни ТОЛЬКО markdown без пояснений.

# SKILL: $SKILL_NAME

## DESCRIPTION
Одно предложение — суть предметной области проекта.

## WHEN_TO_USE
- [когда этот скилл нужен при обработке документов этого домена]
- [триггеры: упоминание конкретных понятий, методов, терминов]

## DOMAIN_CONTEXT
Краткое описание предметной области: о чём она, ключевые объекты, как связаны.

## CORE_CONCEPTS
- **[Термин/понятие]**: [определение — 1 строка, из контекста проекта]
- **[Термин/понятие]**: [определение — 1 строка]

## DECISION_RULES
- Если [ситуация в этом домене] → [как извлекать/трактовать]
- Когда [контекст домена] → [что учитывать]

## ANTI_PATTERNS
- ❌ [Типичная ошибка в этом домене]: [почему неправильно]

## SOURCE
- Проект: $JIRA
- Создан: $(date '+%Y-%m-%d')

Правила:
- Только факты из документов, без домыслов
- Термины на языке оригинала документов
- Если раздел пуст — не включай его
- Язык — русский"

# --- вызов Ollama ---
log "Генерирую доменный скилл через Ollama..."

RESPONSE="$(curl -s --max-time "$TIMEOUT" -X POST "$OLLAMA_URL" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.1, num_ctx: 8192}}'
  )" | jq -r '.response // empty')"

if [[ -z "$RESPONSE" ]]; then
  err "Пустой ответ от Ollama — таймаут или ошибка"
  exit 1
fi

# --- сохраняем ---
mkdir -p "$SKILL_DIR"
echo "$RESPONSE" > "$SKILL_FILE"

log "Скилл создан: $SKILL_FILE"

# --- обновляем README ---
README="$SKILLS_DIR/README.md"
if [[ -f "$README" ]]; then
  DATE_NOW="$(date '+%Y-%m-%d')"
  echo "| $SKILL_NAME/SKILL.md | $JIRA knowledge | $DATE_NOW |" >> "$README"
  log "README.md обновлён"
fi

echo ""
log "=== Готово ==="
echo -e "  ${BLUE}→ Скилл:${NC}   $SKILL_FILE"
echo -e "  ${BLUE}→ Проект:${NC}  $JIRA"
wc -l "$SKILL_FILE" | awk '{print "  Строк в SKILL.md: " $1}'
