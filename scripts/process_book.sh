#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# process_book.sh — конвертация PDF книги/фреймворка в SKILL.md
# Использование: ./scripts/process_book.sh path/to/book.pdf [skill-name]
# Пример:        ./scripts/process_book.sh ~/Downloads/clean-arch.pdf clean-architecture
# =============================================================================

# Загружаем .env если есть
if [[ -f "$(dirname "$0")/../.env" ]]; then
  set -a
  source "$(dirname "$0")/../.env"
  set +a
fi

PDF_PATH="${1:-}"
SKILL_NAME="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$BRAIN_DIR/skills"
CLAUDE_MD="$BRAIN_DIR/CLAUDE.md"
MODEL="${OLLAMA_MODEL:-llama3.1:8b}"
OLLAMA_URL="http://localhost:11434/api/generate"
# MAX_CHARS / MAX_CHUNKS / TIMEOUT — рассчитываются из железа ниже (hw-профиль)
TMP_DIR="/tmp/process_book_$$"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[book]${NC}   $*"; }
info() { echo -e "${BLUE}[book]${NC}   $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}   $*"; }
err()  { echo -e "${RED}[error]${NC}  $*" >&2; }

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --- авто-конфигурация по железу: мельче чанки и больше времени на слабых машинах ---
_get_ram_gb() {
  local ram=0
  case "$(uname -s)" in
    Linux)  ram=$(awk '/MemTotal/{printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null) ;;
    Darwin) ram=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 )) ;;
    MINGW*|MSYS*|CYGWIN*)
      ram=$(powershell.exe -NoProfile -Command \
        "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB" 2>/dev/null \
        | tr -d '[:space:]' | cut -d'.' -f1) ;;
  esac
  echo "${ram:-0}"
}

_get_cpu_cores() {
  local cores=0
  case "$(uname -s)" in
    Linux)  cores=$(nproc 2>/dev/null) ;;
    Darwin) cores=$(sysctl -n hw.ncpu 2>/dev/null) ;;
    MINGW*|MSYS*|CYGWIN*) cores="${NUMBER_OF_PROCESSORS:-0}" ;;
  esac
  echo "${cores:-0}"
}

_RAM_GB=$(_get_ram_gb)
_CPU_CORES=$(_get_cpu_cores)
# если детект не сработал — берём средний профиль, не калечим машину
(( _RAM_GB   > 0 )) || _RAM_GB=16
(( _CPU_CORES > 0 )) || _CPU_CORES=4

if   (( _RAM_GB < 8 )); then
  MAX_CHARS=1500; MAX_CHUNKS=6;  TIMEOUT=600
  _HW_PROFILE="economy (RAM < 8 ГБ)"
elif (( _RAM_GB < 16 && _CPU_CORES < 8 )); then
  MAX_CHARS=3000; MAX_CHUNKS=10; TIMEOUT=300
  _HW_PROFILE="standard (RAM 8-16 ГБ, CPU < 8)"
elif (( _RAM_GB < 16 )); then
  MAX_CHARS=5000; MAX_CHUNKS=12; TIMEOUT=300
  _HW_PROFILE="standard+ (RAM 8-16 ГБ, CPU 8+)"
else
  MAX_CHARS=8000; MAX_CHUNKS=12; TIMEOUT=300
  _HW_PROFILE="full (RAM > 16 ГБ)"
fi

info "Железо: RAM=${_RAM_GB}ГБ CPU=${_CPU_CORES} → профиль: $_HW_PROFILE"
info "Параметры: MAX_CHARS=$MAX_CHARS MAX_CHUNKS=$MAX_CHUNKS TIMEOUT=${TIMEOUT}с"
_EST_MINUTES=$(( MAX_CHUNKS * TIMEOUT / 60 ))
info "Расчётное время: ~${_EST_MINUTES} мин (${MAX_CHUNKS} чанков × до ${TIMEOUT}с)"

# --- валидация ---
if [[ -z "$PDF_PATH" ]]; then
  err "Использование: $0 <path/to/book.pdf> [skill-name]"
  err "Пример: $0 ~/Downloads/clean-arch.pdf clean-architecture"
  exit 1
fi

[[ ! -f "$PDF_PATH" ]] && { err "Файл не найден: $PDF_PATH"; exit 1; }

# Автоимя скилла из имени файла если не задано
if [[ -z "$SKILL_NAME" ]]; then
  SKILL_NAME="$(basename "$PDF_PATH" .pdf | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')"
  info "Имя скилла автоматически: $SKILL_NAME"
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"
SKILL_FILE="$SKILL_DIR/SKILL.md"

if [[ -f "$SKILL_FILE" ]]; then
  warn "Скилл уже существует: $SKILL_FILE"
  read -r -p "Перезаписать? (y/N): " confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { info "Отменено."; exit 0; }
fi

# --- проверки зависимостей ---
curl -s --max-time 5 "$OLLAMA_URL" > /dev/null 2>&1 || {
  err "Ollama не запущена. Запусти: ollama serve &"
  exit 1
}

# Проверяем чем извлекать текст из PDF
PDF_EXTRACTOR=""
if command -v pdftotext &> /dev/null; then
  PDF_EXTRACTOR="pdftotext"
elif python3 -c "import pypdf" &> /dev/null 2>&1; then
  PDF_EXTRACTOR="pypdf"
elif python3 -c "import pdfplumber" &> /dev/null 2>&1; then
  PDF_EXTRACTOR="pdfplumber"
else
  err "Нужен pdftotext (brew install poppler) или pypdf (pip install pypdf)"
  exit 1
fi

info "Экстрактор PDF: $PDF_EXTRACTOR"

# --- извлечение текста из PDF ---
mkdir -p "$TMP_DIR"
RAW_TEXT="$TMP_DIR/raw.txt"

log "Извлекаю текст из PDF..."

if [[ "$PDF_EXTRACTOR" == "pdftotext" ]]; then
  pdftotext -layout "$PDF_PATH" "$RAW_TEXT"
elif [[ "$PDF_EXTRACTOR" == "pypdf" ]]; then
  python3 - "$PDF_PATH" "$RAW_TEXT" << 'PYEOF'
import sys
from pypdf import PdfReader
reader = PdfReader(sys.argv[1])
with open(sys.argv[2], 'w', encoding='utf-8') as f:
    for page in reader.pages:
        text = page.extract_text()
        if text:
            f.write(text + '\n')
PYEOF
elif [[ "$PDF_EXTRACTOR" == "pdfplumber" ]]; then
  python3 - "$PDF_PATH" "$RAW_TEXT" << 'PYEOF'
import sys
import pdfplumber
with pdfplumber.open(sys.argv[1]) as pdf:
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                f.write(text + '\n')
PYEOF
fi

TOTAL_CHARS="$(wc -c < "$RAW_TEXT" | tr -d ' ')"
log "Извлечено символов: $TOTAL_CHARS"

if [[ "$TOTAL_CHARS" -lt 500 ]]; then
  err "Слишком мало текста — возможно PDF зашифрован или состоит из картинок"
  exit 1
fi

# --- нарезаем на чанки ---
log "Нарезаю на чанки по $MAX_CHARS символов (макс. $MAX_CHUNKS чанков)..."

python3 - "$RAW_TEXT" "$TMP_DIR" "$MAX_CHARS" "$MAX_CHUNKS" << 'PYEOF'
import sys, os, re

raw_file, tmp_dir, max_chars, max_chunks = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])

with open(raw_file, 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

# Чистим мусор: колонтитулы, лишние пробелы
text = re.sub(r'\n{3,}', '\n\n', text)
text = re.sub(r'[ \t]{3,}', ' ', text)

# Режем по абзацам чтобы не рвать посередине предложения
paragraphs = text.split('\n\n')
raw_chunks = []
current = ''

for para in paragraphs:
    while len(para) > max_chars:          # жёстко режем слишком длинный абзац
        raw_chunks.append(para[:max_chars].strip())
        para = para[max_chars:]
    if len(current) + len(para) < max_chars:
        current += para + '\n\n'
    else:
        if current.strip():
            raw_chunks.append(current.strip())
        current = para + '\n\n'

if current.strip():
    raw_chunks.append(current.strip())

# Равномерно прореживаем если чанков больше лимита
if len(raw_chunks) > max_chunks:
    step = len(raw_chunks) // max_chunks
    chunks = [raw_chunks[i * step] for i in range(max_chunks)]
else:
    chunks = raw_chunks

for i, chunk in enumerate(chunks):
    path = os.path.join(tmp_dir, f'chunk_{i:02d}.txt')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(chunk)

print(len(chunks))
PYEOF

CHUNK_COUNT="$(ls "$TMP_DIR"/chunk_*.txt 2>/dev/null | wc -l | tr -d ' ')"
log "Чанков для обработки: $CHUNK_COUNT"

# --- промпт для извлечения знаний из чанка ---
call_ollama_chunk() {
  local chunk_content="$1"
  local chunk_num="$2"
  local book_name="$3"

  local prompt="Извлеки экспертизу из текста в JSON. Только валидный JSON, без markdown.

ТЕКСТ: $chunk_content

JSON:
{\"concepts\":[],\"decision_rules\":[],\"playbooks\":[],\"anti_patterns\":[],\"when_to_use_hints\":[]}

Заполни массивы. Пустой раздел = []. Язык: русский."

  curl -s --max-time "$TIMEOUT" -X POST "$OLLAMA_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "$MODEL" \
      --arg prompt "$prompt" \
      '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.1, num_ctx: 8192}}'
    )" | jq -r '.response // empty'
}

# --- финальная сборка SKILL.md из всех чанков ---
call_ollama_consolidate() {
  local all_insights="$1"
  local book_name="$2"
  local skill_name="$3"

  local prompt="Ты собираешь финальный SKILL.md из извлечённых инсайтов книги.

Книга: $book_name
Скилл: $skill_name

Все извлечённые инсайты (JSON массивы):
$all_insights

---
Создай финальный SKILL.md. Верни ТОЛЬКО markdown, без пояснений.

Структура:
# SKILL: [название скилла на английском]

## DESCRIPTION
Одно предложение — суть экспертизы.

## WHEN_TO_USE
- [триггер 1 — когда Claude должен активировать этот скилл]
- [триггер 2]
- [триггер 3]

## CORE_CONCEPTS
- **[Понятие]**: [определение — 1 строка]
- **[Понятие]**: [определение — 1 строка]

## DECISION_RULES
- Если [условие] → [действие]
- Когда [контекст] → [применяй паттерн]

## PLAYBOOKS
### [Название плейбука]
1. [Шаг 1]
2. [Шаг 2]
3. [Шаг 3]

## ANTI_PATTERNS
- ❌ [Что не делать]: [почему]

## SOURCE
- Книга: $book_name
- Создан: $(date '+%Y-%m-%d')

Правила:
- Дедуплицируй похожие пункты
- Оставь только операционно полезное
- Язык — русский, термины — английские если общеприняты"

  curl -s --max-time "$TIMEOUT" -X POST "$OLLAMA_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg model "$MODEL" \
      --arg prompt "$prompt" \
      '{model: $model, prompt: $prompt, stream: false, options: {temperature: 0.2, num_ctx: 4096}}'
    )" | jq -r '.response // empty'
}

# --- основной цикл по чанкам ---
BOOK_NAME="$(basename "$PDF_PATH" .pdf)"
ALL_INSIGHTS=""
COUNT_OK=0
COUNT_ERR=0

echo ""
echo "[PROGRESS] 0/$CHUNK_COUNT"
CHUNK_IDX=0
for chunk_file in "$TMP_DIR"/chunk_*.txt; do
  chunk_num="$(basename "$chunk_file" .txt)"
  chunk_content="$(cat "$chunk_file")"
  chunk_size="$(echo "$chunk_content" | wc -c | tr -d ' ')"

  info "  Обрабатываю $chunk_num/$CHUNK_COUNT (${chunk_size} символов)..."

  response="$(call_ollama_chunk "$chunk_content" "$chunk_num" "$BOOK_NAME")"
  if [[ -z "$response" ]]; then
    warn "  Нет ответа — повторяю попытку (2/2)..."
    response="$(call_ollama_chunk "$chunk_content" "$chunk_num" "$BOOK_NAME")"
  fi

  ((CHUNK_IDX++))
  echo "[PROGRESS] $CHUNK_IDX/$CHUNK_COUNT"

  if [[ -z "$response" ]]; then
    warn "  Пропускаю $chunk_num после 2 попыток"
    ((COUNT_ERR++))
  else
    # Вырезаем JSON если модель добавила текст
    json="$(echo "$response" | sed -n '/^{/,/^}/p' | head -100)"
    if [[ -n "$json" ]]; then
      ALL_INSIGHTS="$ALL_INSIGHTS
--- $chunk_num ---
$json"
      ((COUNT_OK++))
    else
      warn "  Не удалось распарсить JSON из $chunk_num"
      ((COUNT_ERR++))
    fi
  fi
done

echo ""
log "Чанков обработано: $COUNT_OK / $CHUNK_COUNT"

if [[ $COUNT_OK -eq 0 ]]; then
  err "Ни один чанк не обработан — прерываю"
  exit 1
fi

# --- финальная консолидация → SKILL.md ---
log "Консолидирую в SKILL.md..."

SKILL_CONTENT="$(call_ollama_consolidate "$ALL_INSIGHTS" "$BOOK_NAME" "$SKILL_NAME")"

if [[ -z "$SKILL_CONTENT" ]]; then
  warn "Консолидация — повторяю попытку..."
  SKILL_CONTENT="$(call_ollama_consolidate "$ALL_INSIGHTS" "$BOOK_NAME" "$SKILL_NAME")"
fi
if [[ -z "$SKILL_CONTENT" ]]; then
  err "Консолидация не удалась — пустой ответ"
  exit 1
fi

# --- сохраняем скилл ---
mkdir -p "$SKILL_DIR"
echo "$SKILL_CONTENT" > "$SKILL_FILE"

log "Скилл создан: $SKILL_FILE"

# --- обновляем skills/README.md ---
README="$SKILLS_DIR/README.md"
if [[ -f "$README" ]]; then
  DATE_NOW="$(date '+%Y-%m-%d')"
  echo "| $SKILL_NAME/SKILL.md | $BOOK_NAME | $DATE_NOW |" >> "$README"
  log "README.md обновлён"
fi

echo ""
log "=== Готово ==="
echo -e "  ${GREEN}✓ Чанков обработано:${NC}  $COUNT_OK"
echo -e "  ${RED}✗ Ошибок:${NC}             $COUNT_ERR"
echo -e "  ${BLUE}→ Скилл:${NC}              $SKILL_FILE"
echo ""
wc -l "$SKILL_FILE" | awk '{print "  Строк в SKILL.md: " $1}'
