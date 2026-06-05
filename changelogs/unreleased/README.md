# changelogs/unreleased/

Каждый MR кладёт сюда **отдельный файл** с записями об изменениях в формате
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Команда `/release` собирает все файлы в один блок `## [X.Y.Z] — DATE` в
[`../../CHANGELOG.md`](../../CHANGELOG.md) через скрипт
[`../../scripts/build-changelog.py`](../../scripts/build-changelog.py) и удаляет
исходные фрагменты.

## Имя файла

`<ID-NNN>-<slug>.md` — например, `PROJ-142-google-oauth.md`. Для `chore` /
`docs` MR без задачи в трекере — просто `<slug>.md`.

## Формат содержимого

Внутри файла — только подсекции `### Added` / `### Changed` / `### Fixed` /
`### Removed` / `### Deprecated` / `### Security`. Пример:

```markdown
### Added

- Поддержка входа через Google OAuth (PROJ-142). Используется Google Identity Services.

### Security

- Токены OAuth хранятся в httpOnly cookie с SameSite=Lax (PROJ-142).
```

Не нужно заголовка `## [Unreleased]` — он только в `CHANGELOG.md`. Не нужно
писать `## [X.Y.Z]` — версия и дата ставятся при сборке `/release`.

## Зачем так

Раньше CHANGELOG.md имел общую секцию `## [Unreleased]`, в которую все
разработчики дописывали записи. Это создавало постоянные merge-конфликты при
параллельной работе. GitLab прошёл через [CHANGELOG conflict
crisis](https://about.gitlab.com/blog/solving-gitlabs-changelog-conflict-crisis/)
и пришёл к решению «один файл = одна запись». Мы используем тот же паттерн.

## Связки

- [`../../CHANGELOG.md`](../../CHANGELOG.md) — финальный аккумулирующий файл
- [`../../scripts/build-changelog.py`](../../scripts/build-changelog.py) — сборщик
- [`../../playbooks/release.md`](../../playbooks/release.md) — команда `/release`
- [`../../AGENTS.md` §4.1](../../AGENTS.md#41-имена-файлов) — формат имени
