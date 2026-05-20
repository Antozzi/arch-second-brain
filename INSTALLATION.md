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
brew install node pandoc tesseract imagemagick ollama jq gh poppler openjdk

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
│       ├── stakeholders.md
│       ├── diagram-objects.json   ← каталог объектов drawio
│       └── diagrams/              ← сохранённые .drawio диаграммы
├── templates/             ← шаблоны артефактов
├── skills/                ← доменные скиллы (в git)
│   ├── README.md
│   └── my-skill/
│       └── SKILL.md
├── scripts/
│   ├── ingest.sh                        ← конвертация документов
│   ├── process.sh                       ← обработка через Ollama
│   ├── process_book.sh                  ← создание скилла из PDF книги
│   └── create_skill_from_knowledge.sh   ← создание скилла из базы знаний
├── ui/
│   ├── index.html         ← веб-интерфейс
│   └── drawio-viewer.min.js  ← офлайн-вьюер drawio
├── vendor/                ← plantuml.jar (не в git, авто-скачивание)
├── server.js              ← Node.js сервер
├── CLAUDE.md              ← системный промпт (встроенный скилл)
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

## Шаг 9 — Диаграммы (опционально)

В разделе **◈ Генерация артефакта** есть два режима генерации диаграмм из базы знаний.

### ◫ PlantUML диаграмма

Модель строит диаграммы (sequence, component, C4, deployment, activity, ER и др.)
с живым превью.

Рендер требует **Java** (ставится в Шаге 1 как `openjdk`). Сам PlantUML
(`vendor/plantuml.jar`, ~26 МБ) скачивается автоматически при первом запуске `./start.sh`.

Если нужен ручной контроль — можно поставить PlantUML через пакетный менеджер:

```bash
brew install plantuml          # macOS / Linux
# choco install plantuml       # Windows
```

Команда `plantuml` в PATH используется автоматически, если `vendor/plantuml.jar` отсутствует.

### ⬚ drawio диаграмма

Модель собирает валидный drawio XML, который можно экспортировать в `.drawio`,
сохранить в проект и редактировать в [diagrams.net](https://www.drawio.com/).
Существующие `.drawio` импортируются — их объекты попадают в каталог проекта
(`knowledge/projects/<JIRA>/diagram-objects.json`) и переиспользуются в новых диаграммах.

Дополнительная установка не нужна — офлайн-вьюер (`ui/drawio-viewer.min.js`)
поставляется с репозиторием, превью рендерится в браузере без обращений к сети.

---

## Шаг 10 — Скиллы (опционально)

Скиллы — это дистиллированная экспертиза для модели. Чем их больше, тем точнее ответы по предметной области.

### Создать скилл из PDF книги или документации

Через UI: **◆ Скиллы** → форма **⊕ Создать скилл из PDF** → укажи путь → нажми кнопку.

Или через терминал:
```bash
./scripts/process_book.sh ~/Downloads/clean-architecture.pdf clean-architecture
```

Требует запущенного `ollama serve` и установленного `poppler` (для `pdftotext`).

### Создать доменный скилл из базы знаний проекта

После обработки проекта через Ollama: **◆ Скиллы** → форма **◎ Создать из знаний проекта** → выбери проект → нажми кнопку.

Или через терминал:
```bash
./scripts/create_skill_from_knowledge.sh ARCH-123
```

Скилл сохраняется в `skills/ARCH-123-domain/SKILL.md` и автоматически подхватывается CLAUDE.md.

---

## Диагностика по логам

Система пишет логи в папку `logs/` для каждого запуска. При успешном прогоне лог удаляется автоматически — файл остаётся только если были ошибки или таймауты.

### Ingest (конвертация документов)

```
logs/ingest-ARCH-123-20260520_143012.log
```

Что искать:
```
[OK]   Конвертирован: договор.pdf → договор.md
[WARN] tesseract не найден — OCR недоступен
[ERR]  Папка не найдена: /path/to/docs
[FILE-START] file=договор.pdf        ← с какого файла упало
```

Ключевые проблемы:
- `[WARN] пропущен: ~$file.docx` — временный файл Office, это нормально
- `[ERR] Не найден: pandoc` — нужно `brew install pandoc`
- Файл попал в `[FILE-START]` но нет следующего → зависание на конкретном документе, используй **⇥ Пропустить файл**

---

### Process (обработка через Ollama)

```
logs/process-ARCH-123-20260520_144500.log
```

Что искать:
```
[INFO] Используется скилл проекта: ARCH-123-SKILL.md
[START-MODEL] file=spec.md doc_type=hld chars=7420 model=gemma3:12b num_ctx=12800
[END-MODEL]   file=spec.md elapsed=45s response_len=2341
[OK]   Создан: architecture.md
[OK]   Обновлён: requirements.md
[WARN] Гарблед контент (18% читаемых символов) — пропускаю: scan.md
[TIMEOUT] file=big-doc.md elapsed=180s
[DONE] ok=5 skip=2 err=1
```

Как читать:
| Строка | Значение |
|--------|----------|
| `chars=7420` | размер контента передан в модель |
| `num_ctx=12800` | размер контекстного окна Ollama |
| `elapsed=45s` | время ответа модели на этот файл |
| `response_len=2341` | модель вернула ответ, JSON парсится |
| `Гарблед контент (18%)` | PDF с битой кодировкой, файл пропущен корректно |
| `[TIMEOUT]` | модель не ответила за 180с — увеличь таймаут или уменьши MAX_CHARS |

---

### Проверка шагов вручную

**Шаг 1 — Ingest работает?**
```bash
bash scripts/ingest.sh TEST-001 /path/to/one/file/folder
ls raw/TEST-001/
```

**Шаг 2 — Process работает?**
```bash
OLLAMA_MODEL=gemma3:12b bash scripts/process.sh TEST-001
cat knowledge/projects/TEST-001/requirements.md 2>/dev/null || echo "пусто"
```

**Шаг 3 — Ollama отвечает?**
```bash
curl -s http://localhost:11434/api/tags | python3 -c "import sys,json; d=json.load(sys.stdin); [print(m['name']) for m in d['models']]"
```

**Шаг 4 — MAX_CHARS правильный?**

Открой **⚙ Настройки** — в поле MAX_CHARS будет показано авто-значение с пояснением `авто: 10000 (ОЗУ 18ГБ, gemma3:12b)`. Если обработка зависает — уменьши вручную до 5000.

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

**Модель зависает на файле:**
Нажми **⇥ Пропустить файл** в UI — файл будет помечен как обработанный, обработка продолжится со следующего.

**Все ответы модели пустые или мусор:**
```bash
# Проверь лог — ищи response_len=0 или json-extract error
cat logs/process-ARCH-123-*.log | grep -E "TIMEOUT|json-extract|response_len=0"

# Попробуй модель с поддержкой кириллицы
ollama pull qwen2.5:7b
# В Настройках → Ollama модель → qwen2.5:7b
```

**Claude API ошибка:**
Проверь баланс: https://console.anthropic.com/settings/billing
