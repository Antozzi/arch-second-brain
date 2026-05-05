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

# --- функция: OCR для PDF ---
pdf_ocr() {
  local filepath="$1" out_path="$2" filename="$3"
  local tmp_dir ocr_text=""
  tmp_dir="$(mktemp -d)"
  log "PDF OCR → md: $filename"
  if magick -density 200 "${filepath}[0-9]" -colorspace Gray -contrast-stretch 0x10% "${tmp_dir}/page.png" 2>/dev/null; then
    for page_img in "${tmp_dir}"/page*.png "${tmp_dir}"/page-*.png; do
      [[ -f "$page_img" ]] || continue
      ocr_text="${ocr_text}$(tesseract "$page_img" stdout -l rus+eng 2>/dev/null || true)"$'\n'
    done
  fi
  rm -rf "$tmp_dir"
  if [[ -z "$(echo "$ocr_text" | tr -d '[:space:]')" ]]; then
    warn "OCR не извлёк текст из: $filename"
    echo "" > "$out_path"
    add_frontmatter "$out_path" "$filepath" "pdf-scan-failed"
    echo "> Ни pandoc ни OCR не смогли извлечь текст." >> "$out_path"
    COUNT_ERR=$((COUNT_ERR+1))
  else
    echo "$ocr_text" > "$out_path"
    add_frontmatter "$out_path" "$filepath" "pdf-ocr"
    COUNT_OK=$((COUNT_OK+1))
  fi
}

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
        # Проверяем что pandoc реально извлёк текст (не пустой файл)
        text_len="$(awk '/^---/{found++; if(found==2){skip=0; next}} found<2{next} {print}' "$out_path" | tr -d '[:space:]' | wc -c | tr -d ' ')"
        if [[ "$text_len" -gt 50 ]]; then
          add_frontmatter "$out_path" "$filepath" "pdf"
          COUNT_OK=$((COUNT_OK+1))
        else
          warn "pandoc извлёк пустой текст из: $filename — пробую pdftotext..."
          if command -v pdftotext &>/dev/null; then
            pdftotext "$filepath" - 2>/dev/null > "$out_path"
            text_len="$(wc -c < "$out_path" | tr -d ' ')"
            if [[ "$text_len" -lt 50 ]]; then false; fi
            add_frontmatter "$out_path" "$filepath" "pdf"
            COUNT_OK=$((COUNT_OK+1))
          else
            warn "pdftotext не смог — пробую OCR: $filename"
            pdf_ocr "$filepath" "$out_path" "$filename"
          fi
        fi
      else
        warn "pandoc не смог обработать: $filename — пробую pdftotext..."
        if command -v pdftotext &>/dev/null; then
          pdftotext "$filepath" - 2>/dev/null > "$out_path"
          text_len="$(wc -c < "$out_path" | tr -d ' ')"
          if [[ "$text_len" -lt 50 ]]; then false; fi
          add_frontmatter "$out_path" "$filepath" "pdf"
          COUNT_OK=$((COUNT_OK+1))
        else
          warn "pdftotext не смог — пробую OCR: $filename"
          pdf_ocr "$filepath" "$out_path" "$filename"
        fi
      fi
      ;;

    docx|doc)
      log "DOCX → md: $filename"
      if pandoc "$filepath" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "docx"
        COUNT_OK=$((COUNT_OK+1))
      elif command -v soffice &>/dev/null; then
        log "pandoc не смог → LibreOffice: $filename"
        tmp_dir="$(mktemp -d)"
        if soffice --headless --convert-to docx "$filepath" --outdir "$tmp_dir" 2>/dev/null; then
          converted="$(find "$tmp_dir" -name "*.docx" | head -1)"
          if [[ -n "$converted" ]] && pandoc "$converted" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
            add_frontmatter "$out_path" "$filepath" "docx"
            COUNT_OK=$((COUNT_OK+1))
          else
            err "LibreOffice конвертировал но pandoc не смог: $filename"
            COUNT_ERR=$((COUNT_ERR+1))
          fi
        else
          err "LibreOffice не смог: $filename"
          COUNT_ERR=$((COUNT_ERR+1))
        fi
        rm -rf "$tmp_dir"
      else
        err "Ошибка конвертации (установи LibreOffice для .doc): $filename"
        COUNT_ERR=$((COUNT_ERR+1))
      fi
      ;;

    pptx|ppt)
      log "PPTX → md: $filename"
      if pandoc "$filepath" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "pptx"
        COUNT_OK=$((COUNT_OK+1))
      else
        err "Ошибка конвертации: $filename"
        COUNT_ERR=$((COUNT_ERR+1))
      fi
      ;;

    txt|log|out|err)
      log "TXT → md: $filename"
      cp "$filepath" "$out_path"
      add_frontmatter "$out_path" "$filepath" "txt"
      COUNT_OK=$((COUNT_OK+1))
      ;;

    md|markdown)
      log "MD → md: $filename"
      cp "$filepath" "$out_path"
      add_frontmatter "$out_path" "$filepath" "md"
      COUNT_OK=$((COUNT_OK+1))
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
          COUNT_ERR=$((COUNT_ERR+1))
        else
          COUNT_OK=$((COUNT_OK+1))
        fi
      else
        err "imagemagick не смог обработать: $filename"
        COUNT_ERR=$((COUNT_ERR+1))
      fi
      ;;

    xlsx|xls|csv)
      log "ТАБЛИЦА → md: $filename"
      if pandoc "$filepath" -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "spreadsheet"
        COUNT_OK=$((COUNT_OK+1))
      else
        warn "Пропускаю таблицу (pandoc не поддерживает): $filename"
        COUNT_SKIP=$((COUNT_SKIP+1))
      fi
      ;;

    html|htm)
      log "HTML → md: $filename"
      if pandoc "$filepath" -f html -t markdown --wrap=none -o "$out_path" 2>/dev/null; then
        add_frontmatter "$out_path" "$filepath" "html"
        COUNT_OK=$((COUNT_OK+1))
      else
        warn "Пропускаю HTML (pandoc не смог): $filename"
        COUNT_SKIP=$((COUNT_SKIP+1))
      fi
      ;;

    yaml|yml)
      log "YAML → md: $filename"
      { echo '```yaml'; cat "$filepath"; echo '```'; } > "$out_path"
      add_frontmatter "$out_path" "$filepath" "yaml"
      COUNT_OK=$((COUNT_OK+1))
      ;;

    puml|plantuml)
      log "PUML → md: $filename"
      { echo '```plantuml'; cat "$filepath"; echo '```'; } > "$out_path"
      add_frontmatter "$out_path" "$filepath" "diagram"
      COUNT_OK=$((COUNT_OK+1))
      ;;

    sql)
      log "SQL → md: $filename"
      { echo '```sql'; cat "$filepath"; echo '```'; } > "$out_path"
      add_frontmatter "$out_path" "$filepath" "sql"
      COUNT_OK=$((COUNT_OK+1))
      ;;

    7z|zip|rar|tar|gz)
      warn "Пропускаю архив: $filename"
      COUNT_SKIP=$((COUNT_SKIP+1))
      ;;

    drawio)
      log "DRAWIO → md: $filename"
      { echo '```xml'; cat "$filepath"; echo '```'; } > "$out_path"
      add_frontmatter "$out_path" "$filepath" "drawio"
      COUNT_OK=$((COUNT_OK+1))
      ;;

    bpmn)
      log "BPMN → md: $filename"
      { echo '```xml'; cat "$filepath"; echo '```'; } > "$out_path"
      add_frontmatter "$out_path" "$filepath" "bpmn"
      COUNT_OK=$((COUNT_OK+1))
      ;;

    iml|xml|json)
      warn "Пропускаю служебный файл: $filename"
      COUNT_SKIP=$((COUNT_SKIP+1))
      ;;

    *)
      warn "Пропускаю (неизвестный тип): $filename"
      COUNT_SKIP=$((COUNT_SKIP+1))
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

# --- показываем нечитабельные файлы ---
FAILED_FILES=()
while IFS= read -r -d '' fp; do
  if grep -q 'pdf-scan-failed\|pdf-ocr-failed' "$fp" 2>/dev/null; then
    src="$(grep "^source:" "$fp" | head -1 | sed 's/source: *"//' | sed 's/"$//')"
    FAILED_FILES+=("$src")
  fi
done < <(find "$TARGET_DIR" -name "*.md" -print0)

if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}  ⚠  Следующие файлы не удалось прочитать автоматически:${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  for f in "${FAILED_FILES[@]}"; do
    echo -e "  ${RED}✗${NC} $f"
  done
  echo ""
  echo -e "${YELLOW}  💡 Если эти файлы важны для базы знаний — конвертируй их вручную:${NC}"
  echo -e "     • Скопируй текст из PDF → сохрани как .md или .docx"
  echo -e "     • Сделай скриншот → сохрани как .jpg (OCR извлечёт текст)"
  echo -e "     • Или экспортируй из источника в .docx формат"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
fi

log "Следующий шаг: ./scripts/process.sh $JIRA"
