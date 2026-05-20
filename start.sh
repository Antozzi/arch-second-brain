#!/usr/bin/env bash
# Запуск Second Brain UI
cd "$(dirname "$0")"

echo ""
echo "╔══════════════════════════════════╗"
echo "║       Second Brain  🧠            ║"
echo "╚══════════════════════════════════╝"
echo ""

# --- проверка Node.js ---
if ! command -v node &>/dev/null; then
  echo "  [ERR] Node.js не найден. Установи: brew install node"
  exit 1
fi
NODE_VER=$(node --version)
echo "  [OK] Node.js $NODE_VER"

# --- проверка Ollama ---
if ! curl -s --max-time 3 http://localhost:11434/api/version > /dev/null 2>&1; then
  echo "  [..] Запускаю Ollama..."
  ollama serve &>/dev/null &
  sleep 3
  if ! curl -s --max-time 3 http://localhost:11434/api/version > /dev/null 2>&1; then
    echo "  [WARN] Ollama не запустилась — локальные модели недоступны"
    echo "         Запусти вручную: ollama serve &"
  else
    echo "  [OK] Ollama запущена"
  fi
else
  echo "  [OK] Ollama работает"
fi

# --- проверка PlantUML (рендер диаграмм) ---
if [[ -f "vendor/plantuml.jar" ]]; then
  echo "  [OK] PlantUML jar найден (диаграммы доступны)"
elif command -v plantuml &>/dev/null; then
  echo "  [OK] PlantUML в PATH (диаграммы доступны)"
elif command -v java &>/dev/null; then
  echo "  [..] Скачиваю PlantUML jar (~26МБ, один раз)..."
  mkdir -p vendor
  if curl -sL -o "vendor/plantuml.jar" \
    "https://github.com/plantuml/plantuml/releases/download/v1.2026.3/plantuml-1.2026.3.jar"; then
    echo "  [OK] PlantUML jar установлен"
  else
    rm -f vendor/plantuml.jar
    echo "  [WARN] не удалось скачать PlantUML — рендер диаграмм недоступен"
  fi
else
  echo "  [--] Java не найдена — рендер диаграмм недоступен (см. INSTALLATION.md)"
fi

# --- кириллическая модель (для русскоязычных документов) ---
QWEN_MARKER="logs/.no-qwen"
mkdir -p logs
if curl -s --max-time 3 http://localhost:11434/api/tags >/dev/null 2>&1; then
  CYR_MODEL="$(curl -s --max-time 3 http://localhost:11434/api/tags 2>/dev/null \
    | grep -oE '"name":"[^"]*"' | grep -iE 'qwen|aya|vikhr|saiga|mistral' | head -1)"
  if [[ -n "$CYR_MODEL" ]]; then
    echo "  [OK] Кириллическая модель установлена"
  elif [[ -f "$QWEN_MARKER" ]]; then
    echo "  [--] Кириллическая модель пропущена (выбор сохранён)"
  else
    echo ""
    printf "  Будешь работать с русскоязычными документами? qwen2.5 точнее с русским [y/N]: "
    read -r ANS
    if [[ "$ANS" =~ ^[yYдД] ]]; then
      echo "  [..] Устанавливаю qwen2.5:7b (~4.7 ГБ, разово)..."
      ollama pull qwen2.5:7b && echo "  [OK] qwen2.5:7b установлена" \
        || echo "  [WARN] не удалось установить — можно позже в UI"
    else
      touch "$QWEN_MARKER"
      echo "  [--] Пропущено (больше не спрашиваю; можно поставить в потоке Ingest)"
    fi
  fi
fi

# --- проверка .env ---
if [[ -f ".env" ]]; then
  echo "  [OK] .env найден (API ключи загружены)"
else
  echo "  [--] .env не найден (Claude API недоступен — только локальная модель)"
fi

echo ""
echo "  Открой браузер: http://localhost:3030"
echo "  Для остановки: Ctrl+C"
echo "  Подробнее:      DEPLOYMENT.md"
echo ""

node server.js
