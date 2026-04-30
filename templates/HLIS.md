# High Level Integration Specification (HLIS)

**Document status**: DRAFT  
**Jira CR**: <!-- ARCH-XXX -->  
**Version**: 1.0  
**Date**: <!-- YYYY-MM-DD -->

---

## 1. Versions / История изменений

| # | Date | Author | Description | Approved version |
|---|------|--------|-------------|-----------------|
| 1 | | | Initial version | |

---

## 2. Glossary / Глоссарий

| Term / Acronym | Definition |
|----------------|------------|
| | |

> **MANDATORY** — включить все аббревиатуры и доменные термины используемые в документе. Если термин трактуется специфически в рамках проекта — указать "как понимаем в этом проекте".

---

## 3. Purpose and scope / Назначение и границы

> **MANDATORY**

### 3.1 Purpose / Назначение

Описать цель интеграции: какие системы интегрируются, в рамках какой инициативы/программы, для какой бизнес-цели.

### 3.2 Scope / Границы

**In scope:**
- 

**Out of scope:**
- 

**Зависимости:**
- 

### 3.3 Phases / Фазы (если применимо)

| Фаза | Описание | Срок |
|------|----------|------|
| Phase 1 | | |
| Phase 2 | | |

---

## 4. Assumptions / Предположения

> **MANDATORY** — каждое предположение должно быть зарегистрировано в реестре предположений (Assumptions Registry) и трассировано до Jira.

| # | Assumption | Comments | Jira |
|---|------------|----------|------|
| 1 | | | |

---

## 5. Architecture decisions / Архитектурные решения (ADR)

> **MANDATORY** — каждое ADR должно содержать контекст, принятое решение, отклонённые альтернативы и последствия.

### ADR-01 [Название решения]

**Status**: Proposed / Accepted / Deprecated  
**Context**: Описать проблему или вопрос, требующий решения.  
**Decision**: Принятое решение.  
**Alternatives rejected**: Перечислить отклонённые варианты и причины отклонения.  
**Consequences**: Последствия и trade-offs принятого решения.  
**Jira**: 

---

## 6. Integration architecture / Архитектура интеграции

### 6.1 TO-BE Architecture / Целевая архитектура

#### 6.1.1 Architecture Description / Описание архитектуры

> Описать целевое состояние интеграции. Приложить C4 Container или Component диаграмму.

**Diagram**: <!-- ссылка на диаграмму или вставить PlantUML -->

**Involved components / Компоненты:**

| Component | Role | Owner |
|-----------|------|-------|
| | | |

#### 6.1.2 Interfaces Description / Описание интерфейсов

| Interface ID | Initiator | Provider | Description | Protocol | Format | Auth |
|-------------|-----------|----------|-------------|----------|--------|------|
| IF-001 | | | | REST/SOAP/MQ | JSON/XML | OAuth2/mTLS |

---

### 6.2 AS-IS Architecture / Текущая архитектура (если применимо)

#### 6.2.1 Architecture Description

> Описать текущее состояние до внедрения интеграции.

#### 6.2.2 Interfaces Description

| Interface ID | Initiator | Provider | Description | Protocol | Format |
|-------------|-----------|----------|-------------|----------|--------|
| | | | | | |

---

### 6.3 Transit Architecture / Переходная архитектура

> Описать промежуточное состояние на период перехода (bridging, параллельная работа старой и новой систем).

#### 6.3.1 Architecture Description

Описать переходный период: какие системы работают параллельно, как маршрутизируются запросы.

#### 6.3.2 Interfaces Description

| Interface ID | Initiator | Provider | Description | Phase | Notes |
|-------------|-----------|----------|-------------|-------|-------|
| | | | | | |

---

## 7. Bridging / Схема бриджинга

> Описать схему обеспечения связности между тестовыми и продуктивными средами в период перехода.

**Diagram**: <!-- ссылка или PlantUML -->

**Bridging components:**

| Component | Environment | Role |
|-----------|-------------|------|
| | | |

---

## 8. Identified requirements / Выявленные требования

> Требования, которые необходимо реализовать для обеспечения интеграции. Каждое требование трассируется до Jira Story.

| # | Required change | Components | Phase | Jira |
|---|----------------|------------|-------|------|
| 1 | | | | |

---

## 9. IDDs / Детализация сценариев интеграции

> Для каждого use case описать sequence diagram, выявленные требования и маппинг параметров.

### 9.1 Sequence diagrams

#### UC-01 [Название сценария]

**Task**: Описание задачи.  
**Jira**: 

**Preconditions:**
- 

**Postconditions:**
- 

**Involved components**: Система A, Система B, ...

**Sequence diagram**: <!-- PlantUML или ссылка -->

**Identified requirements for UC-01:**

| # | Required change | Components | Phase | Jira |
|---|----------------|------------|-------|------|
| 1 | | | | |

**Parameters mapping:**

| # | Parameter | Source system | Source field | Target system | Target field | Transformation |
|---|-----------|---------------|--------------|---------------|--------------|----------------|
| 1 | | | | | | |

---

#### UC-02 [Название сценария]

> (повторить структуру UC-01)

---

### 9.2 Security / Безопасность интеграции

| Interface ID | Auth method | Encryption | Token lifetime | Notes |
|-------------|-------------|------------|----------------|-------|
| | OAuth2 / mTLS / API Key | TLS 1.2+ | | |

### 9.3 Error handling / Обработка ошибок

| Scenario | Error code | Handling | Retry policy |
|----------|-----------|----------|-------------|
| Timeout | 504 | | 3x with backoff |

### 9.4 NFR / Нефункциональные требования

| ID | Quality attribute | Scenario | Target | Priority |
|----|------------------|----------|--------|----------|
| NFR-001 | Performance | При пике N rps | p95 ≤ Xms | High |
| NFR-002 | Availability | Uptime | 99.9% | High |

### 9.5 Configurations / Конфигурируемые параметры

| Parameter | Description | Default | Configurable by |
|-----------|-------------|---------|----------------|
| | | | |

---

## 10. Open questions / Открытые вопросы

> **MANDATORY** — все открытые вопросы должны быть зарегистрированы и трассированы до Jira или ответственного лица.

| # | Date | Question | Context | Owner | Status | Jira |
|---|------|----------|---------|-------|--------|------|
| 1 | | | | | Open | |

---

## 11. Materials / Материалы

| # | Enclosure | Description |
|---|-----------|-------------|
| 1 | | |

---

## 12. Deployment diagram (bridging / test environments) / Схема развёртывания для тестовых сред

> Этот раздел **не является частью согласования**. Содержит схему бриджинга между тестовыми средами и может изменяться.

### 12.1 Deployment diagram

<!-- Диаграмма развёртывания тестовых сред -->

### 12.2 Identified requirements for deployment

| # | Required change | Components | Phase | Jira |
|---|----------------|------------|-------|------|
| 1 | | | | |

---

## 13. Deployment requirements (production) / Требования к развёртыванию в продуктиве

### 13.1 Deployment diagram

<!-- Диаграмма развёртывания продуктивной среды -->

### 13.2 Identified requirements for deployment

| # | Required change | Components | Phase | Jira |
|---|----------------|------------|-------|------|
| 1 | | | | |
