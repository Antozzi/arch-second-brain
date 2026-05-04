# Архитектура решения — ARCH-PULSE-AI

## ARCH-001 Таблица [pred].[dbo].[Customer_Segment]
- **Type**: DataModel
- **Description**: Основная таблица для анализа KPI по сегментам клиентов.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

## ARCH-002 Таблица [pred].[dbo].[Customer_AI]
- **Type**: DataModel
- **Description**: Таблица для анализа показателей клиентской базы.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

## ARCH-003 Таблица [pred].[dbo].[Customer_Revenue]
- **Type**: DataModel
- **Description**: Таблица для анализа доходов по бизнес-вертикалям.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

## ARCH-004 Таблица [pred].[dbo].[Digital]
- **Type**: DataModel
- **Description**: Таблица для анализа цифровых продуктов и платформ.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

---

## ARCH-001 Компонент Orchestrator
- **Type**: TO-BE
- **Description**: Центральный компонент для управления и координации AI-сервисов.
- **Systems**: AI-сервисы, система мониторинга
- **Protocol**: REST
- **Source**: [[2026-05-04-ai_orchestration_architecture_presentation]]
- **Tags**: #architecture

## ARCH-002 Интеграция с системой мониторинга
- **Type**: Integration
- **Description**: Оркестратор должен интегрироваться с существующей системой мониторинга для сбора метрик производительности.
- **Systems**: Orchestrator, Система мониторинга
- **Protocol**: REST
- **Source**: [[2026-05-04-ai_orchestration_architecture_presentation]]
- **Tags**: #architecture #integration

---

## ARCH-001 TTS Service Architecture
- **Type**: Architecture
- **Description**: Архитектура сервиса TTS на базе ML
- **Systems**: Eleven Labs TTS, Langgraph, OpenAI GPTs, PostgreSQL, Object Storage, Frontend, Email server, KeyCloak
- **Protocol**: HTTP Stream, HTTPS Stream
- **Source**: [[2026-05-04-image2025-11-12_17-16-0]]
- **Tags**: #architecture

---

## ARCH-001 Интеграция ESS с 1С
- **Type**: Integration
- **Description**: REST API
- **Systems**: ESS, 1С
- **Protocol**: REST
- **Source**: [[2026-05-04-obase-air-veon-pulse-ai-architecture-review]]
- **Tags**: #architecture

---

## ARCH-001 [pred].[dbo].[Customer_Segment]
- **Type**: DataModel
- **Description**: Основная таблица для анализа KPI по различным сегментам клиентов.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

## ARCH-002 [pred].[dbo].[Customer_AI]
- **Type**: DataModel
- **Description**: Таблица для анализа показателей клиентской базы и использования услуг.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

## ARCH-003 [pred].[dbo].[Customer_Revenue]
- **Type**: DataModel
- **Description**: Таблица для анализа доходов, разбитых по бизнес-вертикалям.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

## ARCH-004 [pred].[dbo].[Digital]
- **Type**: DataModel
- **Description**: Таблица для анализа цифровых продуктов, платформ и вертикалей.
- **Systems**: Data Warehouse
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #architecture #datamodel

---

## ARCH-001 Платформа оркестрации AI
- **Type**: TO-BE
- **Description**: Централизованная платформа для управления и координации AI-сервисов.
- **Systems**: AI-сервисы, Платформа оркестрации
- **Protocol**: REST
- **Source**: [[2026-05-04-ai_orchestration_architecture_presentation]]
- **Tags**: #architecture

---

## ARCH-001 TTS Service Architecture
- **Type**: TO-BE
- **Description**: Архитектура сервиса TTS на базе ML
- **Systems**: Eleven Labs TTS, Langgraph, OpenAI GPTs, PostgreSQL, Object Storage, Frontend, Email server, KeyCloak
- **Protocol**: HTTP Stream, HTTPS Stream
- **Source**: [[2026-05-04-image2025-11-12_17-16-0]]
- **Tags**: #architecture

---

## ARCH-001 REST API для интеграции с 1С
- **Type**: Integration
- **Description**: Описание REST API для получения данных о поступлении товаров из 1С.
- **Systems**: ESS, 1С
- **Protocol**: REST
- **Source**: [[2026-05-04-questions-to-the-veon-vendor-team-1]]
- **Tags**: #architecture

---

## ARCH-001 Аутентификация мобильного приложения через Api Gateway
- **Type**: Integration
- **Description**: Мобильное приложение отправляет cookie в Api Gateway, который валидирует пользователя через MicroStrategy REST API и отправляет запрос в AI API.
- **Systems**: Mobile Application, MicroStrategy Library, Api Gateway, MicroStrategy REST API, AI API
- **Protocol**: REST
- **Source**: [[2026-05-04-mobile-login]]
- **Tags**: #architecture #integration
