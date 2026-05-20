#!/usr/bin/env bash
set -uo pipefail
export PYTHONIOENCODING=utf-8

# =============================================================================
# process.sh v3 — streaming, garbled filter, ID dedup, skill-aware, auto MAX_CHARS
# Использование: ./scripts/process.sh ARCH-123
# =============================================================================

if [[ -f "$(dirname "$0")/../.env" ]]; then
  set -a
  source "$(dirname "$0")/../.env"
  set +a
fi

JIRA="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DIR="$(dirname "$SCRIPT_DIR")"
RAW_DIR="$BRAIN_DIR/raw"
KNOWLEDGE_DIR="$BRAIN_DIR/knowledge"
CLAUDE_MD="$BRAIN_DIR/CLAUDE.md"
MODEL="${OLLAMA_MODEL:-llama3.1:8b}"
OLLAMA_URL="http://localhost:11434/api/generate"
TIMEOUT=180

# --- авто-расчёт MAX_CHARS по модели и ОЗУ ---
_get_ram_gb() {
  local ram=8
  case "$(uname -s)" in
    Linux)  ram=$(awk '/MemTotal/{printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null) ;;
    Darwin) ram=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 8589934592) / 1073741824 )) ;;
    MINGW*|MSYS*|CYGWIN*)
      ram=$(powershell.exe -NoProfile -Command \
        "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB" 2>/dev/null \
        | tr -d '[:space:]' | cut -d'.' -f1) ;;
  esac
  echo "${ram:-8}"
}

_get_model_b() {
  local m; m="$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')"
  if   [[ "$m" =~ 70b|72b ]]; then echo 70
  elif [[ "$m" =~ 34b|30b ]]; then echo 34
  elif [[ "$m" =~ 27b     ]]; then echo 27
  elif [[ "$m" =~ 12b|13b ]]; then echo 13
  elif [[ "$m" =~ 3b|4b   ]]; then echo 3
  else echo 8; fi
}

_auto_max_chars() {
  local ram b
  ram=$(_get_ram_gb); b=$(_get_model_b)
  if   (( b >= 70 )); then (( ram >= 64 )) && echo 24000 || echo 16000
  elif (( b >= 27 )); then
    if   (( ram >= 64 )); then echo 20000
    elif (( ram >= 32 )); then echo 14000
    elif (( ram >= 16 )); then echo 8000
    else echo 4000; fi
  elif (( b >= 12 )); then
    if   (( ram >= 32 )); then echo 14000
    elif (( ram >= 16 )); then echo 10000
    elif (( ram >= 8  )); then echo 6000
    else echo 4000; fi
  else
    if   (( ram >= 32 )); then echo 10000
    elif (( ram >= 16 )); then echo 7000
    elif (( ram >= 8  )); then echo 5000
    else echo 3000; fi
  fi
}

MAX_CHARS="${MAX_CHARS:-$(_auto_max_chars)}"
NUM_CTX=$(( (MAX_CHARS + 2048 + 511) / 512 * 512 ))

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

LOG_DIR="$BRAIN_DIR/logs"
mkdir -p "$LOG_DIR"
RUN_TS="$(date '+%Y%m%d_%H%M%S')"
LOG_FILE="$LOG_DIR/process-${JIRA}-${RUN_TS}.log"

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

tee_log() {
  local msg="$*"
  local clean
  clean="$(printf '%s' "$msg" | sed 's/\x1b\[[0-9;]*m//g')"
  printf '[%s] %s\n' "$(_ts)" "$clean" >> "$LOG_FILE"
}

log()  { local m="${GREEN}[process]${NC} $*"; echo -e "$m"; tee_log "[OK]  $*"; }
info() { local m="${BLUE}[process]${NC} $*";  echo -e "$m"; tee_log "[INFO] $*"; }
warn() { local m="${YELLOW}[warn]${NC}    $*"; echo -e "$m"; tee_log "[WARN] $*"; }
err()  { local m="${RED}[error]${NC}   $*";  echo -e "$m" >&2; tee_log "[ERR]  $*"; }

PYTHON="$(command -v python3 2>/dev/null)"
if [[ -n "$PYTHON" ]]; then
  "$PYTHON" --version &>/dev/null || PYTHON=""
fi
[[ -z "$PYTHON" ]] && PYTHON="$(command -v python 2>/dev/null)"
[[ -z "$PYTHON" ]] && { err "Python не найден"; exit 1; }

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

SKILL_FILE="$KNOWLEDGE_JIRA/${JIRA}-SKILL.md"
if [[ -f "$SKILL_FILE" ]]; then
  SYSTEM_PROMPT="$(tr -d '\r' < "$SKILL_FILE" | sed 's/^```[a-z]*$//' | sed '/^```$/d' | sed '/^[[:space:]]*$/d' | sed '1{/^[[:space:]]*$/d}')"
  SKILL_ACTIVE="true"
  info "Используется скилл проекта: ${JIRA}-SKILL.md"
else
  SYSTEM_PROMPT="Ты извлекаешь знания из документов в структурированный JSON. Отвечай ТОЛЬКО валидным JSON без пояснений."
  SKILL_ACTIVE="false"
fi

# --- авто-переключение модели если тексты на кириллице ---
_model_supports_cyrillic() {
  local m; m="$(echo "$MODEL" | tr '[:upper:]' '[:lower:]')"
  [[ "$m" == *qwen* || "$m" == *aya* || "$m" == *vikhr* || "$m" == *saiga* || "$m" == *mistral* ]]
}

_content_is_cyrillic() {
  local body="" count=0
  while IFS= read -r -d '' fp && (( count < 3 )); do
    body+="$(tr -d '\r' < "$fp" | awk '/^---/{f++; if(f==2){next}} f<2{next} {print}' | head -c 1500)"
    (( count++ ))
  done < <(find "$RAW_JIRA" -name "*.md" -type f -print0)
  local cyr
  cyr="$(printf '%s' "$body" | "$PYTHON" -c 'import sys; t=sys.stdin.buffer.read().decode("utf-8", errors="replace"); print(sum(1 for c in t if "Ѐ"<=c<="ӿ"))')"
  [[ "$cyr" =~ ^[0-9]+$ ]] && (( cyr > 100 ))
}

if ! _model_supports_cyrillic && _content_is_cyrillic; then
  CYRILLIC_FALLBACK="qwen2.5:7b"
  HAS_FALLBACK="$("$PYTHON" -c "
import urllib.request, json
try:
  r = urllib.request.urlopen('http://localhost:11434/api/tags', timeout=3)
  models = json.load(r).get('models', [])
  print('yes' if any('qwen2.5' in m['name'] for m in models) else 'no')
except: print('no')
")"
  if [[ "$HAS_FALLBACK" == "yes" ]]; then
    warn "Модель ${MODEL} не поддерживает кириллицу — авто-переключение на ${CYRILLIC_FALLBACK}"
    MODEL="$CYRILLIC_FALLBACK"
    NUM_CTX=$(( (MAX_CHARS + 2048 + 511) / 512 * 512 ))
  else
    warn "Модель ${MODEL} не поддерживает кириллицу. Рекомендуется: ollama pull ${CYRILLIC_FALLBACK}"
  fi
fi

COUNT_OK=0; COUNT_SKIP=0; COUNT_ERR=0

log "Тикет: $JIRA | Модель: $MODEL | Лимит: ${MAX_CHARS} символов | Таймаут: ${TIMEOUT}с"
info "Лог: $LOG_FILE"
echo ""

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
  local tmp
  tmp="$(mktemp)"
  sed 's/^processed: false/processed: true/' "$1" > "$tmp" && mv "$tmp" "$1"
}

get_frontmatter() {
  grep "^${2}:" "$1" | head -1 | sed "s/^${2}: *//" | tr -d '"\r'
}

call_ollama_single() {
  local content="$1"
  local ref="$2"
  local doc_type="$3"

  local prompt
  if [[ "${SKILL_ACTIVE:-false}" == "true" ]]; then
    prompt="Извлеки знания ТОЛЬКО из текста документа ниже, строго следуя схеме из system prompt.
НЕ генерируй информацию из других источников — только то, что явно присутствует в тексте.
Верни ТОЛЬКО валидный JSON, без пояснений и markdown-блоков.

ДОКУМЕНТ ($ref):
$content"
  else
    local spfa_instruction=""
    [[ "$doc_type" == "spfa" ]] && spfa_instruction='
8. "spfa": массив SPFA оценок вендора (если есть): [{id, vendor, status, findings, tco, source}]'
    prompt="Проанализируй текст документа и заполни JSON-структуру.
Каждый элемент массива ДОЛЖЕН быть объектом с полями как в примере ниже.
Если данных для категории нет — верни пустой массив [].
Используй только роли людей, не имена.

ПРИМЕР (заполни по аналогии с реальными данными из документа):
{
  \"business_context\": [{\"id\": \"BC-001\", \"title\": \"Название инициативы\", \"problem\": \"Какую проблему решает\", \"goals\": \"Цели\", \"source\": \"$ref\", \"tags\": \"#business-context\"}],
  \"requirements\": [{\"id\": \"BR-001\", \"title\": \"Название требования\", \"type\": \"Functional\", \"description\": \"Описание\", \"priority\": \"Must\", \"source\": \"$ref\", \"tags\": \"#requirement\"}],
  \"architecture\": [{\"id\": \"ARCH-001\", \"title\": \"Компонент или интеграция\", \"type\": \"Integration\", \"description\": \"Описание\", \"systems\": \"Система A, Система B\", \"protocol\": \"REST\", \"source\": \"$ref\", \"tags\": \"#architecture\"}],
  \"adrs\": [{\"id\": \"ADR-001\", \"title\": \"Решение\", \"status\": \"Accepted\", \"context\": \"Контекст\", \"decision\": \"Решение\", \"consequences\": \"Последствия\", \"source\": \"$ref\", \"tags\": \"#adr\"}],
  \"risks\": [{\"id\": \"R-001\", \"title\": \"Название риска\", \"category\": \"Technical\", \"impact\": \"High\", \"probability\": \"Medium\", \"mitigation\": \"Меры\", \"source\": \"$ref\", \"tags\": \"#risk\"}],
  \"open_questions\": [{\"id\": \"Q-001\", \"question\": \"Вопрос?\", \"context\": \"Контекст\", \"affects\": \"Architecture\", \"owner\": \"Роль\", \"urgency\": \"Normal\", \"source\": \"$ref\", \"tags\": \"#open-question\"}],
  \"stakeholders\": [{\"id\": \"S-001\", \"role\": \"Product Owner\", \"project\": \"$JIRA\", \"interests\": \"Интересы\", \"raci\": \"Accountable\", \"source\": \"$ref\", \"tags\": \"#stakeholder\"}]${spfa_instruction}
}

ДОКУМЕНТ ($ref, тип: $doc_type):
$content"
  fi

  local payload
  if [[ "${SKILL_ACTIVE:-false}" == "true" ]]; then
    payload="$(jq -n \
      --arg model "$MODEL" \
      --arg system "$SYSTEM_PROMPT" \
      --arg prompt "$prompt" \
      --argjson num_ctx "$NUM_CTX" \
      '{model: $model, system: $system, prompt: $prompt, stream: true, options: {temperature: 0.1, num_ctx: $num_ctx}}')"
  else
    payload="$(jq -n \
      --arg model "$MODEL" \
      --arg system "$SYSTEM_PROMPT" \
      --arg prompt "$prompt" \
      --argjson num_ctx "$NUM_CTX" \
      '{model: $model, system: $system, prompt: $prompt, stream: true, format: "json", options: {temperature: 0.1, num_ctx: $num_ctx}}')"
  fi

  local skip_flag="$BRAIN_DIR/logs/.skip-$JIRA"
  local skipped_flag="$BRAIN_DIR/logs/.skipped-$JIRA"

  local hb_start
  hb_start="$(date +%s)"
  (
    while true; do
      sleep 30
      printf " [%ds…]" "$(( $(date +%s) - hb_start ))" >&2
    done
  ) &
  local HB_PID=$!

  local tmp_payload tmp_ndjson tmp_result
  tmp_payload="$(mktemp)"
  tmp_ndjson="$(mktemp)"
  tmp_result="$(mktemp)"
  printf '%s' "$payload" > "$tmp_payload"

  # Mac: curl --max-time работает надёжно со streaming на macOS
  curl -s --max-time "${TIMEOUT}" -X POST "$OLLAMA_URL" \
    -H "Content-Type: application/json" \
    --data-binary "@${tmp_payload}" \
    > "$tmp_ndjson" 2>/dev/null || true

  kill "$HB_PID" 2>/dev/null; wait "$HB_PID" 2>/dev/null
  rm -f "$tmp_payload"

  "$PYTHON" - "$tmp_ndjson" "$tmp_result" << 'PYNDJSON'
import sys, json
src, dst = sys.argv[1], sys.argv[2]
result = []
dots = 0
try:
    with open(src, 'rb') as f:
        for raw_line in f:
            try:
                line = raw_line.decode('utf-8', errors='replace').strip()
                if not line:
                    continue
                obj = json.loads(line)
                t = obj.get('response', '')
                if t:
                    result.append(t)
                    dots += 1
                    if dots % 30 == 0:
                        sys.stderr.write('·')
                        sys.stderr.flush()
            except Exception:
                pass
except Exception:
    pass
if dots > 0:
    sys.stderr.write('\n')
    sys.stderr.flush()
with open(dst, 'w', encoding='utf-8') as f:
    f.write(''.join(result))
PYNDJSON

  rm -f "$tmp_ndjson"

  if [[ -f "$skip_flag" ]]; then
    rm -f "$skip_flag" "$tmp_result"
    touch "$skipped_flag"
    printf "\n[skipped]\n" >&2
    return
  fi

  printf '%s' "$tmp_result"
}

# --- JSON → markdown файлы (generic, schema-agnostic) ---
json_to_files() {
  local raw_file="$1"
  [[ ! -s "$raw_file" ]] && return

  local py_extract py_write
  py_extract="$(mktemp).py"
  py_write="$(mktemp).py"

  cat > "$py_extract" << 'PYEXTRACT'
import sys, re, json as _json

def depth_find(text, start):
    depth = 0
    for i, c in enumerate(text[start:], start):
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return text[start:i+1]
    return None

with open(sys.argv[1], 'r', encoding='utf-8', errors='replace') as fh:
    text = fh.read()
candidate = None

m = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', text)
if m:
    fenced = m.group(1)
    start = fenced.find('{')
    if start != -1:
        candidate = depth_find(fenced, start)

if candidate is None:
    start = text.find('{')
    if start != -1:
        candidate = depth_find(text, start)

if candidate is None:
    sys.exit(0)

try:
    _json.loads(candidate)
    print(candidate)
except Exception as e:
    print(f'json-extract error: {e}', file=sys.stderr)
    sys.exit(0)
PYEXTRACT

  local json_file
  json_file="$(mktemp)"
  "$PYTHON" "$py_extract" "$raw_file" > "$json_file" 2>/dev/null
  rm -f "$py_extract"
  [[ ! -s "$json_file" ]] && { rm -f "$json_file"; return; }

  cat > "$py_write" << 'PYEOF'
import sys, json, os, re
knowledge_dir = sys.argv[1]
try:
  data = json.loads(sys.stdin.buffer.read().decode('utf-8', errors='replace'))
except Exception as e:
  print(f'json parse error: {e}', file=sys.stderr)
  sys.exit(0)
project = os.path.basename(knowledge_dir)
HEADING_KEYS = ('title','name','role','question','concept','finding','decision','insight','method','action','quote','author','term','definition','theory')

def _max_id_in_file(fp):
  try:
    with open(fp, 'r', encoding='utf-8') as fh:
      nums = re.findall(r'^## [A-Za-z]+-(\d+)', fh.read(), re.MULTILINE)
    return max((int(n) for n in nums), default=0)
  except Exception:
    return 0

def _reindex(item_id, offset):
  m = re.match(r'^([A-Za-z]+-?)(\d+)$', str(item_id))
  if not m or offset == 0:
    return item_id
  return f"{m.group(1)}{int(m.group(2)) + offset:03d}"

for key, items in data.items():
  if not isinstance(items, list) or not items:
    continue
  filename = key.replace('_', '-') + '.md'
  filepath = os.path.join(knowledge_dir, filename)
  is_append = os.path.exists(filepath)
  id_offset = _max_id_in_file(filepath) if is_append else 0
  lines = []
  for item in items:
    if not isinstance(item, dict):
      continue
    item_id = _reindex(str(item.get('id', '?')), id_offset)
    heading_key = next((k for k in HEADING_KEYS if item.get(k)), None)
    heading = str(item[heading_key]) if heading_key else item_id
    lines.append(f'## {item_id} {heading}')
    for k, v in item.items():
      if k == 'id' or k == heading_key:
        continue
      if v:
        if isinstance(v, (list, dict)):
          v = json.dumps(v, ensure_ascii=False)
        lines.append(f'- **{k.capitalize()}**: {v}')
    lines.append('')
  if not lines:
    continue
  content = '\n'.join(lines)
  header_title = key.replace('_', ' ').title()
  if is_append:
    with open(filepath, 'a', encoding='utf-8') as f:
      f.write('\n---\n\n' + content)
    print(f'append:{filename}')
  else:
    with open(filepath, 'w', encoding='utf-8') as f:
      f.write(f'# {header_title} — {project}\n\n{content}')
    print(f'create:{filename}')
PYEOF

  local result
  result="$("$PYTHON" "$py_write" "$KNOWLEDGE_JIRA" < "$json_file" 2>/dev/null)"
  rm -f "$py_write" "$json_file"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == create:* ]]; then
      log "  Создан: ${line#create:}"
    elif [[ "$line" == append:* ]]; then
      log "  Обновлён: ${line#append:}"
    else
      warn "$line"
    fi
  done <<< "$result"
}

detect_doc_type() {
  local name
  name="$(basename "$1" | tr '[:upper:]' '[:lower:]')"
  echo "$name" | grep -qi "spfa\|feasibility\|vendor\|assessment" && echo "spfa" && return
  echo "$name" | grep -qi "hld\|high.level" && echo "hld" && return
  echo "$name" | grep -qi "bazaar\|справка\|an-" && echo "an" && return
  echo "generic"
}

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

  content="$(tr -d '\r' < "$filepath" | awk '/^---/{found++; if(found==2){skip=0; next}} found<2{next} {print}' | head -c $MAX_CHARS)"

  if [[ -z "$(echo "$content" | tr -d '[:space:]')" ]]; then
    warn "Пустой контент — пропускаю"
    mark_processed "$filepath"
    ((COUNT_SKIP++))
    continue
  fi

  # Гарблед-фильтр: PDF с битой кодировкой (<25% читаемых символов)
  readable_ratio="$(printf '%s' "$content" | "$PYTHON" -c "
import sys
text = sys.stdin.buffer.read().decode('utf-8', errors='replace')
stripped = text.replace(' ','').replace('\n','').replace('\t','').replace('\r','')
total = len(stripped)
if total < 50:
    print(100)
else:
    readable = sum(1 for c in stripped if c.isalpha() or c.isdigit())
    print(int(readable * 100 // total))
")"
  if [[ "${readable_ratio:-100}" -lt 25 ]]; then
    warn "  Гарблед контент (${readable_ratio}% читаемых символов) — пропускаю: $filename"
    mark_processed "$filepath"
    ((COUNT_SKIP++))
    continue
  fi

  doc_type="$(detect_doc_type "$filepath")"
  ref="[[${filename%.md}]]"
  chars="$(printf '%s' "$content" | wc -c | tr -d ' ')"

  info "  → 1 запрос (тип: $doc_type, размер: ${chars} символов)..."
  tee_log "[START-MODEL] file=$filename doc_type=$doc_type chars=$chars model=$MODEL num_ctx=$NUM_CTX"

  t_start="$(date +%s)"
  result_file="$(call_ollama_single "$content" "$ref" "$doc_type")"
  t_end="$(date +%s)"
  elapsed=$(( t_end - t_start ))

  if [[ -f "$BRAIN_DIR/logs/.skipped-$JIRA" ]]; then
    rm -f "$BRAIN_DIR/logs/.skipped-$JIRA" "$result_file"
    warn "  Пропущен по запросу пользователя: $filename"
    tee_log "[SKIP-REQ] file=$filename elapsed=${elapsed}s"
    ((COUNT_SKIP++))
    mark_processed "$filepath"
    echo ""
    continue
  fi

  if [[ -z "$result_file" ]] || [[ ! -s "$result_file" ]]; then
    warn "  Таймаут или пустой ответ (${elapsed}с) — пропускаю: $filename"
    tee_log "[TIMEOUT] file=$filename elapsed=${elapsed}s"
    [[ -n "$result_file" ]] && rm -f "$result_file"
    ((COUNT_ERR++))
  else
    resp_len="$(wc -c < "$result_file" | tr -d ' ')"
    info "  ✓ Ответ получен за ${elapsed}с (${resp_len} символов)"
    tee_log "[END-MODEL] file=$filename elapsed=${elapsed}s response_len=${resp_len}"
    json_to_files "$result_file"
    rm -f "$result_file"
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
tee_log "[DONE] ok=$COUNT_OK skip=$COUNT_SKIP err=$COUNT_ERR"

if [[ "$COUNT_ERR" -eq 0 ]]; then
  rm -f "$LOG_FILE"
else
  log "Лог ошибок: $LOG_FILE"
fi
