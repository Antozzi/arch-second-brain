# Требования — ARCH-PULSE-AI

## BR-001 Использование таблицы [pred].[dbo].[Customer_Segment] для анализа KPI по сегментам
- **Type**: Functional
- **Description**: При запросе KPI, связанных с сегментами, необходимо использовать таблицу [pred].[dbo].[Customer_Segment].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

## BR-002 Использование таблицы [pred].[dbo].[Customer_AI] для анализа показателей клиентской базы
- **Type**: Functional
- **Description**: При запросе показателей клиентской базы (активные пользователи, отток, ARPU) необходимо использовать таблицу [pred].[dbo].[Customer_AI].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

## BR-003 Использование таблицы [pred].[dbo].[Customer_Revenue] для анализа доходов
- **Type**: Functional
- **Description**: При запросе данных о доходах, разбитых по бизнес-вертикалям, необходимо использовать таблицу [pred].[dbo].[Customer_Revenue].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

## BR-004 Использование таблицы [pred].[dbo].[Digital] для анализа цифровых продуктов и платформ
- **Type**: Functional
- **Description**: При запросе данных о цифровых продуктах и платформах необходимо использовать таблицу [pred].[dbo].[Digital].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

---

## BR-001 Централизованное управление AI-сервисами
- **Type**: Functional
- **Description**: Система должна предоставлять единую точку управления для всех AI-сервисов.
- **Priority**: Must
- **Source**: [[2026-05-04-ai_orchestration_architecture_presentation]]
- **Tags**: #requirement #functional

## BR-002 Мониторинг производительности AI-сервисов
- **Type**: NFR
- **Description**: Система должна обеспечивать мониторинг производительности AI-сервисов в режиме реального времени.
- **Priority**: Should
- **Source**: [[2026-05-04-ai_orchestration_architecture_presentation]]
- **Tags**: #requirement #nfr

---

## BR-001 TTS Service
- **Type**: Functional
- **Description**: Сервис должен предоставлять функциональность TTS на базе ML
- **Priority**: Must
- **Source**: [[2026-05-04-image2025-11-12_17-16-0]]
- **Tags**: #requirement #functional

---

## BR-001 Интеграция ESS с 1С
- **Type**: Functional
- **Description**: ESS получает данные о поступлении товаров из 1С через REST API.
- **Priority**: Must
- **Source**: [[2026-05-04-obase-air-veon-pulse-ai-architecture-review]]
- **Tags**: #requirement

---

## BR-001 Использование таблицы [pred].[dbo].[Customer_Segment] для анализа KPI по сегментам
- **Type**: Functional
- **Description**: При запросе KPI, связанных с сегментами клиентов, необходимо использовать таблицу [pred].[dbo].[Customer_Segment].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

## BR-002 Использование таблицы [pred].[dbo].[Customer_AI] для анализа показателей клиентской базы
- **Type**: Functional
- **Description**: При запросе показателей клиентской базы, таких как количество активных подписчиков, отток и использование услуг, необходимо использовать таблицу [pred].[dbo].[Customer_AI].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

## BR-003 Использование таблицы [pred].[dbo].[Customer_Revenue] для анализа доходов
- **Type**: Functional
- **Description**: При запросе информации о доходах, разбитых по бизнес-вертикалям, необходимо использовать таблицу [pred].[dbo].[Customer_Revenue].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

## BR-004 Использование таблицы [pred].[dbo].[Digital] для анализа цифровых продуктов и платформ
- **Type**: Functional
- **Description**: При запросе информации о цифровых продуктах, платформах и вертикалях необходимо использовать таблицу [pred].[dbo].[Digital].
- **Priority**: Must
- **Source**: [[2026-05-04-view-descriptions]]
- **Tags**: #requirement #functional

---

## BR-001 Централизованное управление AI-сервисами
- **Type**: Functional
- **Description**: Платформа должна предоставлять единую точку управления для всех AI-сервисов.
- **Priority**: Must
- **Source**: [[2026-05-04-ai_orchestration_architecture_presentation]]
- **Tags**: #requirement #functional

## BR-002 Мониторинг производительности AI-сервисов
- **Type**: NFR
- **Description**: Платформа должна обеспечивать мониторинг производительности AI-сервисов в реальном времени.
- **Priority**: Should
- **Source**: [[2026-05-04-ai_orchestration_architecture_presentation]]
- **Tags**: #requirement #nfr

---

## BR-001 TTS Service
- **Type**: Functional
- **Description**: Сервис должен предоставлять функциональность TTS на базе ML
- **Priority**: Must
- **Source**: [[2026-05-04-image2025-11-12_17-16-0]]
- **Tags**: #requirement #functional

---

## BR-001 Интеграция ESS с 1С
- **Type**: Functional
- **Description**: ESS должна получать данные о поступлении товаров из 1С через REST API.
- **Priority**: Must
- **Source**: [[2026-05-04-questions-to-the-veon-vendor-team-1]]
- **Tags**: #requirement

---

## BR-001 Аутентификация мобильного приложения
- **Type**: Functional
- **Description**: Мобильное приложение использует аутентификацию через cookie из MicroStrategy Library.
- **Priority**: Must
- **Source**: [[2026-05-04-mobile-login]]
- **Tags**: #requirement #functional
