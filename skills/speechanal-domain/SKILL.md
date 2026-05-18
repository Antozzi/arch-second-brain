# SKILL: speechanal-domain

## DESCRIPTION
SpeechAnal - платформа для анализа речи, интегрированная с Avaya Aura Contact Center и другими системами.

## WHEN_TO_USE
- При описании интеграции с Avaya Aura Contact Center.
- При обсуждении лицензирования программного обеспечения Avaya.
- При решении проблем с SSO интеграцией через ADFS.
- При работе с CDR парсером и системой мониторинга.
- При анализе проблем с Avaya Aura Session Manager.
- При разработке моделей и скриптов для отдела контроля качества сервиса.

## DOMAIN_CONTEXT
SpeechAnal используется для анализа речи, полученной из Avaya Aura Contact Center.  Включает интеграцию с различными системами, такими как Application Enablement Services (AES), CDR парсер, Active Directory, Yandex SpeechKit и др.  Используется для улучшения работы отдела контроля качества сервиса и автоматизации процессов.

## CORE_CONCEPTS
- **SpeechAnal Platform**: Платформа для анализа речи.
- **Avaya Aura Contact Center**: Система управления контакт-центром.
- **Application Enablement Services (AES)**: Платформа для интеграции с Avaya Aura Contact Center.
- **ADFS**: Active Directory Federation Services, система для SSO интеграции.
- **Breeze**: Система для управления и мониторинга сервисов Avaya Workspaces for Elite.
- **CDR**: Call Detail Record, запись о вызове.
- **sipTrace Utility**: Инструмент для анализа проблем с вызовами.
- **traceSM Utility**: Инструмент для захвата и сохранения действий обработки вызовов.
- **Experience Portal**: Компонент в архитектуре Avaya Aura Contact Center.
- **Yandex SpeechKit**: Сервис анализа аудио от Yandex.
- **HADOOP, БигДата**: Платформа для хранения метаданных аудио.
- **AAMS**: Avaya Aura Media Server, сервер для обработки медиа данных.
- **CMS**: Call Management System, система управления вызовами.
- **SBC**: Session Border Controller, устройство для управления сессиями.

## BUSINESS_RULES
- Лицензирование Heritage Nortel Software регулируется отдельным документом.
- Данные из Active Directory автоматически синхронизируются в Control Manager.
- Метаданные для аудио хранятся в HADOOP, БигДата.
- Система записи Avaya WFO хранит логи.

## DECISION_RULES
- Если возникли проблемы с SSO интеграцией → проверить правила в ADFS и повторить процедуру сопряжения с Breeze.
- Когда необходимо проанализировать сложные проблемы с вызовами → использовать sipTrace Utility.

## INTEGRATION_POINTS
- Avaya Aura Contact Center ↔ AES: Интеграция через REST, XML.
- CDR Парсер ↔ Система мониторинга: Интеграция через Telnet.
- Active Directory ↔ Control Manager: Синхронизация данных через LDAP.
- CMS ↔ PostgreSQL: Хранение данных о вызовах.
- Avaya Aura Communication Manager ↔ cdr service: Передача CDR записей.

## ANTI_PATTERNS
- ❌ Неправильная настройка правил в ADFS: Может привести к сбою SSO интеграции.
- ❌ Использование устаревших версий TLS: Может привести к проблемам с безопасностью.
- ❌ Недостаточная доступность CDP из сертификата кластера Breeze: Может привести к проблемам с подключением.

## SOURCE
- Проект: SpeechAnal
- Создан: 2026-05-18
