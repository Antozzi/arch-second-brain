# Архитектура решения — ARCH-ESS

## ARCH-001 GO Микросервисы
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Systems**: API GATEWAY, Registry Service, Exchange Service, Stock Service, Shop Integration, Audit Service
- **Protocol**: OAuth2, Rate limiting, Маршрутизация, Централизованное логирование
- **Source**: [[2026-04-30-go]]
- **Tags**: #architecture

---

## ARCH-001 Поступление
- **Type**: TO-BE
- **Systems**: 1C: Сервер приложений, 1C: Модуль интеграций, ESS: Receiving REST API
- **Protocol**: REST
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: ШОП -> Go Микросервис -> PostgreSQL -> 1С Торговля РЦС -> Консолидированные базы
- **Systems**: ШОП, Go Микросервис, PostgreSQL, 1С Торговля РЦС, Консолидированные базы
- **Source**: [[2026-04-30-scenarios]]
- **Tags**: #architecture

---

## ARCH-001 Registry Service Architecture
- **Type**: AS-IS
- **Description**: The registry service is configured with a PostgreSQL database, health checks, credentials management, logging, and metrics.
- **Systems**: PostgreSQL database, registry service
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE
- **Description**: Текущая система управления остатками на складе: PostgreSQL - stock_balance.
- **Systems**: PostgreSQL, stock_balance
- **Source**: [[2026-04-30-]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Система состоит из множественных экземпляров сервисных баз, включая МДМ и ФТТБ (единичные), базы Торговля (множественные) и базы Склад (множественные).
- **Systems**: МДМ, ФТТБ, Базы Торговля, Базы Склад
- **Source**: [[2026-04-30-stage3-scaling]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Текущая монолитная архитектура 1С, микросервисная архитектура.
- **Systems**: SHOP (Kafka), GO Микросервис, PG PostgreSQL Остатки, Trade 1С Торговля РЦС, ConsReg Консолидация региона
- **Source**: [[2026-04-30-view-diagrams]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Центральное ядро: Oracle Fusion ERP Cloud, Биллинговая система: Генератор финансового события
- **Systems**: Oracle Fusion ERP Cloud, Биллинговая система
- **Source**: [[2026-04-30-1]]
- **Tags**: #architecture

---

## ARCH-001 1C (AS-IS компоненты, TO-BE поведение)
- **Type**: AS-IS
- **Systems**: 1C Сервер приложений, 1C Модуль интеграций
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #architecture

## ARCH-002 Oracle Integration Cloud - INTW74 / INT_1C_004
- **Type**: Integration
- **Systems**: Orchestration Flows, Callback Dispatcher, Nightly Replay (Job)
- **Protocol**: REST/HTTPS
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #architecture

## ARCH-003 ESS - Oracle Fusion (Receiving)
- **Type**: Integration
- **Systems**: Receiving REST APIs, INTW81_JSON_LOG, Admin UI (Logs)
- **Protocol**: REST/HTTPS
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #architecture

---

## ARCH-001 Архитектура разделения сервисов
- **Type**: TO-BE
- **Description**: Разделить систему на отдельные сервисы для улучшения масштабируемости и гибкости
- **Systems**: МДМ, СКЛАД, ТОРГОВЛЯ, ФТТБ, GO WEB SERVICE, PostgreSQL
- **Source**: [[2026-04-30-stage2-service-separation]]
- **Tags**: #architecture

---

## ARCH-001 Shop Integration Service Architecture
- **Type**: AS-IS
- **Description**: Shop integration service connects with Kafka brokers, stock service, exchange service, and audit service.
- **Systems**: shop-integration-service, Kafka brokers, stock service, exchange service, audit service
- **Protocol**: #hypothesis
- **Source**: [[2026-04-30-shop-integration]]
- **Tags**: #architecture

---

## ARCH-001 Exchange Service Architecture
- **Type**: AS-IS
- **Description**: Exchange service connects to registry and audit services using HTTP client
- **Systems**: exchange-service, registry-service, audit-service
- **Protocol**: HTTP
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #architecture

---

## ARCH-001 Полная интеграция через GO микросервисы
- **Type**: Integration
- **Systems**: Торговля, Банк и Касса, ДБСС Финансы
- **Protocol**: GO API Gateway (OAuth2)
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS
- **Description**: 1C: Сервер, 1C: Модуль интеграций, ОИС: INTW74 Flows, ОИС: Callback Dispatcher, ESS: Receiving API
- **Systems**: 1C: Сервер, 1C: Модуль интеграций, ОИС: INTW74 Flows, ОИС: Callback Dispatcher, ESS: Receiving API
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #architecture

---

## ARCH-001 Stock Service Architecture
- **Type**: AS-IS
- **Description**: Stock service uses PostgreSQL database and audit service
- **Systems**: stock-service, postgres-main, audit-service
- **Source**: [[2026-04-30-stock-service]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Схема AS-IS: розничная продажа в ОПиО без временного резерва
- **Systems**: Кассовая система, Интернет-магазин
- **Source**: [[2026-04-30-discussion-topics]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Система "1С Склад" для складских операций, интеграция с ТСД (терминал сбора данных) для сканирования вместо печатания.
- **Source**: [[2026-04-30-business-guide]]
- **Tags**: #architecture

---

## ARCH-001 Архитектура интеграции 1С и ESS
- **Type**: AS-IS|TO-BE
- **Systems**: 1С, ESS
- **Source**: [[2026-04-30-md_int_1c_004_-_-_v2.3]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS
- **Description**: Монолитная архитектура: 2 базы УТ
- **Systems**: 1C Trade - Монолит, 1C FTTB - Монолит
- **Source**: [[2026-04-30-ut-architecture-evolution]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Система управления остатками на основе PostgreSQL, с автоматическим пересчетом резервов и свободного остатка
- **Systems**: PostgreSQL, Go микросервис
- **Source**: [[2026-04-30-stock-table-diagram]]
- **Tags**: #architecture

---

## ARCH-001 Архитектура обмена данными
- **Type**: AS-IS
- **Systems**: 1С База, Exchange Service, Registry Service
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Исходное поступление через ESB, корректировка в ESS
- **Systems**: 1С: Учет запасов, Интеграционный слой (ESB/REST-шлюз), ESS
- **Protocol**: JSON, POST /receivingReceipt
- **Source**: [[2026-04-30-full_correction_recording]]
- **Tags**: #architecture

---

## ARCH-001 Audit Service Architecture
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Configure audit service to log events, monitor performance, and ensure security
- **Systems**: Postgres database, audit service
- **Protocol**: REST
- **Source**: [[2026-04-30-audit-service]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE
- **Description**: Интеграция через GO Exchange Service
- **Systems**: База Торговля РЦС, База Склад ЦС, База МДМ
- **Protocol**: REST
- **Source**: [[2026-04-30-1-1]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Systems**: Внешние системы: ЕСС (Oracle), ШОП (интернет-магазин), ИС ЭСФ (Казахстан); Микросервисы Go; Операционные базы 1С; Консолидированные базы 1С
- **Source**: [[2026-04-30-summary]]
- **Tags**: #architecture

---

## ARCH-001 Финансовая архитектура
- **Type**: AS-IS
- **Description**: Текущее состояние финансовых баз: 1С Банк и Касса, 1С ДБСС Финансы
- **Systems**: 1С Банк и Касса, 1С ДБСС Финансы
- **Source**: [[2026-04-30-finance-bases]]
- **Tags**: #architecture

---

## ARCH-001 Структура таблицы stocks.stock_balance
- **Type**: AS-IS|TO-BE
- **Description**: Добавить поля для предв. резерва 1С и вычисляемого свободного остатка
- **Systems**: База данных PostgreSQL
- **Source**: [[2026-04-30-summary-v3]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Systems**: МДМ, Сервисные базы 1С, Новые финансовые базы, GO Микросервисы, Хранилища данных
- **Source**: [[2026-04-30-2]]
- **Tags**: #architecture

---

## ARCH-001 API Gateway Architecture
- **Type**: AS-IS
- **Description**: The API gateway is a single entry point for microservices communication.
- **Systems**: Microservices, Keycloak
- **Protocol**: HTTP/HTTPS
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #architecture

---

## ARCH-001 API Gateway
- **Type**: AS-IS
- **Description**: Единая точка входа для всех запросов
- **Systems**: API Gateway, Registry Service, Exchange Service, Stock Service, Shop Integration Service, Audit Service
- **Source**: [[2026-04-30-go-api-spec]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Схема БД для микросервиса остатков
- **Systems**: POSTGRESQL, 1С
- **Source**: [[2026-04-30-database-schema]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS
- **Description**: Взаимодействие складов с Go веб-сервисом через REST API
- **Systems**: Go веб-сервис, Склады 1С
- **Protocol**: HTTP/HTTPS
- **Source**: [[2026-04-30-simple-exchange-diagram]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS
- **Description**: Оператор 1С -> 1С: Учет запасов -> Интеграционный слой (ESB/REST-шлюз) -> ESS
- **Systems**: 1С: Учет запасов, Интеграционный слой (ESB/REST-шлюз), ESS
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #architecture

## ARCH-002 ?
- **Type**: TO-BE
- **Description**: Оператор 1С -> 1С: Учет запасов -> Интеграционный слой (ESB/REST-шлюз) -> ESS
- **Systems**: 1С: Учет запасов, Интеграционный слой (ESB/REST-шлюз), ESS
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Двухуровневая структура: Операционные и Консолидированные базы
- **Systems**: Операционные базы складов, региональные консолидации
- **Source**: [[2026-04-30-pyramid-diagram]]
- **Tags**: #architecture

---

## ARCH-001 Интеграция между 1С и ESS
- **Type**: AS-IS
- **Description**: Использует Oracle Integration Cloud, REST/JSON сервисы и двунаправленный обмен данными
- **Systems**: 1С:Trade, ESS
- **Protocol**: REST/JSON
- **Source**: [[2026-04-30-_-_1-_ess-1]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: Схема AS-IS: текущее состояние систем; Схема TO-BE: целевая архитектура с горизонтальным масштабированием и использованием множественных экземпляров сервисных баз
- **Systems**: МДМ, ФТТБ, Базы Торговля, Базы Склад, GO Web Service, PostgreSQL
- **Source**: [[2026-04-30-3]]
- **Tags**: #architecture

---

## ARCH-001 Миграция БД с версии 2.0 на версию 3.0
- **Type**: AS-IS
- **Systems**: stocks.stock_balance
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #architecture

---

## ARCH-001 Регистрация баз данных в GO Platform
- **Type**: AS-IS
- **Systems**: 1С:Предприятие, HTTP-сервис 1С, API Gateway
- **Protocol**: HTTPS
- **Source**: [[2026-04-30-database-registration-guide]]
- **Tags**: #architecture

---

## ARCH-001 Audit Service Database Schema
- **Type**: AS-IS
- **Systems**: PostgreSQL database for audit service.
- **Source**: [[2026-04-30-database-schema-audit]]
- **Tags**: #architecture

---

## ARCH-001 ?
- **Type**: AS-IS|TO-BE|Integration|Scenario
- **Description**: API Gateway, Registry, Exchange, Stock, Shop Integration, Audit
- **Systems**: PostgreSQL, Kafka + Zookeeper, Keycloak, Prometheus + Grafana
- **Protocol**: REST|SOAP|gRPC|MQ|...
- **Source**: [[2026-04-30-docker-compose]]
- **Tags**: #architecture

---

## ARCH-001 API Gateway
- **Type**: AS-IS
- **Systems**: GO микросервисы платформы
- **Source**: [[2026-04-30-readme]]
- **Tags**: #architecture

## ARCH-002 Registry Service
- **Type**: AS-IS
- **Systems**: GO микросервисы платформы
- **Source**: [[2026-04-30-readme]]
- **Tags**: #architecture

## ARCH-003 Exchange Service
- **Type**: AS-IS
- **Systems**: GO микросервисы платформы
- **Source**: [[2026-04-30-readme]]
- **Tags**: #architecture

## ARCH-004 Stock Service
- **Type**: AS-IS
- **Systems**: GO микросервисы платформы
- **Source**: [[2026-04-30-readme]]
- **Tags**: #architecture

## ARCH-005 Shop Integration Service
- **Type**: AS-IS
- **Systems**: GO микросервисы платформы
- **Source**: [[2026-04-30-readme]]
- **Tags**: #architecture

## ARCH-006 Audit Service
- **Type**: AS-IS
- **Systems**: GO микросервисы платформы
- **Source**: [[2026-04-30-readme]]
- **Tags**: #architecture
