# Migrations

Каталог гайдов перехода между версиями методологии `team+ai`.

## Текущая версия

См. [`../VERSION`](../VERSION). История — в [`../CHANGELOG.md`](../CHANGELOG.md).

## Гайды (применять последовательно)

<!-- /full-ahead и другие команды НЕ применяют эти гайды автоматически.
     Пользователь читает и применяет руками. -->

- (Пока нет; первая миграция появится при следующем MINOR/MAJOR bump.)

## Как пользоваться

1. Посмотри свою текущую версию в `VERSION` файле твоей копии методологии.
2. Посмотри последнюю версию в исходном репо (например, на GitHub).
3. Применяй гайды последовательно: `v0.1-to-v0.2.md`, `v0.2-to-v0.3.md`, и т.д.
4. Каждый гайд — markdown с пошаговыми инструкциями. Скриптов нет — миграции делаются руками, чтобы пользователь видел каждый шаг.

## Формат гайда

Имя файла: `v<from>-to-v<to>.md`, например `v0.1-to-v0.2.md`. Обоснование принципа («один markdown-гайд на bump, без скриптов») — мета-ADR [`20260518-1501-markdown-migration-guides`](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1501-markdown-migration-guides.md). Общая политика версионирования — мета-ADR [`20260518-1500-version-methodology-via-version-file`](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1500-version-methodology-via-version-file.md).

## Связки

- [`../VERSION`](../VERSION)
- [`../CHANGELOG.md`](../CHANGELOG.md)
- [`../playbooks/release.md`](../playbooks/release.md) — команда `/release`, которая инициирует создание гайда при MINOR/MAJOR bump
