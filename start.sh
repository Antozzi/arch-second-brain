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
