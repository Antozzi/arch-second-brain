## Personal Knowledge Pipeline · Solution Architect · Beeline KZ
**Version**: 1.0 · April 2026  
**Owner**: Anton Dyrdin  
**Stack**: VS Code · Ollama · Obsidian · Claude API

---

## Контекст и цель

Solution Architect в ИТ-компании (дочка Beeline KZ). До 3 параллельных проектов одновременно.

**Pain point**: корпоративный AI-агент (Aventa) не справляется из-за ограничений токенов и архитектуры. Корпоративная ИБ блокирует ChatGPT/Claude Pro. Рабочий Mac M3 Pro 18GB.

**Цель системы**: персональный AI-слой поверх корпоративных ограничений — полностью локальный, данные не покидают машину, работает с реальными рабочими материалами.

---

## Железо и окружение

- MacBook Pro M3 Pro · 18GB unified memory
- VS Code (основная IDE и оркестратор)
- Obsidian (UI для навигации по knowledge base)
- Рабочая папка: `iCloud Drive/Documents/Working Docs before OneDrive/`

**Активные проекты** (папки-источники):
- АМЛ (82.8 MB)
- ESS-IDM (464.6 MB)
- Unitel (182.8 MB)
- PureHealth (4 MB)
- Presales (79 KB)
- EA, EDMS, DARLean, Pulse AI, R&D Lab и др.

---

## Архитектура системы

### Слои

```
[ ЛОКАЛЬНО ]
  Working Docs/          ← рабочие папки, не трогаем
  second-brain/
    raw/                 ← сырое входящее после конвертации
    knowledge/           ← обезличенные структурированные знания
  Ollama (Llama 3.1 8B) ← локальный AI-процессор

[ ГИБРИД ]
  VS Code + Claude Code CLI  ← оркестратор
  Obsidian                   ← UI / граф / поиск
  Me / SA                    ← оператор: queries, challenge, new questions

[ ОБЛАКО — только обезличенное ]
  Claude API             ← глубокий архитектурный анализ
```

### Структура vault

```
~/projects/second-brain/
├── raw/
│   ├── ARCH-001/        ← по номеру задачи в Jira
│   │   └── 2026-04-30-ess-idm-auth-hld.md
│   ├── ARCH-042/
│   └── inbox/           ← входящее без тикета
├── knowledge/
│   ├── projects/
│   │   ├── ARCH-001/
│   │   │   ├── stakeholders.md
│   │   │   ├── risks.md
│   │   │   ├── decisions.md
│   │   │   └── open-questions.md
│   │   └── ARCH-042/
│   ├── stakeholders/    ← сквозные (между проектами)
│   ├── risks/
│   ├── decisions/
│   └── patterns/        ← архитектурные паттерны
├── references/          ← статьи, документация (не raw)
├── scripts/
│   ├── ingest.sh        ← главный скрипт конвертации
│   └── process.sh       ← запуск Ollama обработки
└── CLAUDE.md            ← системный промпт для агента
```

---

## Скрипт ingest.sh — что должен делать

**Запуск**: `./scripts/ingest.sh ARCH-42 ~/path/to/folder`

**Шаги**:
1. Создать `raw/ARCH-42/` если не существует
2. Рекурсивно обойти указанную папку
3. Конвертировать по типу файла:
   - `.pdf` → `pandoc` → `.md`
   - `.docx`, `.pptx` → `pandoc` → `.md`
   - `.txt` → переименовать в `.md`
   - `.png`, `.jpg`, `.jpeg` → `tesseract` OCR → `.md`
4. Добавить в каждый файл метаданные:
   ```yaml
   ---
   source: оригинальный путь к файлу
   jira: ARCH-42
   date: 2026-04-30
   processed: false
   type: pdf|docx|image|txt
   ---
   ```
5. Сохранить в `raw/ARCH-42/YYYY-MM-DD-originalname.md`
6. Оригиналы не трогать, не перемещать, не удалять

**Зависимости**: `pandoc`, `tesseract`, `imagemagick`

---

## CLAUDE.md — системный промпт для Ollama

```markdown
# Knowledge Pipeline Instructions

## Role
You are a knowledge processor for a Solution Architect at a telecom IT company.
Process files from raw/ and maintain structured knowledge base in knowledge/.

## Processing rules
1. Read all .md files in raw/ where processed: false
2. Extract entities:
   - Stakeholders (name → role → project → interests)
   - Risks (description → impact → mitigation → source)
   - Decisions (what → why → alternatives rejected → source)
   - Open questions (question → context → owner)
3. Create or UPDATE corresponding files in knowledge/projects/{jira}/
4. Every claim MUST have backlink [[source-file]] to raw/ origin
5. If claim has no traceable source → mark as #hypothesis
6. After processing → set processed: true in the raw/ file

## Output format
- Use Obsidian wiki-links: [[filename]]
- Tags: #risk #stakeholder #decision #open-question #hypothesis
- Language: Russian (same as source documents)

## Privacy rule
- Never include full names of individuals in knowledge/ files
- Use roles instead: "Product Owner", "Security Lead", "CTO"
- Codenames are acceptable: "Stakeholder-A"
```

---

## Правило эпистемической честности

> Если утверждение в `knowledge/` нельзя привязать к источнику в `raw/` — оно помечается `#hypothesis`, не как факт.

Это ключевое правило системы. Факты vs предположения должны быть разделены.

---

## Модель Ollama

**Выбор**: `llama3.1:8b` — оптимум для M3 Pro 18GB

```bash
# Установка
brew install ollama
ollama pull llama3.1:8b

# Проверка
ollama run llama3.1:8b "Привет, отвечай по-русски"
```

При необходимости глубокого анализа (архитектурные паттерны, сложные запросы) — переключаться на Claude API вручную, передавая только обезличенный контент из `knowledge/`.

---

## Что в облако — никогда

- Содержимое `raw/` (сырые рабочие материалы)
- Имена сотрудников и заказчиков
- Коммерческие условия и цифры
- Архитектурные схемы с названиями систем заказчика

## Что в облако — можно

- Обезличенные сущности из `knowledge/`
- Архитектурные паттерны без привязки к заказчику
- Общие вопросы типа "как лучше описать риск интеграции"

---

## Порядок реализации

### Шаг 1 — Окружение
```bash
brew install node pandoc tesseract imagemagick ollama
npm install -g @anthropic/claude-code
ollama pull llama3.1:8b
```

### Шаг 2 — Структура vault
```bash
mkdir -p ~/projects/second-brain/{raw/inbox,knowledge/{projects,stakeholders,risks,decisions,patterns},references,scripts}
cd ~/projects/second-brain
git init
```

### Шаг 3 — Obsidian
Открыть `~/projects/second-brain/` как новый vault.

### Шаг 4 — VS Code
Открыть `~/projects/second-brain/` как проект.
Установить расширение: Claude Code (Anthropic).

### Шаг 5 — ingest.sh
Написать и протестировать скрипт конвертации.
Первый тест: папка `Presales/` (79 KB — маленькая, безопасно).

### Шаг 6 — CLAUDE.md
Создать системный промпт, протестировать на результатах Шага 5.

### Шаг 7 — process.sh
Скрипт запуска Ollama обработки `raw/` → `knowledge/`.

---

## Команды быстрого старта (итог)

```bash
# Загрузить проект в базу знаний
./scripts/ingest.sh ARCH-42 ~/path/to/project/folder

# Запустить обработку Ollama
./scripts/process.sh ARCH-42

# Открыть базу знаний
open ~/projects/second-brain  # в Obsidian
code ~/projects/second-brain  # в VS Code
```

---

## Для нового чата — инструкция

Скажи: *"Читай контекст из файла second-brain-architecture.md — мы реализуем этот проект. Начинаем с Шага 1."*

Или вставь содержимое этого файла целиком как первое сообщение.
