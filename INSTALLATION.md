# Installation Guide — Second Brain

> Этот документ нужен один раз. После установки работай через UI.

---

## Требования

- macOS с Apple Silicon (M1/M2/M3) — рекомендуется 16GB+ unified memory
- Homebrew — если нет: `https://brew.sh`
- GitHub аккаунт — для синхронизации knowledge base

---

## Шаг 1 — Установка зависимостей

```bash
# Все CLI инструменты одной командой
brew install node pandoc tesseract imagemagick ollama jq gh

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Obsidian (UI для базы знаний)
brew install --cask obsidian
```

Проверка что всё встало:

```bash
node --version && pandoc --version | head -1 && tesseract --version 2>&1 | head -1 && ollama --version && claude --version
```

---

## Шаг 2 — Загрузка языковой модели

```bash
# Запускаем Ollama как сервис
ollama serve &
```

Выбери модель по своим условиям:

| Модель | Размер | Контекст | Качество | Скорость |
|--------|--------|----------|----------|----------|
| `llama3.1:8b` | 4.7 GB | 8K | хорошее | быстро |
| `gemma3:12b` | 8 GB | 128K | лучше | средне |
| `qwen2.5:14b` | 9 GB | 128K | отлично (русский) | медленнее |

**Рекомендация для M3 Pro 18GB:** `gemma3:12b` — оптимальный баланс.

```bash
# Минимум (быстрый старт)
ollama pull llama3.1:8b

# Рекомендуется (лучше качество, длиннее ответы)
ollama pull gemma3:12b

# Можно установить несколько и переключаться в UI
```

Проверка:
```bash
ollama run gemma3:12b "Привет, скажи OK"
```

---

## Шаг 3 — Создание репозитория

```bash
# Авторизация в GitHub
gh auth login

# Создаём структуру проекта
mkdir -p ~/projects/second-brain/{raw/inbox,knowledge/{projects,stakeholders,risks,decisions,patterns},references,scripts,templates,ui}
cd ~/projects/second-brain

# Инициализация git и публикация
git init
echo "raw/" > .gitignore
echo ".obsidian/" >> .gitignore
echo ".env" >> .gitignore
git add .gitignore
git commit -m "init: second-brain vault"
gh repo create second-brain --private --source=. --remote=origin --push
```

---

## Шаг 4 — Настройка Obsidian

1. Открой Obsidian
2. **Open folder as vault** → выбери `~/projects/second-brain`
3. Settings (⌘,) → Files & Links:
   - New link format → `Shortest path when possible`
   - Use Wikilinks → включить
4. Core plugins → включить: Backlinks, Graph view, Tags view

---

## Шаг 5 — Настройка VS Code

```bash
# Добавляем code в PATH: ⌘⇧P → "Install 'code' command in PATH"

# Устанавливаем расширение Claude Code
code --install-extension anthropic.claude-code

# Открываем проект
code ~/projects/second-brain
```

---

## Шаг 6 — Запуск UI

```bash
cd ~/projects/second-brain
node server.js
```

Открой в браузере: **http://localhost:3030**

Для автозапуска создай алиас в `~/.zshrc`:
```bash
echo 'alias brain="cd ~/projects/second-brain && node server.js"' >> ~/.zshrc
source ~/.zshrc
```

Теперь достаточно написать `brain` в терминале.

---

## Шаг 7 — Настройка моделей в UI

### Ollama (локальная модель)

Открой **⚙ Настройки** → Ollama модель → выбери из списка установленных → сохрани.

Переключение между моделями не требует перезапуска сервера — применяется сразу.

### Claude API (опционально, для глубокого анализа)

1. Зарегистрируйся на **https://console.anthropic.com**
2. Создай ключ: Settings → API Keys → Create Key
3. Пополни баланс: Settings → Billing (минимум $5)
4. Открой **⚙ Настройки** в UI → введи ключ → выбери модель → сохрани

Доступные Claude модели:
- `claude-sonnet-4-6` — рекомендуется (баланс цена/качество)
- `claude-opus-4-6` — максимальное качество, дороже
- `claude-haiku-4-5-20251001` — быстрее, дешевле

Ключ хранится в `.env` локально и никогда не попадает в git.

---

## Шаг 8 — Шаблоны артефактов

В папку `templates/` положи шаблоны в формате `.md`:

| Файл | Артефакт |
|------|---------|
| `HLD.md` | High Level Design |
| `HLIS.md` | High Level Integration Specification |
| `AN-Pre-Analysis.md` | Architectural Note Pre-Analysis |
| `AN-Post-Analysis.md` | Architectural Note Post-Analysis |
| `SPFA.md` | Software Product Full Assessment |
| `BRD.md` | Business Requirements Document |

Шаблоны автоматически появляются в UI в разделе **◈ Генерация артефакта**.

---

## Структура проекта

```
~/projects/second-brain/
├── raw/                   ← конвертированные документы (не в git)
│   └── ARCH-123/
├── knowledge/             ← база знаний (в git)
│   └── projects/ARCH-123/
│       ├── business-context.md
│       ├── requirements.md
│       ├── architecture.md
│       ├── adrs.md
│       ├── risks.md
│       ├── open-questions.md
│       └── stakeholders.md
├── templates/             ← шаблоны артефактов
├── scripts/
│   ├── ingest.sh          ← конвертация документов
│   └── process.sh         ← обработка через Ollama
├── ui/
│   └── index.html         ← веб-интерфейс
├── server.js              ← Node.js сервер
├── CLAUDE.md              ← системный промпт для Ollama
├── .env                   ← API ключи (не в git)
└── .gitignore
```

---

## Поддерживаемые форматы файлов

| Формат | Конвертация | Примечание |
|--------|------------|------------|
| `.pdf` | pandoc → md, fallback OCR | Сканы через tesseract |
| `.docx`, `.doc` | pandoc → md | |
| `.pptx`, `.ppt` | pandoc → md | |
| `.xlsx`, `.xls`, `.csv` | pandoc → md | |
| `.md`, `.txt`, `.log` | копирование | |
| `.png`, `.jpg`, `.jpeg` | tesseract OCR | |
| `.yaml`, `.yml` | как code block | |
| `.sql` | как code block | |
| `.puml`, `.plantuml` | как code block | |
| `.drawio` | как XML | |
| `.bpmn` | как XML | |
| `.html`, `.htm` | pandoc → md | |
| `.drawio` | как XML | компоненты и связи |
| `.bpmn` | как XML | процессы и роли |
| `.log`, `.out`, `.err` | копирование | логи и вывод |

---

## Решение проблем

**Ollama не запускается:**
```bash
ollama serve &
curl http://localhost:11434/api/version
```

**Сервер не стартует:**
```bash
node --version  # нужен v18+
lsof -i :3030   # порт занят?
```

**PDF не читается:**
Скопируй текст вручную → сохрани как `.md` → загрузи через **⚠ Пропущенные файлы → ⇪ Заменить**

**Claude API ошибка:**
Проверь баланс: https://console.anthropic.com/settings/billing
