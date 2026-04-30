# High Level Design (HLD)

**Document status**: DRAFT
**Jira CR**: <!-- ARCH-XXX -->
**Version**: 1.0
**Date**: <!-- YYYY-MM-DD -->

---

## 1. History of changes / История изменений

| # | Date | Author | Brief changes info | Reason of changes |
|---|------|--------|--------------------|-------------------|
| 1 | | | Initial version | |

---

## 2. Glossary / Глоссарий

| Term / Acronym | Definition |
|----------------|------------|
| | |

> **MANDATORY** — все аббревиатуры и доменные термины. Если термин трактуется специфически — указать «как понимаем в этом проекте».

---

## 3. Business context / Бизнес-контекст

### 3.1 Introduction / Введение

> **MANDATORY** — описать инициативу: что, зачем, в рамках какой программы.

### 3.2 Goals / Цели

> **MANDATORY** — цели должны быть проверяемыми (с метрикой/сроком где возможно).

| # | Goal | Metric | Target | Timeline |
|---|------|--------|--------|----------|
| 1 | | | | |

### 3.3 Stakeholders / Заинтересованные лица

> **MANDATORY**

| Role | Name | Interests / Expectations | RACI |
|------|------|--------------------------|------|
| Product Owner | | | A |
| Solution Architect | | | R |
| Security Lead | | | C |

### 3.4 Solution scope / Границы решения

> **MANDATORY** — содержать in-scope / out-of-scope и зависимости.

**In scope:**
-

**Out of scope:**
-

**Dependencies / Зависимости:**
-

---

## 4. Key requirements / Ключевые требования

### 4.1 Business requirements / Бизнес-требования

> **MANDATORY**

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| BR-001 | | Must | |

### 4.2 Business Status & Capacity / Текущие показатели бизнеса

> **MANDATORY** — текущие объёмы, нагрузка, capacity.

| Metric | Current value | Target value |
|--------|--------------|--------------|
| | | |

### 4.3 Security requirements / Требования по безопасности

> **MANDATORY**

| ID | Requirement | Trust boundary | Jira |
|----|-------------|---------------|------|
| SEC-001 | | | |

**Data flows:** Описать классы данных и где они проходят (потоки на TO-BE).
**Auth/Authz:** Описать аутентификацию/авторизацию на уровне принципа.
**Encryption:** Что шифруется in-transit / at-rest, где хранятся секреты.
**Logging/Audit:** Что и как логируется для расследования инцидентов.

### 4.4 Assumptions / Предположения

> **MANDATORY**

| # | Assumption | Comments |
|---|------------|----------|
| 1 | | |

#### 4.4.1 Access control model

Описать модель доступа: роли, права, принцип least privilege.

### 4.5 Design constraints / Ограничения проектного решения

| Constraint | Type | Description |
|------------|------|-------------|
| | Technical / Regulatory / Budget | |

### 4.6 Architectural concerns / Архитектурные аспекты

Зафиксировать архитектурные риски и компромиссы, требующие внимания.

### 4.7 Quality attributes and scenarios (NFR) / Атрибуты качества

> **MANDATORY (LOD2)**

| ID | Quality Attribute | Scenario | Target | Business Priority |
|----|------------------|----------|--------|------------------|
| NFR-001 | Performance | При пике N rps | p95 ≤ Xms, p99 ≤ Yms | High |
| NFR-002 | Availability | Uptime | 99.9% | High |
| NFR-003 | Security | | | High |
| NFR-004 | Observability | | | Medium |

### 4.8 Recommended standards / Рекомендованные стандарты

| Standard | Applicability |
|----------|--------------|
| eTOM / TMF Open API | |
| OAuth 2.0 / OIDC | |

---

## 5. Solution architecture / Архитектура решения

### 5.1 Integration scheme

#### 5.1.1 AS-IS Integration diagram

##### 5.1.1.1 Diagram / Диаграмма

<!-- Вставить C4 Container или Component диаграмму -->

##### 5.1.1.2 List of the components / Список компонентов

| Component | Description | Owner | Tech stack |
|-----------|-------------|-------|-----------|
| | | | |

##### 5.1.1.3 Additional info / Дополнительная информация

#### 5.1.2 TO-BE Integration diagram

##### 5.1.2.1 Diagram / Диаграмма

<!-- Вставить C4 Container или Component диаграмму -->

##### 5.1.2.2 List of the components / Список компонентов

| Component | Description | New / Modified | Owner |
|-----------|-------------|---------------|-------|
| | | | |

##### 5.1.2.3 Additional info

#### 5.1.3 Interfaces inventory

| Interface ID | Initiator | Provider | Description | Protocol | Format | Auth | MANDATORY |
|-------------|-----------|----------|-------------|----------|--------|------|-----------|
| IF-001 | | | | REST | JSON | OAuth2 | Yes |

### 5.2 End-to-end scenarios list / Список end-to-end сценариев

#### 5.2.1 Access control model / Модель доступа

| Role | System | Access type | Notes |
|------|--------|------------|-------|
| | | | |

#### 5.2.2 End-to-end scenarios

| UC ID | Scenario name | Involved systems | Happy path only |
|-------|--------------|-----------------|----------------|
| UC-01 | | | Yes |

**UC-01: [Название сценария]**

Описание happy path сценария. Технические детали — в LLD.

---

## 6. Architecture decision records (ADR)

### ADR-01 [Название решения]

**Status**: Proposed / Accepted / Deprecated
**Context**: Описать проблему или вопрос.
**Decision**: Принятое решение.
**Alternatives rejected**: Отклонённые варианты и причины.
**Consequences**: Последствия и trade-offs.

---

## 7. Open questions / Открытые вопросы

| # | Question | Context | Owner | Status | Jira |
|---|----------|---------|-------|--------|------|
| 1 | | | | Open | |
