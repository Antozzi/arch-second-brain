# Бизнес-контекст — ARCH-ESS

## BC-001 GO Микросервисы
- **Scope_in**: Архитектура компонентов интеграционной платформы
- **Source**: [[2026-04-30-go]]
- **Tags**: #business-context

---

## BC-001 GO Микросервисы
- **Scope_in**: Архитектура компонентов интеграционной платформы
- **Source**: [[2026-04-30-go]]
- **Tags**: #business-context

---

## BC-001 Поступление
- **Goals**: Создание и отправка документа "Поступление"
- **Scope_in**: 1C: Сервер приложений, 1C: Модуль интеграций, 1C: Интеграционный журнал/статусы
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Клиент оформляет заказ на сайте (ШОП). Заказ через Kafka поступает в Go микросервис, который проверяет остатки в PostgreSQL, резервирует товар и создает документ в соответствующей базе 1С Торговля.
- **Scope_in**: Клиент
- **Scope_out**: ШОП, Go Микросервис, PostgreSQL, 1С Торговля РЦС, Консолидированные базы
- **Source**: [[2026-04-30-scenarios]]
- **Tags**: #business-context

---

## BC-001 Registry Service Configuration
- **Problem**: #hypothesis
- **Goals**: Provide a centralized registry service for managing data.
- **Scope_in**: Registry service configuration, database setup, health checks, credentials management, logging, and metrics.
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Требуется система управления остатками на складе.
- **Goals**: Управлять остатками на складе, обеспечивать точную информацию о наличии товаров.
- **Scope_in**: Система должна учитывать все типы товаров и их остатки на складе.
- **Source**: [[2026-04-30-]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Масштабирование системы для увеличения производительности и масштабируемости.
- **Goals**: Увеличить скорость обработки данных, повысить доступность системы и обеспечить гибкость в масштабировании.
- **Scope_in**: Включает горизонтальное масштабирование с помощью множественных экземпляров сервисных баз.
- **Source**: [[2026-04-30-stage3-scaling]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Миграция монолитной 1С к микросервисной архитектуре
- **Goals**: Улучшение масштабируемости и гибкости системы
- **Scope_in**: Переход от монолитной архитектуры к микросервисной
- **Source**: [[2026-04-30-view-diagrams]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Сложность интеграции унаследованных (legacy) и новых облачных ERP-систем
- **Goals**: Единообразие данных, Автоматизация процессов
- **Scope_in**: Целевая ИТ-архитектура
- **Source**: [[2026-04-30-1]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Создание/проведение Поступления
- **Goals**: Оформление Поступления в 1С
- **Scope_in**: 1C Сервер приложений, 1C Модуль интеграций
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #business-context

---

## BC-001 Этап 2: разделение сервисов
- **Problem**: Недостаточная гибкость и масштабируемость монолитной системы
- **Goals**: Разделить систему на отдельные сервисы для улучшения масштабируемости и гибкости
- **Scope_in**: Монолитная система
- **Scope_out**: Отдельные сервисы
- **Source**: [[2026-04-30-stage2-service-separation]]
- **Tags**: #business-context

---

## BC-001 SHOP INTEGRATION SERVICE CONFIGURATION
- **Problem**: #hypothesis
- **Goals**: Integrate SHOP with other services for order processing and status updates.
- **Scope_in**: shop-integration-service, Kafka brokers, stock service, exchange service, audit service
- **Scope_out**: #hypothesis
- **Source**: [[2026-04-30-shop-integration]]
- **Tags**: #business-context

---

## BC-001 Exchange Service Configuration
- **Problem**: Configure exchange service for production environment
- **Goals**: Ensure reliable and secure data exchange between services
- **Scope_in**: exchange-service, registry-service, audit-service
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #business-context

---

## BC-001 Добавление финансовых баз
- **Problem**: Финансовые операции "размазаны" по торговым базам
- **Goals**: Централизованная обработка всех денежных операций
- **Scope_in**: Торговля, Банк и Касса, ДБСС Финансы
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Нет данных о проблеме
- **Goals**: Нет данных о целях
- **Scope_in**: 1C: Сервер, 1C: Модуль интеграций
- **Scope_out**: ОИС: INTW74 Flows, ОИС: Callback Dispatcher, ESS: Receiving API
- **Source**: [[2026-04-30-price_issue]]
- **Tags**: #business-context

---

## BC-001 Stock Service Configuration
- **Problem**: Manage stock data and operations
- **Goals**: Provide a reliable and efficient stock service
- **Scope_in**: stock-service, production environment
- **Source**: [[2026-04-30-stock-service]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Кассир оформил чек, клиент оплатил, но при проведении реализации получает ошибку "товара нет в наличии"
- **Goals**: Гарантирует доступность товара во время оформления
- **Scope_in**: Розничная продажа в ОПиО
- **Source**: [[2026-04-30-discussion-topics]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Работа в большой базе "1С Управление торговлей" (все вместе) - медленная работа при пиковых нагрузках, конфликты блокировок при работе с серийными товарами.
- **Goals**: Быстрая работа без конфликтов, точная инвентаризация
- **Source**: [[2026-04-30-business-guide]]
- **Tags**: #business-context

---

## BC-001 Интеграция 1С и ESS
- **Problem**: Необходима интеграция 1С с ESS для передачи факта поступления
- **Goals**: Улучшение автоматизации процессов
- **Scope_in**: ESS в ТОО "Кар-Тел"
- **Source**: [[2026-04-30-md_int_1c_004_-_-_v2.3]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Монолитная архитектура: все процессы в одной базе - сложность поддержки и масштабирования
- **Scope_in**: Текущее состояние (AS-IS)
- **Source**: [[2026-04-30-ut-architecture-evolution]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Нужно управлять остатками на складе
- **Goals**: Оптимизировать запасы, обеспечить доступность товаров для продажи
- **Scope_in**: Склад, товары, клиенты
- **Scope_out**: Другие части бизнеса
- **Source**: [[2026-04-30-stock-table-diagram]]
- **Tags**: #business-context

---

## BC-001 Обмен данными между 1С базами
- **Problem**: Необходимость обмена данными между разными базами 1С
- **Goals**: Упростить процесс обмена данными, повысить надежность и гибкость
- **Scope_in**: Включает в себя обмен данными между различными базами 1С
- **Scope_out**: Не включает прямое взаимодействие между базами
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Прием в ESS факта поступления из 1С
- **Source**: [[2026-04-30-veon_ess_intw74_-ess-1-_v.2.1]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Полная отмена поступления через Акт / Возврат и CORRECT
- **Goals**: Полнота отмены, корректность данных
- **Scope_in**: Исходное поступление, корректировка
- **Scope_out**: Новое поступление с корректными данными
- **Source**: [[2026-04-30-full_correction_recording]]
- **Tags**: #business-context

---

## BC-001 Audit Service Configuration
- **Problem**: Need to configure audit service for logging and monitoring
- **Goals**: Configure audit service to log events, monitor performance, and ensure security
- **Scope_in**: All system components and services
- **Scope_out**: None
- **Source**: [[2026-04-30-audit-service]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Обмен данными между 1С базами
- **Goals**: Устранить проблемы с обменом данными
- **Scope_in**: База Торговля РЦС, База Склад ЦС
- **Scope_out**: База МДМ
- **Source**: [[2026-04-30-1-1]]
- **Tags**: #business-context

---

## BC-001 Миграция монолитной 1С к микросервисной архитектуре
- **Problem**: Одна большая база 1С для всех → конфликты блокировок, медленная работа, невозможность масштабирования
- **Goals**: Нет лимита на количество пользователей, экономия на лицензиях 1С, быстрая работа (ускорение в 3-10 раз)
- **Source**: [[2026-04-30-summary]]
- **Tags**: #business-context

---

## BC-001 Финансовые базы 1С
- **Problem**: Централизация и разделение финансовых операций
- **Goals**: Разделение ответственности, централизация, автоматизация сверок, независимость, масштабируемость
- **Scope_in**: Торговые базы, 1С Банк и Касса, 1С ДБСС Финансы
- **Source**: [[2026-04-30-finance-bases]]
- **Tags**: #business-context

---

## BC-001 Предварительный резерв 1С
- **Problem**: Необходимость унифицировать резервирование в системе
- **Goals**: Упростить процесс резервирования, обеспечить точную вычисляемость свободного остатка
- **Scope_in**: Резервирование в системе 1С
- **Source**: [[2026-04-30-summary-v3]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: От монолита к сервисным базам + финансовые системы
- **Goals**: # Концепция разделения (TO-BE)
- **Scope_in**: МДМ - Мастер-данные, Сервисные базы 1С, Новые финансовые базы, GO Микросервисы, Хранилища данных
- **Source**: [[2026-04-30-2]]
- **Tags**: #business-context

---

## BC-001 API Gateway Service
- **Problem**: Provide a secure and scalable API gateway for microservices communication.
- **Goals**: Ensure high availability, security, and performance of the API gateway.
- **Scope_in**: Microservices communication, security, scalability
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #business-context

---

## BC-001 GO Микросервисы - OpenAPI 3.0 Спецификация
- **Problem**: Внедрение микросервисной архитектуры для решения бизнес-задач
- **Goals**: Улучшение масштабируемости, производительности и безопасности системы
- **Scope_in**: API Gateway, Registry Service, Exchange Service, Stock Service, Shop Integration Service, Audit Service
- **Source**: [[2026-04-30-go-api-spec]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Схема БД для микросервиса остатков
- **Goals**: Хранить информацию о складах и номенклатуре
- **Scope_in**: Микросервис остатков, 1С
- **Source**: [[2026-04-30-database-schema]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Взаимодействие складов с Go веб-сервисом
- **Goals**: Обмен данными между складами и Go веб-сервисом
- **Scope_in**: Схема обмена данными между складами и Go веб-сервисом
- **Source**: [[2026-04-30-simple-exchange-diagram]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: ПТУ с частичной ошибкой и повторной отправкой недостающих строк
- **Goals**: #hypothesis
- **Scope_in**: Оператор 1С, 1С: Учет запасов, Интеграционный слой (ESB/REST-шлюз), ESS
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Необходимость оптимизации баз данных для операционных и консолидированных систем
- **Goals**: Улучшение производительности, сокращение затрат на поддержку и эксплуатацию
- **Scope_in**: Операционные базы складов, региональные консолидации
- **Source**: [[2026-04-30-pyramid-diagram]]
- **Tags**: #business-context

---

## BC-001 Интеграция между 1С и ESS
- **Problem**: Несинхронизация данных между двумя системами
- **Goals**: Обеспечить сквозной обмен данными, синхронизацию справочников и целостность данных
- **Scope_in**: Операционный контур (1С) и финансово-бухгалтерский контур (ESS)
- **Source**: [[2026-04-30-_-_1-_ess-1]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Масштабирование системы для увеличения производительности
- **Goals**: Повысить скорость обработки данных, обеспечить доступность и масштабируемость
- **Scope_in**: Включает горизонтальное масштабирование с использованием множественных экземпляров сервисных баз
- **Source**: [[2026-04-30-3]]
- **Tags**: #business-context

---

## BC-001 Миграция БД с версии 2.0 на версию 3.0
- **Scope_in**: Добавление предварительного резерва 1С
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #business-context

---

## BC-001 Регистрация баз данных в GO Platform
- **Problem**: Необходимо регистрировать базы данных 1С в интеграционной платформе GO.
- **Goals**: Предоставить уникальный UUID и OAuth2 credentials для безопасного взаимодействия с микросервисами.
- **Scope_in**: Регистрация баз данных 1С в GO Platform
- **Source**: [[2026-04-30-database-registration-guide]]
- **Tags**: #business-context

---

## BC-001 Audit Service Database Schema
- **Problem**: Need to log all integration events between 1C bases and microservices GO Platform.
- **Goals**: Efficient storage, automatic cleanup of old logs, fast search by various criteria.
- **Scope_in**: Integration events, 1C bases, microservices GO Platform.
- **Source**: [[2026-04-30-database-schema-audit]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: GO микросервисная платформа для интеграции с ШОП
- **Goals**: разработка и внедрение GO микросервисной платформы
- **Scope_in**: 6 GO микросервисов, 2 PostgreSQL, Kafka + Zookeeper, Keycloak, Prometheus + Grafana
- **Source**: [[2026-04-30-docker-compose]]
- **Tags**: #business-context

---

## BC-001 ?
- **Problem**: Конфигурационные файлы GO микросервисов
- **Goals**: Управление конфигурациями GO микросервисов
- **Scope_in**: GO микросервисы платформы
- **Source**: [[2026-04-30-readme]]
- **Tags**: #business-context
