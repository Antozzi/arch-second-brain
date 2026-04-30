# Architecture Note — Post-Analysis (AN)

**Initiative**: <!-- Название инициативы -->
**Jira IT Bazaar**: <!-- ITBZR-XXX -->
**Pre-Analysis AN**: <!-- ссылка -->
**SPOC SA**: <!-- ФИО -->
**Status**: DRAFT / IN REVIEW / HANDOVER
**Date**: <!-- YYYY-MM-DD -->
**SLA**: 40 рабочих часов

> **Цель Post-Analysis**: углублённая архитектурная проработка после первичного одобрения на IT Bazaar. Результат — полный HLD-уровень архитектуры с детализированными сценариями, NFR, ADR и планом реализации.

---

## 1. Описание инициативы

### 1.1 Участники

| Роль | ФИО / Команда | Ответственность |
|------|--------------|----------------|
| Initiative Owner | | A |
| SPOC SA | | R |
| Reviewer | | C |
| Security Lead | | C |

### 1.2 Версионирование

| Версия | Дата | Автор | Изменения |
|--------|------|-------|-----------|
| 0.1 | | | Post-Analysis initial |

### 1.3 Связанные документы

| Документ | Ссылка |
|---------|--------|
| Pre-Analysis AN | |
| BRD | |
| Jira CR | |

---

## 2. Подтверждение результатов Pre-Analysis

### 2.1 Problem Statement (подтверждён / уточнён)

### 2.2 Выбранный вариант решения

Подтвердить или уточнить рекомендованный вариант из Pre-Analysis. Если вариант изменился — обосновать.

### 2.3 Изменения в скоупе

| Элемент | Pre-Analysis | Post-Analysis | Причина изменения |
|---------|-------------|--------------|------------------|
| | | | |

---

## 3. Детальная архитектура решения

### 3.1 AS-IS Architecture

#### 3.1.1 Описание текущего состояния

#### 3.1.2 AS-IS диаграмма

<!-- C4 Container diagram -->

#### 3.1.3 Список компонентов AS-IS

| Component | Description | Owner | Tech stack | Known issues |
|-----------|-------------|-------|-----------|-------------|
| | | | | |

### 3.2 TO-BE Architecture

#### 3.2.1 Описание целевого состояния

#### 3.2.2 TO-BE диаграмма

<!-- C4 Container diagram -->

#### 3.2.3 Список компонентов TO-BE

| Component | New / Modified | Description | Owner | Tech stack |
|-----------|--------------|-------------|-------|-----------|
| | | | | |

### 3.3 Interfaces inventory

| Interface ID | Initiator | Provider | Description | Protocol | Format | Auth | Security | MANDATORY |
|-------------|-----------|----------|-------------|----------|--------|------|----------|-----------|
| IF-001 | | | | REST | JSON | OAuth2 | TLS 1.3 | Yes |

### 3.4 End-to-end scenarios

| UC ID | Scenario | Involved systems | Priority |
|-------|----------|-----------------|----------|
| UC-01 | | | Must |

**UC-01: [Название]**

Sequence diagram: <!-- PlantUML -->

Happy path steps:
1.
2.

---

## 4. Ключевые требования

### 4.1 Бизнес-требования (детализированные)

| ID | Requirement | Acceptance criteria | Priority | Jira |
|----|-------------|--------------------|---------|----- |
| BR-001 | | | Must | |

### 4.2 NFR (детализированные сценарии)

| ID | Quality Attribute | Scenario | Target | Measurement | Priority |
|----|------------------|----------|--------|-------------|---------|
| NFR-001 | Performance | | p95 ≤ Xms | Load test | High |
| NFR-002 | Availability | | 99.9% uptime | Monitoring | High |
| NFR-003 | Security | | | Pentest | High |
| NFR-004 | Observability | | | | Medium |
| NFR-005 | DR | | RTO=Xh, RPO=Yh | DR test | High |

### 4.3 Security requirements

| ID | Requirement | Trust boundary | Implementation | Jira |
|----|-------------|---------------|---------------|------|
| SEC-001 | | | | |

### 4.4 Assumptions (финальные)

| # | Assumption | Confirmed | Jira |
|---|------------|-----------|------|
| 1 | | Yes/No | |

---

## 5. Architecture Decision Records (ADR)

### ADR-01 [Название решения]

**Status**: Accepted
**Context**:
**Decision**:
**Alternatives rejected**:
**Consequences**:
**Jira**:

---

## 6. Data & Standards

### 6.1 Доменные объекты данных

| Object | Source | Owner | Classification | Standard (TMF/eTOM) |
|--------|--------|-------|---------------|---------------------|
| | | | | |

### 6.2 Применимые стандарты

| Standard | Version | Applicability |
|----------|---------|--------------|
| | | |

---

## 7. Риски и план митигации

| ID | Risk | P (L/M/H) | I (L/M/H) | Mitigation | Owner | Status |
|----|------|-----------|-----------|------------|-------|--------|
| R-001 | | | | | | Open |

---

## 8. Plan & Estimations

### 8.1 Высокоуровневый план реализации

| Phase | Scope | Duration | Dependencies |
|-------|-------|----------|-------------|
| Phase 1 | | | |

### 8.2 Команда и роли

| Role | Responsibility | FTE |
|------|---------------|-----|
| | | |

---

## 9. Open questions

| # | Question | Context | Owner | Urgency | Status |
|---|----------|---------|-------|---------|--------|
| 1 | | | | Blocker/High/Normal | Open |

---

## 10. Acceptance Criteria

**Post-Analysis DoD checklist:**

- [ ] AS-IS и TO-BE архитектура детализированы до уровня компонентов
- [ ] Interfaces inventory заполнен (все MANDATORY интерфейсы)
- [ ] End-to-end сценарии описаны (happy path)
- [ ] NFR детализированы как сценарии качества с метриками
- [ ] Security requirements трассированы до интерфейсов/UC
- [ ] ADR зафиксированы для всех ключевых архитектурных решений
- [ ] Топ-риски с планом митигации
- [ ] Высокоуровневый план реализации согласован
- [ ] Review Outcome = Pass
- [ ] Согласован с Initiative Owner и Security Lead
