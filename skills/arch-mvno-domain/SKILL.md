# arch-mvno-domain

## WHEN_TO_USE
Подгружай этот скилл, когда документ относится к проекту ARCH-MVNO: описывает Use Cases (UC) и Knowledge Zones (KZ) для интеграции MVNO с DBSS в рамках VEON.

## CORE_CONCEPTS
- **Use Case (UC)** — сценарий использования, описанный в таблицах документа.
- **Knowledge Zone (KZ)** — область знаний, к которой относится UC.
- **Business epic** — бизнес-эпик, на который опирается интеграция (relies_on) либо которым она пользуется (used_by).
- **Glossary** — определения терминов проекта.

## DECISION_RULES
- Если в документе есть таблица с UC → извлеки `use_case_name`, `task_id`, связи с business epic.
- Если есть таблица версий → извлеки версии, авторов, даты, статусы согласования.
- Если есть глоссарий → извлеки термины и определения.
- Если есть раздел scope/purpose → извлеки в `purpose_and_scope`.

## PLAYBOOKS
1. Извлечь Use Case name и Task id из таблиц.
2. Извлечь Business epic, на который опирается интеграция (relies_on).
3. Извлечь Business epic, которым пользуется интеграция (used_by).
4. Извлечь версии документов: автор, дата, описание, согласованная версия, согласующие.
5. Извлечь определения терминов из глоссария.
6. Извлечь scope и purpose документов.

## ANTI_PATTERNS
- Не путать relies_on (на что опирается) и used_by (кто пользуется).
- Не включать реальные имена согласующих — только роли.
- Не выдумывать task_id, если его нет в таблице.

## JSON-структура
```json
{
  "use_cases": [
    {"use_case_name": "string", "task_id": "string", "relies_on": "string", "used_by": "string", "source": "[[filename]]"}
  ],
  "versions": [
    {"version_number": "integer", "date": "string", "author": "string", "description": "string", "approved_version": "string", "approvers": "string", "source": "[[filename]]"}
  ],
  "glossary": [
    {"term": "string", "definition": "string", "source": "[[filename]]"}
  ],
  "purpose_and_scope": {"description": "string", "phase": "string", "source": "[[filename]]"}
}
```
