# <PROJECT_NAME>

> <one-liner про продукт>

## Что это

<!-- /init-project заполнит -->

## Как работать

Этот проект использует методологию **«команда + AI»** для команды 4-7 человек по GitLab Flow. Полное описание — в [`METHODOLOGY.md`](METHODOLOGY.md).

Кратко:
- AI читает [`AGENTS.md`](AGENTS.md) (или [`CLAUDE.md`](CLAUDE.md) — это симлинк) в каждой сессии. Личные оверрайды каждого разработчика — в `CLAUDE.local.md` (gitignored).
- Все архитектурные решения — в [`docs/adr/`](docs/adr/). Индекс — [`docs/adr/INDEX.md`](docs/adr/INDEX.md) (генерируется автоматически).
- Технические планы — в [`plans/`](plans/) (один план = одна задача из внешнего трекера). Ретроспективы — в [`retrospectives/`](retrospectives/) (общекомандные после релиза).
- Команды (skills) — в `.claude/skills/`. Основные:
  - `/init-project` — один раз, первый разработчик.
  - `/onboard-developer` — каждый следующий разработчик после клонирования.
  - `/adopt-stack`, `/plan`, `/full-ahead`, `/open-mr`, `/adr`, `/retro`, `/release`.

## Командная работа

- **`main` защищён**, прямой push запрещён. Любое изменение — через Merge Request с минимум 1 approve, зелёный pipeline, squash on merge.
- Имена веток: `feature/<ID-задачи>-<slug>`, `bugfix/...`, `hotfix/...`, `chore/...`, `docs/...`. ID задачи — из внешнего трекера (`id_prefix` в [`AGENTS.md §0`](AGENTS.md#0-project-one-liner)).
- Полная git-модель и правила MR — [`AGENTS.md §4.3`](AGENTS.md#43-git) + раздел [«Командная специфика»](METHODOLOGY.md#12-командная-специфика) в `METHODOLOGY.md`.
- Владельцы командных файлов — в [`CODEOWNERS`](CODEOWNERS).

## Локальная разработка

<!-- /adopt-stack заполнит эту секцию: prerequisites, install, run, test -->

См. [`scripts/local-ci.sh`](scripts/local-ci.sh) — зеркало CI-пайплайна.

## Структура

См. [`AGENTS.md §2`](AGENTS.md#2-карта-проекта).
