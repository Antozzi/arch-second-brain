# DEPLOYMENT.md — Запуск, тестирование и диагностика

> Операционное руководство. Установка с нуля → INSTALLATION.md. Как работать с проектами → README.md.

---

## Запуск

### macOS / Linux

```bash
./start.sh
```

`start.sh` выполняет:
1. Проверяет Node.js
2. Проверяет Ollama — запускает автоматически если не запущена
3. Проверяет `.env` (ключи API)
4. Запускает `node server.js`

### Windows

```cmd
start.bat
```

Или через PowerShell:

```powershell
node server.js
```

### Ручной запуск (все платформы)

```bash
# Запустить Ollama отдельно (если не автостартует)
ollama serve &          # macOS/Linux
start "" /B ollama serve   # Windows cmd

# Запустить сервер
node server.js
```

Открой в браузере: **http://localhost:3030**

---

## Проверка работоспособности (тестовый прогон)

### Шаг 1 — Сервер отвечает?

```bash
curl http://localhost:3030/api/projects
```

Ожидаемый ответ: `[]` или список проектов в JSON.

### Шаг 2 — Ollama отвечает?

```bash
curl http://localhost:11434/api/version
curl -s http://localhost:11434/api/tags | python3 -c \
  "import sys,json; d=json.load(sys.stdin); [print(m['name']) for m in d['models']]"
```

Ожидаемый ответ: список установленных моделей.

### Шаг 3 — Ingest работает?

```bash
bash scripts/ingest.sh TEST-001 /path/to/one/file/folder
ls raw/TEST-001/
```

Ожидаемый результат: `*.md` файлы в `raw/TEST-001/`.

### Шаг 4 — Process работает?

```bash
OLLAMA_MODEL=gemma3:12b bash scripts/process.sh TEST-001
cat knowledge/projects/TEST-001/requirements.md 2>/dev/null || echo "пусто"
```

Ожидаемый результат: заполненные `*.md` файлы в `knowledge/projects/TEST-001/`.

### Шаг 5 — MAX_CHARS правильный?

Открой **⚙ Настройки** — поле MAX_CHARS покажет автовычисленное значение:
`авто: 10000 (ОЗУ 18ГБ, gemma3:12b)`

Если обработка зависает — уменьши вручную до 5000.

---

## Логи

Логи пишутся в `logs/` при каждом запуске. При успешном завершении лог автоматически удаляется — файл остаётся только если были ошибки или таймаут.

### Ingest

```
logs/ingest-ARCH-123-20260520_143012.log
```

Ключевые маркеры:

```
[OK]   Конвертирован: договор.pdf → договор.md
[WARN] tesseract не найден — OCR недоступен
[ERR]  Папка не найдена: /path/to/docs
[FILE-START] file=договор.pdf        ← с какого файла зависло
```

Типичные проблемы:
| Сообщение | Причина | Действие |
|-----------|---------|----------|
| `[WARN] пропущен: ~$file.docx` | Временный файл Office | Норма, игнорировать |
| `[ERR] Не найден: pandoc` | pandoc не установлен | `brew install pandoc` / `winget install JohnMacFarlane.Pandoc` |
| Файл в `[FILE-START]` без следующей строки | Зависание на конкретном файле | **⇥ Пропустить файл** в UI |

### Process

```
logs/process-ARCH-123-20260520_144500.log
```

Большие файлы режутся на чанки по `MAX_CHARS` — каждый чанк идёт через модель
отдельной строкой `[START-MODEL] ... chunk=N/M`.

Ключевые маркеры:

```
[INFO] Используется скилл проекта: ARCH-123-SKILL.md
[FILE-CHUNKS] file=spec.md chunks=9 doc_type=hld
[START-MODEL] file=spec.md chunk=1/9 doc_type=hld chars=10000 model=gemma3:12b num_ctx=12288
[END-MODEL]   file=spec.md chunk=1/9 elapsed=60s response_len=2341
[OK]   Создан: architecture.md
[OK]   Обновлён: requirements.md
[INFO] Файл готов: успешно 9/9 чанков
[WARN] Гарблед контент (18% читаемых символов) — пропускаю: scan.md
[TIMEOUT] file=big-doc.md chunk=4/9 elapsed=180s
[DONE] ok=5 skip=2 err=1
```

Расшифровка:
| Строка | Значение |
|--------|----------|
| `[FILE-CHUNKS] chunks=9` | Файл разбит на 9 чанков, каждый обрабатывается отдельно |
| `chunk=1/9` | Текущий чанк из общего числа |
| `chars=10000` | Размер чанка, переданный в модель (≤ MAX_CHARS) |
| `num_ctx=12288` | Размер контекстного окна Ollama |
| `elapsed=60s` | Время ответа модели на чанк |
| `response_len=2341` | Модель вернула ответ, JSON парсится |
| `Файл готов: успешно 9/9` | Сколько чанков файла обработано без ошибок |
| `Гарблед контент (18%)` | PDF с битой кодировкой, файл корректно пропущен |
| `[TIMEOUT]` | Модель не ответила за 180с на чанке |

---

## Мониторинг в реальном времени

```bash
# Следить за текущим процессом
tail -f logs/process-ARCH-123-*.log

# Найти все незакрытые логи (с ошибками)
ls -la logs/

# Что сейчас обрабатывается (последняя строка лога)
tail -1 logs/process-ARCH-123-*.log
```

---

## Диагностика проблем

### Сервер не стартует

```bash
node --version   # нужен v18+
lsof -i :3030    # порт занят?
# macOS/Linux: kill $(lsof -t -i:3030)
# Windows:     netstat -ano | findstr :3030 → taskkill /PID <pid> /F
```

### Ollama не запускается

```bash
ollama serve &
curl http://localhost:11434/api/version
```

Windows: убедись что Ollama установлена (`winget install Ollama.Ollama`) и PATH содержит её директорию.

### PDF не читается

Скопируй текст вручную → сохрани как `.md` → загрузи через **⚠ Пропущенные файлы → ⇪ Заменить**.

### Модель зависает на файле

Нажми **⇥ Пропустить файл** в UI — файл будет помечен как обработанный, следующий начнётся автоматически.

### Все ответы модели пустые или мусор

```bash
# Проверь лог
cat logs/process-ARCH-123-*.log | grep -E "TIMEOUT|json-extract|response_len=0"

# Попробуй модель с поддержкой кириллицы
ollama pull qwen2.5:7b
# В Настройках → Ollama модель → qwen2.5:7b
```

### Claude API ошибка

Проверь баланс: https://console.anthropic.com/settings/billing

### PlantUML: диаграмма не рендерится

Превью показывает «PlantUML недоступен». Проверь:

```bash
java -version                       # нужна Java (любая 8+)
ls -lh vendor/plantuml.jar           # jar на месте? (~26 МБ)
```

- Нет Java → `brew install openjdk` (macOS/Linux) / `winget install Microsoft.OpenJDK.21` (Windows)
- Нет jar → перезапусти `./start.sh` — он скачает автоматически, либо `brew install plantuml`
- Превью с красным текстом `Syntax Error` — это ошибка в самом коде PlantUML: отредактируй код в левом поле и нажми **↻ Обновить превью**

Проверка рендера вручную:

```bash
echo '@startuml
A -> B: test
@enduml' | java -jar vendor/plantuml.jar -tsvg -pipe -charset UTF-8 | head -c 60
```

### drawio: превью пустое или не загружается

Режим **⬚ drawio диаграмма** рендерит превью офлайн-вьюером в браузере.

- Вьюер не загрузился → проверь, что файл на месте: `ls -lh ui/drawio-viewer.min.js` (~3.8 МБ).
  Если файла нет — скачай заново:
  ```bash
  curl -sL -o ui/drawio-viewer.min.js \
    https://github.com/jgraph/drawio/raw/v30.0.2/src/main/webapp/js/viewer-static.min.js
  ```
- Диаграмма сгенерировалась, но превью пустое → нажми **↻ Обновить превью**; проверь XML в левом поле.
- Импорт `.drawio` не извлёк объекты → файл может быть в сжатом формате; система распаковывает
  его автоматически, но если объектов `0` — открой файл в diagrams.net и пересохрани как
  **Uncompressed**.

Каталог объектов проекта: `knowledge/projects/<JIRA>/diagram-objects.json`,
сохранённые диаграммы: `knowledge/projects/<JIRA>/diagrams/`.

### Windows: bash-скрипты не работают

Убедись что Git for Windows установлен и `C:\Program Files\Git\bin` есть в PATH.
`start.bat` добавляет эти пути автоматически через `server.js` при запуске.

### Windows: garbled output в терминале

`start.bat` устанавливает `chcp 65001` (UTF-8). Если кириллица всё равно не отображается:

```cmd
chcp 65001
```

---

## Управление процессами

| Действие | macOS/Linux | Windows |
|----------|------------|---------|
| Остановить сервер | Ctrl+C | Ctrl+C |
| Остановить Ollama | `pkill ollama` | `taskkill /IM ollama.exe /F` |
| Проверить порт | `lsof -i :3030` | `netstat -ano \| findstr :3030` |
| Перезапустить | `./start.sh` | `start.bat` |

---

## Сохранение базы знаний в git

```bash
git add knowledge/ templates/ scripts/ skills/ CLAUDE.md
git commit -m "ARCH-123: обновление базы знаний"
git push
```

Сырые материалы (`raw/`) и API ключи (`.env`) в git не попадают — только структурированные знания.
