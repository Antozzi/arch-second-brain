#!/usr/bin/env bash
# Запуск Second Brain UI
cd "$(dirname "$0")"

# Проверяем Ollama
if ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
  echo "⚡ Запускаю Ollama..."
  ollama serve &
  sleep 3
fi

echo "🧠 Запускаю Second Brain UI..."
node server.js
