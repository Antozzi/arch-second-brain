#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ingest.sh — конвертация рабочих документов в markdown для second-brain
# Использование: ./scripts/ingest.sh ARCH-42 /path/to/folder
# =============================================================================

JIRA="${1:-}"
SOURCE_DIR="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_DIR="$(dirname "$SCRIPT_DIR")"
RAW_DIR="$BRAIN_DIR/raw"
TODAY="$(date +%Y-%m-%d)"

# --- цвета для вывода ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ingest]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}  $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

# --- проверка аргументов ---
if [[ -z "$JIRA" || -z "$SOURCE_DIR" ]]; then
  err "Использование: $0 <JIRA-ID> <папка с документами>"
  err "Пример: $0 ARCH-42 ~/Documents/WorkingDocs/ESS-IDM"
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  err "Папка не найдена: $SOURCE_DIR"
  exit 1
fi

# --- проверка зависимостей ---
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    err "Не найден: $1. Установи: brew install $2"
    exit 1
  fi
}
check_dep pandoc pandoc
check_dep tesseract tesseract
check_dep magick imagemagick

# --- создаём папку назначения ---
TARGET_DIR="$RAW_DIR/$JIRA"
mkdir -p "$TARGET_DIR"
log "Папка назначения: $TARGET_DIR"

# --- счётчики ---
COUNT_OK=0
COUNT_SKIP=0
COUNT_ERR=0

# --- функция: добавить YAML frontmatter ---
add_frontmatter() {
  local file="$1"
  local source="$2"
  local type="$3"
  local tmp
  tmp="$(mktemp)"

  cat > "$tmp" <<EOF
---
source: "$source"
jira: "$JIRA"
date: "$TODAY"
processed: false
type: "$type"
---

EOF
  cat "$file" >> "$tmp"
  mv "$tmp" "$file"
}

# --- функция: безопасное имя файла ---
safe_name() {
  local name="$1"
  echo "${TODAY}-$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')"
}

# --- обход файлов ---
log "Сканирую: $SOURCE_DIR"
log "Тикет: $JIRA"
echo ""

while IFS= read -r -d '' filepath; do
  filename="$(basename "$filepath")"
  ext="${filename##*.}"
  ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  base="${filename%.*}"
  out_name="$(safe_name "$base").md"
  out_path="$TARGET_DIR/$out_name"

  # пропускаем скрытые файлы и системный мусор
  case "$filename" in
    .* | ~$* | *.tmp | Thumbs.db | .DS_Store) continue ;;
  esac

  case "$ext_lower" in

    pdf)
      log "PDF → md: $filename"
      if pandoc "$filepath" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "pdf"
        ((COUNT_OK++))
      else
        warn "pandoc не смог обработать: $filename (возможно, скан)"
        # fallback: пустой md с пометкой
        echo "" > "$out_path"
        add_frontmatter "$out_path" "$filepath" "pdf-scan"
        echo "" >> "$out_path"
        echo "> **Внимание**: pandoc не извлёк текст. Возможно, это скан — попробуй OCR вручную." >> "$out_path"
        ((COUNT_ERR++))
      fi
      ;;

    docx|doc)
      log "DOCX → md: $filename"
      if pandoc "$filepath" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "docx"
        ((COUNT_OK++))
      else
        err "Ошибка конвертации: $filename"
        ((COUNT_ERR++))
      fi
      ;;

    pptx|ppt)
      log "PPTX → md: $filename"
      if pandoc "$filepath" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "pptx"
        ((COUNT_OK++))
      else
        err "Ошибка конвертации: $filename"
        ((COUNT_ERR++))
      fi
      ;;

    txt)
      log "TXT → md: $filename"
      cp "$filepath" "$out_path"
      add_frontmatter "$out_path" "$filepath" "txt"
      ((COUNT_OK++))
      ;;

    md|markdown)
      log "MD → md: $filename"
      cp "$filepath" "$out_path"
      add_frontmatter "$out_path" "$filepath" "md"
      ((COUNT_OK++))
      ;;

    png|jpg|jpeg|tiff|bmp)
      log "IMG → OCR → md: $filename"
      # препроцессинг: grayscale + contrast для лучшего OCR
      local_tmp="$(mktemp).png"
      if magick "$filepath" -colorspace Gray -contrast-stretch 0x10% "$local_tmp" 2>/dev/null; then
        ocr_text="$(tesseract "$local_tmp" stdout -l rus+eng 2>/dev/null || true)"
        rm -f "$local_tmp"
        echo "$ocr_text" > "$out_path"
        add_frontmatter "$out_path" "$filepath" "image"
        if [[ -z "$(echo "$ocr_text" | tr -d '[:space:]')" ]]; then
          warn "OCR не нашёл текст в: $filename"
          ((COUNT_ERR++))
        else
          ((COUNT_OK++))
        fi
      else
        err "imagemagick не смог обработать: $filename"
        ((COUNT_ERR++))
      fi
      ;;

    xlsx|xls|csv)
      log "ТАБЛИЦА → md: $filename"
      if pandoc "$filepath" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "spreadsheet"
        ((COUNT_OK++))
      else
        warn "Пропускаю таблицу (pandoc не поддерживает): $filename"
        ((COUNT_SKIP++))
      fi
      ;;

    *)
      warn "Пропускаю (неизвестный тип): $filename"
      ((COUNT_SKIP++))
      ;;

  esac

done < <(find "$SOURCE_DIR" -type f -print0)

# --- итог ---
echo ""
log "=== Готово ==="
echo -e "  ${GREEN}✓ Конвертировано:${NC} $COUNT_OK"
echo -e "  ${YELLOW}⊘ Пропущено:${NC}     $COUNT_SKIP"
echo -e "  ${RED}✗ Ошибки:${NC}        $COUNT_ERR"
echo ""
log "Результат в: $TARGET_DIR"
log "Следующий шаг: ./scripts/process.sh $JIRA"
