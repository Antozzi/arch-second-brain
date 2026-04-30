# Architecture Decision Records — ARCH-ESS

## ADR-001 ?
- **Status**: Proposed
- **Source**: [[2026-04-30-tobe_sequence]]
- **Tags**: #adr

---

## ADR-001 ?
- **Status**: Proposed|Accepted
- **Source**: [[2026-04-30-scenarios]]
- **Tags**: #adr

---

## ADR-001 Database Setup Decision
- **Status**: Proposed
- **Context**: The registry service requires a database setup.
- **Decision**: Use a PostgreSQL database with the specified host, port, name, user, and password.
- **Alternatives**: #hypothesis
- **Source**: [[2026-04-30-registry-service]]
- **Tags**: #adr

---

## ADR-001 ?
- **Status**: Proposed
- **Source**: [[2026-04-30-c4_container]]
- **Tags**: #adr

---

## ADR-001 GO сервис как центральный хаб
- **Status**: Proposed
- **Context**: Недостаточная гибкость и масштабируемость монолитной системы
- **Decision**: Использовать GO сервис как центральный хаб для обмена данными между сервисами
- **Source**: [[2026-04-30-stage2-service-separation]]
- **Tags**: #adr

---

## ADR-001 Database Connection Settings
- **Status**: Proposed
- **Context**: Configure exchange service for production environment
- **Decision**: Use PostgreSQL database for caching idempotency keys
- **Alternatives**: #hypothesis
- **Source**: [[2026-04-30-exchange-service]]
- **Tags**: #adr

---

## ADR-001 Добавление финансовых баз
- **Status**: Proposed
- **Source**: [[2026-04-30-finance-bases-summary]]
- **Tags**: #adr

---

## ADR-001 ?
- **Status**: Proposed
- **Context**: Временное резервирование для розничных продаж
- **Decision**: Временный резерв (TTL 5 минут)
- **Alternatives**: Разделение остатков по каналам продаж
- **Source**: [[2026-04-30-discussion-topics]]
- **Tags**: #adr

---

## ADR-001 ?
- **Status**: Proposed
- **Context**: Нужно решить проблему точной информации о остатках на складе
- **Decision**: Использовать систему управления остатками на основе PostgreSQL
- **Alternatives**: #hypothesis
- **Source**: [[2026-04-30-stock-table-diagram]]
- **Tags**: #adr

---

## ADR-001 Асинхронность обмена данными
- **Status**: Proposed
- **Source**: [[2026-04-30-exchange-protocol]]
- **Tags**: #adr

---

## ADR-001 ?
- **Status**: Proposed|Accepted
- **Context**: Полная отмена поступления через Акт / Возврат и CORRECT
- **Decision**: Использовать корректировку в ESS для полной отмены поступления
- **Alternatives**: #hypothesis
- **Consequences**: #hypothesis
- **Source**: [[2026-04-30-full_correction_recording]]
- **Tags**: #adr

---

## ADR-001 Audit Service Configuration Decision Record
- **Status**: Proposed
- **Context**: Need to configure audit service for logging and monitoring
- **Decision**: Configure audit service to log events, monitor performance, and ensure security
- **Alternatives**: #hypothesis
- **Consequences**: #hypothesis
- **Source**: [[2026-04-30-audit-service]]
- **Tags**: #adr

---

## ADR-001 ?
- **Status**: Proposed|Accepted
- **Source**: [[2026-04-30-summary]]
- **Tags**: #adr

---

## ADR-001 Разделение финансовых операций
- **Status**: Proposed
- **Context**: Централизация и разделение финансовых операций
- **Decision**: Разделить финансовые операции на 1С Банк и Касса и 1С ДБСС Финансы
- **Consequences**: Автоматизация сверок, независимость, масштабируемость
- **Source**: [[2026-04-30-finance-bases]]
- **Tags**: #adr

---

## ADR-001 Предварительный резерв 1С
- **Status**: Accepted
- **Context**: Необходимость унифицировать резервирование в системе
- **Decision**: Добавить поля для предв. резерва 1С и вычисляемого свободного остатка в таблицу stocks.stock_balance
- **Consequences**: Упростить процесс резервирования, обеспечить точную вычисляемость свободного остатка
- **Source**: [[2026-04-30-summary-v3]]
- **Tags**: #adr

---

## ADR-001 API Gateway Service Architecture Decision Record
- **Status**: Proposed
- **Context**: Provide a secure and scalable API gateway for microservices communication.
- **Decision**: Use Keycloak for authentication and authorization.
- **Source**: [[2026-04-30-api-gateway]]
- **Tags**: #adr

---

## ADR-001 ?
- **Status**: Proposed
- **Context**: ПТУ с частичной ошибкой и повторной отправкой недостающих строк
- **Decision**: #hypothesis
- **Source**: [[2026-04-30-partial_recording]]
- **Tags**: #adr

---

## ADR-001 Переход на асинхронную интеграцию между 1С и ESS
- **Status**: Proposed
- **Context**: Несинхронизация данных между двумя системами
- **Decision**: Перейти на асинхронную интеграцию для обеспечения целостности данных
- **Source**: [[2026-04-30-_-_1-_ess-1]]
- **Tags**: #adr

---

## ADR-001 Добавление предварительного резерва 1С
- **Status**: Proposed
- **Source**: [[2026-04-30-migration-to-v3]]
- **Tags**: #adr

---

## ADR-001 Регистрация баз данных в GO Platform
- **Status**: Proposed
- **Source**: [[2026-04-30-database-registration-guide]]
- **Tags**: #adr
