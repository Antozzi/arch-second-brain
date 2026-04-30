# Требования — ARCH-ESS

## BR-001 Создание и отправка документа "Поступление"
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-002 Передача данных документа на интеграцию
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-003 Запись статуса в интеграционный журнал
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-004 Установка блокировки исходного документа
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-005 Отправка документа через ESS
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-006 Обработка ответа ESS
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-007 Обновление статуса в интеграционном журнале
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-008 Отправка уведомления об ошибке
- **Type**: Functional
- **Priority**: Should
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

## BR-009 Повторная отправка документа через ESS
- **Type**: Functional
- **Priority**: Should
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Клиент оформляет заказ на сайте (ШОП). Заказ через Kafka поступает в Go микросервис, который проверяет остатки в PostgreSQL, резервирует товар и создает документ в соответствующей базе 1С Торговля.
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-scenarios]]
- **Tags**: #requirement

---

## BR-001 Database Setup
- **Type**: Functional
- **Description**: Set up a PostgreSQL database with the specified host, port, name, user, and password.
- **Priority**: Must
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #requirement

## BR-002 Health Checks
- **Type**: Functional
- **Description**: Configure health checks for the database with a specified interval, timeout, and concurrent checks.
- **Priority**: Must
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #requirement

## BR-003 Credentials Management
- **Type**: Functional
- **Description**: Implement credentials management with bcrypt algorithm, cost factor, and rotation policy.
- **Priority**: Must
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #requirement

## BR-004 Logging
- **Type**: Functional
- **Description**: Configure logging with a specified level, format, and output.
- **Priority**: Must
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #requirement

## BR-005 Metrics
- **Type**: Functional
- **Description**: Enable metrics with a specified port.
- **Priority**: Must
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Система должна обеспечивать горизонтальное масштабирование с помощью множественных экземпляров сервисных баз.
- **Priority**: Must
- **Source**: [[2026-04-30-stage3-scaling]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Система должна обеспечивать проверку остатков на складе, резервирование товаров и создание документов в 1С.
- **Priority**: Must
- **Source**: [[2026-04-30-view-diagrams]]
- **Tags**: #requirement

## BR-002 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Система должна обеспечивать перемещение товаров между складами.
- **Priority**: Should
- **Source**: [[2026-04-30-view-diagrams]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Единообразие данных, Автоматизация процессов
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-1]]
- **Tags**: #requirement

---

## BR-001 Создание/проведение Поступления
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #requirement

## BR-002 Передача на интеграцию
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #requirement

## BR-003 Фиксация статусов (NEW→SENT→...)
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #requirement

## BR-004 Установить ПЕРМАНЕНТНУЮ блокировку исходного документа после отправки
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #requirement

## BR-005 Изменения - только новым корректирующим документом
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #requirement

---

## BR-001 Разделение сервисов
- **Type**: Functional
- **Description**: Разделить систему на отдельные сервисы для улучшения масштабируемости и гибкости
- **Priority**: Must
- **Source**: [[2026-04-30-stage2-service-separation]]
- **Tags**: #requirement

---

## BR-001 Shop Integration Service Configuration
- **Type**: Functional
- **Description**: Configure shop integration service to connect with Kafka brokers, stock service, exchange service, and audit service.
- **Priority**: Must
- **Source**: [[2026-04-30-shop-integration]]
- **Tags**: #requirement

## BR-002 Kafka Configuration
- **Type**: NFR
- **Description**: Configure Kafka brokers for shop integration service to consume and produce messages.
- **Priority**: Must
- **Source**: [[2026-04-30-shop-integration]]
- **Tags**: #requirement

## BR-003 Order Processing Configuration
- **Type**: Functional
- **Description**: Configure order processing for shop integration service to validate orders, select warehouses, and update status.
- **Priority**: Must
- **Source**: [[2026-04-30-shop-integration]]
- **Tags**: #requirement

---

## BR-001 Database Connection Settings
- **Type**: Functional
- **Description**: Establish connection to PostgreSQL database for caching idempotency keys
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #requirement

## BR-002 HTTP Client Settings
- **Type**: Functional
- **Description**: Configure HTTP client for sending requests to registry and audit services
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #requirement

## BR-003 Idempotency Cache Settings
- **Type**: Functional
- **Description**: Configure idempotency cache using PostgreSQL database
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #requirement

## BR-004 Circuit Breaker Settings
- **Type**: Functional
- **Description**: Configure circuit breaker for database connections
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #requirement

## BR-005 Logging Settings
- **Type**: Functional
- **Description**: Configure logging for exchange service
- **Priority**: Should
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #requirement

## BR-006 Metrics Settings
- **Type**: Functional
- **Description**: Configure metrics collection for exchange service
- **Priority**: Should
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #requirement

---

## BR-001 Эквайринг (транзакции с POS-терминалов)
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

## BR-002 Платежные поручения из банка
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

## BR-003 Кассовые операции из торговых точек
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

## BR-004 Автоматическая сверка эквайринга с продажами
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

## BR-005 Получение данных о начислениях из ДБСС
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

## BR-006 Формирование финансовых проводок по биллингу
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

## BR-007 Консолидация выручки от услуг связи
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

## BR-008 Подготовка данных для бухгалтерии
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional
- **Description**: Отправка "Поступления" от 1C: Сервер к 1C: Модуль интеграций
- **Priority**: Must
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #requirement

## BR-002 ?
- **Type**: Functional
- **Description**: POST JSON от 1C: Модуль интеграций к ОИС: INTW74 Flows
- **Priority**: Must
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #requirement

## BR-003 ?
- **Type**: Functional
- **Description**: Создать Receiving от ОИС: INTW74 Flows к ESS: Receiving API
- **Priority**: Must
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #requirement

## BR-004 ?
- **Type**: Functional
- **Description**: Callback #1 = ACK_OK от ОИС: Callback Dispatcher к 1C: Модуль интеграций
- **Priority**: Must
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #requirement

## BR-005 ?
- **Type**: Functional
- **Description**: Callback #2 = PRICE_PROVISIONAL (цены по строкам) от ОИС: Callback Dispatcher к 1C: Модуль интеграций
- **Priority**: Must
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #requirement

## BR-006 ?
- **Type**: Functional
- **Description**: Callback #3 = PRICE_READY (финальные цены) от ОИС: Callback Dispatcher к 1C: Модуль интеграций
- **Priority**: Must
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #requirement

---

## BR-001 Database Connection
- **Type**: Functional
- **Description**: Connect to PostgreSQL database
- **Priority**: Must
- **Source**: [[2026-04-30-stock-service]]
- **Tags**: #requirement

## BR-002 Locking Strategy
- **Type**: Functional
- **Description**: Implement pessimistic locking strategy
- **Priority**: Must
- **Source**: [[2026-04-30-stock-service]]
- **Tags**: #requirement

## BR-003 Validation
- **Type**: Functional
- **Description**: Enable validation for stock data
- **Priority**: Must
- **Source**: [[2026-04-30-stock-service]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: При сканировании товара создается временный резерв на 5 минут
- **Priority**: Must
- **Source**: [[2026-04-30-discussion-topics]]
- **Tags**: #requirement

## BR-002 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Разделение остатков по каналам продаж
- **Priority**: Should
- **Source**: [[2026-04-30-discussion-topics]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Автоматическая проверка остатков в центральной БД, сканирование ячеек и товаров для точного учета.
- **Priority**: Must
- **Source**: [[2026-04-30-business-guide]]
- **Tags**: #requirement

---

## BR-001 Функциональный дизайн интеграции 1С и ESS
- **Type**: Functional
- **Description**: Необходимо разработать функциональный дизайн интеграции 1С с ESS для передачи факта поступления
- **Priority**: Must
- **Source**: [[2026-04-30-md_int_1c_004_-_-_v2.3]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Система должна обеспечивать точную информацию о остатках, поддерживать резервы и свободный остаток
- **Priority**: Must
- **Source**: [[2026-04-30-stock-table-diagram]]
- **Tags**: #requirement

---

## BR-001 Асинхронность обмена данными
- **Type**: Functional
- **Description**: Отправитель не ждет обработки, только доставки
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #requirement

## BR-002 Надежность обмена данными
- **Type**: Functional
- **Description**: Retry механизм + очередь отправки в 1С
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #requirement

## BR-003 Гибкость обмена данными
- **Type**: Functional
- **Description**: Свободная структура данных (GO не валидирует)
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #requirement

## BR-004 Маршрутизация обмена данными
- **Type**: Functional
- **Description**: Отправка по ID, тегам или всем базам
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #requirement

## BR-005 Аудит обмена данными
- **Type**: Functional
- **Description**: Полное логирование всех обменов
- **Priority**: Must
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional
- **Description**: Прием в ESS факта поступления из 1С
- **Priority**: Must
- **Source**: [[2026-04-30-veon_ess_intw74_-ess-1-_v.2.1]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Создание и проведение ПТУ, интеграция с ESS
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-full_correction_recording]]
- **Tags**: #requirement

## BR-002 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Корректировка поступления, создание отрицательных корректировок
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-full_correction_recording]]
- **Tags**: #requirement

---

## BR-001 Audit Service Configuration Requirements
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Configure audit service to log events, monitor performance, and ensure security
- **Priority**: Must
- **Source**: [[2026-04-30-audit-service]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional
- **Description**: Создать заказ на перемещение товара с Центрального склада
- **Priority**: Must
- **Source**: [[2026-04-30-1-1]]
- **Tags**: #requirement

## BR-002 ?
- **Type**: Functional
- **Description**: Массовая рассылка справочника из МДМ
- **Priority**: Must
- **Source**: [[2026-04-30-1-1]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-summary]]
- **Tags**: #requirement

---

## BR-001 Обработка денежных операций
- **Type**: Functional
- **Description**: Получение транзакций с POS-терминалов, загрузка банковских выписок, обработка входящих и исходящих платежей
- **Priority**: Must
- **Source**: [[2026-04-30-finance-bases]]
- **Tags**: #requirement

## BR-002 Автоматизация сверок
- **Type**: Functional
- **Description**: Сверка эквайринга с продажами, сверка инкассаций с кассовыми отчетами
- **Priority**: Should
- **Source**: [[2026-04-30-finance-bases]]
- **Tags**: #requirement

---

## BR-001 Предварительный резерв 1С
- **Type**: Functional
- **Description**: Вычислять предварительный резерв 1С на основе общего остатка и предв. резерва ШОП
- **Priority**: Must
- **Source**: [[2026-04-30-summary-v3]]
- **Tags**: #requirement

## BR-002 Новые типы операций
- **Type**: Functional
- **Description**: Создавать, отменять и переносить предв. резерв 1С
- **Priority**: Must
- **Source**: [[2026-04-30-summary-v3]]
- **Tags**: #requirement

---

## BR-001 OAuth2 / Keycloak Configuration
- **Type**: Functional
- **Description**: Configure OAuth2 with Keycloak for authentication and authorization.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

## BR-002 Rate Limiting Configuration
- **Type**: Functional
- **Description**: Configure rate limiting for API requests.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

## BR-003 Routing Configuration
- **Type**: Functional
- **Description**: Configure routing to microservices.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

## BR-004 Logging Configuration
- **Type**: Functional
- **Description**: Configure logging for API requests.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

## BR-005 CORS Configuration
- **Type**: Functional
- **Description**: Configure CORS for API requests.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

## BR-006 Health Check Configuration
- **Type**: Functional
- **Description**: Configure health check for API gateway.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

## BR-007 Metrics Configuration
- **Type**: Functional
- **Description**: Configure metrics for API requests.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

## BR-008 Circuit Breaker Configuration
- **Type**: Functional
- **Description**: Configure circuit breaker for API requests.
- **Priority**: Must
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #requirement

---

## BR-001 API Gateway
- **Type**: Functional
- **Description**: Единая точка входа для всех запросов
- **Priority**: Must
- **Source**: [[2026-04-30-go-api-spec]]
- **Tags**: #requirement

## BR-002 Registry Service
- **Type**: Functional
- **Description**: Управление регистрацией 1С баз
- **Priority**: Must
- **Source**: [[2026-04-30-go-api-spec]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Хранить информацию о складах и номенклатуре
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-database-schema]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional
- **Description**: Веб-сервис отправляет документы (заказы на перемещение, команды)
- **Priority**: Must
- **Source**: [[2026-04-30-simple-exchange-diagram]]
- **Tags**: #requirement

## BR-002 ?
- **Type**: Functional
- **Description**: Склады отправляют остатки и движения товаров
- **Priority**: Must
- **Source**: [[2026-04-30-simple-exchange-diagram]]
- **Tags**: #requirement

## BR-003 ?
- **Type**: NFR
- **Description**: Протокол: HTTP/HTTPS, формат JSON
- **Priority**: Must
- **Source**: [[2026-04-30-simple-exchange-diagram]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional
- **Description**: Создание и проведение ПТУ (10 строк)
- **Priority**: Must
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #requirement

## BR-002 ?
- **Type**: Functional
- **Description**: JSON Поступление (10 строк)
- **Priority**: Must
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #requirement

## BR-003 ?
- **Type**: Functional
- **Description**: POST /receivingReceipt (строки без транзакций)
- **Priority**: Must
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #requirement

## BR-004 ?
- **Type**: Functional
- **Description**: Повторная отправка JSON (только непринятые строки)
- **Priority**: Must
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #requirement

---

## BR-001 Автоматическая передача первичных документов между 1С и ESS
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-_-_1-_ess-1]]
- **Tags**: #requirement

## BR-002 Синхронизация справочников между 1С и ESS
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-_-_1-_ess-1]]
- **Tags**: #requirement

## BR-003 Передача себестоимости и остатков для формирования финансового результата
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-_-_1-_ess-1]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: Функциональные требования: масштабирование системы, горизонтальное масштабирование с использованием множественных экземпляров сервисных баз; НФР: производительность, доступность, безопасность
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-3]]
- **Tags**: #requirement

---

## BR-001 Добавление колонки предварительного резерва 1С
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #requirement

## BR-002 Переименование колонки reserve_shop на prereserve_shop
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #requirement

## BR-003 Добавление комментария к колонке prereserve_shop
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #requirement

## BR-004 Удаление старого вычисляемого поля free_quantity
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #requirement

## BR-005 Добавление нового вычисляемого поля free_quantity
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #requirement

## BR-006 Обновление представления v_stock_balance
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #requirement

## BR-007 Обновление комментария к таблице stock_balance
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #requirement

---

## BR-001 Регистрация баз данных в GO Platform
- **Type**: Functional
- **Description**: Предоставить уникальный UUID и OAuth2 credentials для безопасного взаимодействия с микросервисами.
- **Priority**: Must
- **Source**: [[2026-04-30-database-registration-guide]]
- **Tags**: #requirement

## BR-002 Предварительные требования
- **Type**: Functional
- **Description**: 1С:Предприятие 8.3.20 или выше, HTTP-сервис 1С (публикация через Apache/IIS), Доступ к API Gateway по HTTPS.
- **Priority**: Must
- **Source**: [[2026-04-30-database-registration-guide]]
- **Tags**: #requirement

---

## BR-001 Partitioning by date for efficient storage.
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-database-schema-audit]]
- **Tags**: #requirement

## BR-002 Automatic cleanup of old logs (retention policy).
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-database-schema-audit]]
- **Tags**: #requirement

## BR-003 Indexes for fast search by various criteria.
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-database-schema-audit]]
- **Tags**: #requirement

## BR-004 JSONB for storing request/response body.
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-database-schema-audit]]
- **Tags**: #requirement

---

## BR-001 ?
- **Type**: Functional|NFR|Security|Constraint|Assumption
- **Description**: API Gateway, Registry, Exchange, Stock, Shop Integration, Audit
- **Priority**: Must|Should|Could
- **Source**: [[2026-04-30-docker-compose]]
- **Tags**: #requirement

---

## BR-001 OAuth2 аутентификация через Keycloak
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-readme]]
- **Tags**: #requirement

## BR-002 Rate limiting (1000 запросов/минуту)
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-readme]]
- **Tags**: #requirement

## BR-003 Маршрутизация к микросервисам
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-readme]]
- **Tags**: #requirement

## BR-004 CORS настройки
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-readme]]
- **Tags**: #requirement

## BR-005 Circuit Breaker
- **Type**: Functional
- **Priority**: Must
- **Source**: [[2026-04-30-readme]]
- **Tags**: #requirement
