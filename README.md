# Second Brain — Personal Knowledge Pipeline

**Owner**: Solution Architect  
**Stack**: VS Code · Ollama · Obsidian · Claude API  
**Version**: 1.1 · April 2026

---

## Зачем это существует

Корпоративный AI-агент не справляется с реальными рабочими материалами из-за ограничений токенов и архитектуры. Корпоративная ИБ блокирует внешние AI-сервисы. При этом нужно вести до 3 параллельных проектов одновременно, не теряя контекст между ними.

**Решение**: персональный AI-слой поверх корпоративных ограничений — полностью локальный, данные не покидают машину, работает с реальными рабочими материалами.

---

## Архитектура

```
[ ЛОКАЛЬНО ]
  Working Docs/          ← рабочие папки, не трогаем, не перемещаем
  second-brain/
    raw/                 ← сырое входящее после конвертации
    knowledge/           ← обезличенные структурированные знания
  Ollama (Llama 3.1 8B) ← локальный AI-процессор, всё на GPU

[ ГИБРИД ]
  VS Code + Claude Code  ← оркестратор и среда разработки
  Obsidian               ← UI / граф знаний / поиск
  SA (оператор)          ← запросы, верификация, новые вопросы

[ ОБЛАКО — только обезличенное ]
  Claude API             ← глубокий архитектурный анализ
                            только knowledge/, никогда raw/
```

---

## Структура vault

```
~/projects/second-brain/
├── raw/
│   ├── ARCH-123/        ← номер задачи из Jira (CR)
│   │   └── 2026-04-30-название-документа.md
│   └── inbox/           ← входящее без тикета
├── knowledge/
│   ├── projects/
│   │   └── ARCH-123/
│   │       ├── business-context.md   ← HLD §3 / AN §1-2 / SPFA Блок 1
│   │       ├── requirements.md       ← HLD §4 (FR + NFR + Security)
│   │       ├── architecture.md       ← HLD §5 (AS-IS / TO-BE / интеграции)
│   │       ├── adrs.md               ← HLD §6 (Architecture Decision Records)
│   │       ├── risks.md              ← HLD concerns / AN §3.8 / SPFA Блок 9
│   │       ├── open-questions.md     ← HLD §7
│   │       ├── stakeholders.md       ← HLD §3.3 / EACMF RACI
│   │       └── spfa-assessment.md    ← только для вендорских инициатив
│   ├── stakeholders/    ← сквозные между проектами
│   ├── risks/
│   ├── decisions/
│   └── patterns/        ← архитектурные паттерны
├── references/          ← статьи, документация
├── scripts/
│   ├── ingest.sh        ← конвертация документов → markdown
│   └── process.sh       ← Ollama обработка raw/ → knowledge/
├── CLAUDE.md            ← системный промпт для Ollama (EACMF-aligned)
└── README.md            ← этот файл
```

---

## CJM: полный путь работы с проектом

### Шаг 1 — Получил задачу в Jira

Открываешь тикет, смотришь номер. Например `ARCH-123`.

Это будет твой ключ для всей работы с этим проектом в second-brain.

---

### Шаг 2 — Загрузка материалов в базу знаний

Запускаешь ingest для папки проекта:

```bash
./scripts/ingest.sh ARCH-123 '/path/to/your/project/folder'
```

Скрипт рекурсивно обходит папку и конвертирует:
- `.pdf` → pandoc → `.md`
- `.docx`, `.pptx` → pandoc → `.md`
- `.xlsx` → pandoc → `.md`
- `.txt` → `.md`
- `.png`, `.jpg` → tesseract OCR → `.md`

Каждый файл получает YAML frontmatter:
```yaml
---
source: "/path/to/original"
jira: "ARCH-123"
date: "2026-04-30"
processed: false
type: pdf|docx|pptx|spreadsheet|image|txt
---
```

Оригиналы не трогаются, не перемещаются, не удаляются.

---

### Шаг 3 — Обработка через Ollama

```bash
./scripts/process.sh ARCH-123
```

Ollama (Llama 3.1 8B, локально на GPU) читает каждый файл из `raw/ARCH-123/` где `processed: false` и делает до 8 проходов, маппируя знания на EACMF-артефакты:

1. **Бизнес-контекст** → `business-context.md` (HLD §3 / AN §1-2 / SPFA Блок 1)
2. **Требования** → `requirements.md` (FR + NFR + Security, HLD §4)
3. **Архитектура** → `architecture.md` (AS-IS / TO-BE / интеграции / сценарии, HLD §5)
4. **ADR** → `adrs.md` (Architecture Decision Records, HLD §6)
5. **Риски** → `risks.md` (HLD concerns / AN §3.8 / SPFA Блок 9)
6. **Открытые вопросы** → `open-questions.md` (HLD §7)
7. **Стейкхолдеры** → `stakeholders.md` (HLD §3.3 / EACMF RACI)
8. **SPFA оценка** → `spfa-assessment.md` (только для вендорских документов, автодетект)

После обработки файл помечается `processed: true` — повторно не обрабатывается.

Каждое извлечённое утверждение содержит обратную ссылку на источник: `[[2026-04-30-название-файла]]`

---

### Шаг 4 — Навигация в Obsidian

```bash
open ~/projects/second-brain
```

В Obsidian открываешь:
- `knowledge/projects/ARCH-123/architecture.md` — AS-IS / TO-BE / интеграции
- `knowledge/projects/ARCH-123/adrs.md` — принятые архитектурные решения
- `knowledge/projects/ARCH-123/risks.md` — все риски по проекту
- Graph view — видишь связи между проектами через общих стейкхолдеров и паттерны
- Поиск по тегам: `#adr`, `#risk`, `#requirement`, `#nfr`, `#open-question`, `#hypothesis`, `#spfa`

Клик на `[[ссылку]]` → переход к исходному документу в `raw/`.

---

### Шаг 5 — Глубокий анализ через Claude API

Когда нужен архитектурный анализ — берёшь **только обезличенный контент** из `knowledge/` и передаёшь в Claude (через Claude Code в VS Code или напрямую через API).

**Никогда в облако**: содержимое `raw/`, имена людей, названия компаний-клиентов, коммерческие условия.

**Можно в облако**: обезличенные сущности из `knowledge/`, архитектурные паттерны, общие вопросы типа "как описать риск интеграции".

---

### Шаг 6 — Новые документы по ходу проекта

По мере появления новых материалов — просто повторяешь ingest для новых файлов или папок:

```bash
./scripts/ingest.sh ARCH-123 '/path/to/new/meeting-notes'
./scripts/process.sh ARCH-123
```

Скрипт обработает только новые файлы (`processed: false`), уже обработанные пропустит.

---

### Шаг 7 — Сохранение в Git

```bash
git add knowledge/ scripts/ CLAUDE.md
git commit -m "ARCH-123: обработка материалов по ESS-IDM auth HLD"
git push
```

В `.gitignore` прописан `raw/` — сырые материалы в GitHub не попадают. В репозитории только обезличенные знания и скрипты.

---

## Маппинг knowledge/ на EACMF артефакты

Система следует процессу EACMF. Каждый файл в `knowledge/projects/{JIRA}/` соответствует конкретному разделу архитектурного артефакта:

| Файл | EACMF артефакт | Разделы |
|---|---|---|
| `business-context.md` | HLD / AN / SPFA | HLD §3, AN §1-2, SPFA Блок 1 |
| `requirements.md` | HLD / AN | HLD §4 (FR + NFR + Security) |
| `architecture.md` | HLD | HLD §5 (AS-IS / TO-BE / интеграции) |
| `adrs.md` | HLD / ADR | HLD §6, EACMF ADR-политика |
| `risks.md` | HLD / AN / SPFA | HLD concerns, AN §3.8, SPFA Блок 9 |
| `open-questions.md` | HLD | HLD §7 |
| `stakeholders.md` | HLD / EACMF | HLD §3.3, EACMF RACI |
| `spfa-assessment.md` | SPFA | Все блоки SPFA (вендорские инициативы) |

---

## Правило эпистемической честности

> Если утверждение в `knowledge/` нельзя привязать к источнику в `raw/` — оно помечается `#hypothesis`, не как факт.

Факты и предположения всегда разделены. Это ключевое правило системы.

---

## Что никогда не уходит в облако

- Содержимое `raw/` (сырые рабочие материалы)
- Имена сотрудников и заказчиков
- Коммерческие условия и цифры
- Архитектурные схемы с названиями систем заказчика
- Любые персональные данные

---

## Быстрый старт

```bash
# 1. Загрузить проект
./scripts/ingest.sh ARCH-123 '/path/to/project/folder'

# 2. Обработать через Ollama
./scripts/process.sh ARCH-123

# 3. Открыть базу знаний
open ~/projects/second-brain        # в Obsidian
code ~/projects/second-brain        # в VS Code

# 4. Убедиться что Ollama запущена (если после перезагрузки)
ollama serve &
```

---

## Зависимости

| Инструмент | Версия | Назначение |
|---|---|---|
| Homebrew | 4.5+ | Менеджер пакетов |
| Node.js | 25.9+ | Claude Code CLI |
| pandoc | 3.9+ | Конвертация документов |
| tesseract | 5.5+ | OCR изображений |
| ImageMagick | 7.1+ | Препроцессинг изображений |
| Ollama | 0.22+ | Локальный AI-процессор |
| llama3.1:8b | — | Языковая модель |
| Claude Code | 2.1+ | AI-оркестратор в VS Code |
| jq | 1.7+ | JSON обработка в скриптах |
| Obsidian | 1.12+ | UI для базы знаний |
| gh | 2.9+ | GitHub CLI |
