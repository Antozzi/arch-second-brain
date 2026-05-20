@echo off
chcp 65001 > nul
cd /d "%~dp0"

echo.
echo ╔══════════════════════════════════╗
echo ║       Second Brain  ^🧠           ║
echo ╚══════════════════════════════════╝
echo.

:: --- проверка Node.js ---
where node >nul 2>&1
if errorlevel 1 (
  echo   [ERR] Node.js не найден.
  echo         Установи: winget install OpenJS.NodeJS
  pause
  exit /b 1
)
for /f "tokens=*" %%v in ('node --version') do set NODE_VER=%%v
echo   [OK] Node.js %NODE_VER%

:: --- проверка Ollama ---
curl -s --max-time 3 http://localhost:11434/api/version >nul 2>&1
if errorlevel 1 (
  echo   [..] Запускаю Ollama...
  start "" /B ollama serve
  timeout /t 4 /nobreak >nul
  curl -s --max-time 3 http://localhost:11434/api/version >nul 2>&1
  if errorlevel 1 (
    echo   [WARN] Ollama не запустилась - локальные модели недоступны
    echo          Запусти вручную: ollama serve
  ) else (
    echo   [OK] Ollama запущена
  )
) else (
  echo   [OK] Ollama работает
)

:: --- проверка PlantUML (рендер диаграмм) ---
if exist "vendor\plantuml.jar" (
  echo   [OK] PlantUML jar найден ^(диаграммы доступны^)
) else (
  where plantuml >nul 2>&1
  if not errorlevel 1 (
    echo   [OK] PlantUML в PATH ^(диаграммы доступны^)
  ) else (
    where java >nul 2>&1
    if errorlevel 1 (
      echo   [--] Java не найдена - рендер диаграмм недоступен ^(см. INSTALLATION.md^)
    ) else (
      echo   [..] Скачиваю PlantUML jar ^(~26МБ, один раз^)...
      if not exist "vendor" mkdir vendor
      curl -sL -o "vendor\plantuml.jar" "https://github.com/plantuml/plantuml/releases/download/v1.2026.3/plantuml-1.2026.3.jar"
      if exist "vendor\plantuml.jar" (
        echo   [OK] PlantUML jar установлен
      ) else (
        echo   [WARN] не удалось скачать PlantUML - рендер диаграмм недоступен
      )
    )
  )
)

:: --- кириллическая модель (для русскоязычных документов) ---
if not exist "logs" mkdir logs
curl -s --max-time 3 http://localhost:11434/api/tags >nul 2>&1
if errorlevel 1 goto skipcyr
curl -s --max-time 3 http://localhost:11434/api/tags 2>nul | findstr /i "qwen aya vikhr saiga mistral" >nul 2>&1
if not errorlevel 1 (
  echo   [OK] Кириллическая модель установлена
  goto skipcyr
)
if exist "logs\.no-qwen" (
  echo   [--] Кириллическая модель пропущена ^(выбор сохранён^)
  goto skipcyr
)
echo.
set /p ANS="  Будешь работать с русскоязычными документами? qwen2.5 точнее [y/N]: "
if /i "%ANS%"=="y" goto pullqwen
if /i "%ANS%"=="д" goto pullqwen
echo done> "logs\.no-qwen"
echo   [--] Пропущено ^(больше не спрашиваю; можно поставить в потоке Ingest^)
goto skipcyr
:pullqwen
echo   [..] Устанавливаю qwen2.5:7b ^(~4.7 ГБ, разово^)...
ollama pull qwen2.5:7b
echo   [OK] qwen2.5:7b
:skipcyr

:: --- проверка .env ---
if exist ".env" (
  echo   [OK] .env найден ^(API ключи загружены^)
) else (
  echo   [--] .env не найден ^(Claude API недоступен — только локальная модель^)
)

echo.
echo   Открой браузер: http://localhost:3030
echo   Для остановки:  Ctrl+C
echo   Подробнее:      DEPLOYMENT.md
echo.

node server.js
