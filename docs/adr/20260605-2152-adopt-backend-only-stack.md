# 20260605-2152-adopt-backend-only-stack

## Status

Accepted

## Date

2026-06-05

## Decision Maker(s)

- msamichev

## Context

Полигон `aity-playground` переходит Phase 0 → Phase 1: пора материализовать структуру кода под
todo-list REST API (см. [docs/idea/04-mvp.md](../idea/04-mvp.md)). Тип проекта — **backend-only**
(чистый JSON REST, без фронтенда и БД, хранилище в памяти).

Ограничения и цели:
- стек должен **легко ложиться в Docker-образ** ботов (Фаза 2 плана agent-aity);
- быстрые тесты (ground-truth для оценки ботов);
- максимально **стандартный** стек — полигон будут расширять слабые модели (DeepSeek/Qwen),
  а Express/TypeScript хорошо представлены в их обучающих данных.

## Decision

Выбираем **Node 20 + TypeScript** (ESM, `NodeNext`), backend-only:

- HTTP-фреймворк: **Express 5**;
- тесты: **Vitest** + **supertest** (через in-app inject, без реальных сокетов);
- линт: **ESLint 9** (flat config) + **typescript-eslint**, `--max-warnings 0`;
- формат: **Prettier** (скоуп — только код проекта, не markdown методологии);
- сборка: `tsc` (`tsconfig.build.json` → `dist/`), запуск `node dist/server.js`, dev — `tsx`;
- контейнеризация: многостадийный `Dockerfile` (`node:20-slim`, non-root).

Структура: `src/` (`store.ts`, `app.ts`, `server.ts`), `tests/`.

## Consequences

### Positive

- Лёгкий, быстрый стек; тесты исполняются за секунды.
- Express/TS — стандарт, понятный слабым моделям-ботам.
- `scripts/ci-push.sh` заполнен под Node (build, typecheck, tests+coverage); внешние SAST/SCA
  (gitleaks/semgrep/trivy) подключатся, если установлены.

### Negative or Trade-offs

- ESM + `NodeNext` требует расширения `.js` в относительных импортах TS — мелкая, но непривычная деталь.
- In-memory store не покрывает темы персистентности/конкурентности — осознанно вне скоупа полигона.

### Follow-ups

- Реализовать baseline todo-API + тесты, добиться зелёного `scripts/ci-push.sh`.
- GitHub Actions, гоняющий `ci-push.sh` (серверный CI как ground-truth) — к Фазам 5–6.
- Добавить в образ ботов инструменты стека (`node`, `npm`) — Фаза 2 плана agent-aity.

## Confirmation

Стек считается принятым, когда `npm ci && npm run build && npm run lint && npm test` и
`scripts/ci-push.sh` зелёные локально на baseline-реализации.

## Alternatives considered

### Fastify вместо Express

- Идея: Fastify даёт нативный TS и `inject()` для тестов из коробки.
- Отказались потому что: Express стандартнее и лучше «знаком» слабым моделям — важнее для полигона ботов.

### Чистый `node:http` без фреймворка

- Идея: ноль рантайм-зависимостей, минимальная поверхность для SCA.
- Отказались потому что: ручной роутинг — больше кода и ошибок для ботов; Express тут выгоднее.

### Python (FastAPI)

- Идея: тоже лёгкий backend-стек.
- Отказались потому что: Node+TS легче тащить в образ и быстрее в тестах (зафиксировано в плане).

## Связки

- [AGENTS.md §3 Индекс ADR](../../AGENTS.md#3-индекс-adr)
- [docs/idea/04-mvp.md](../idea/04-mvp.md)
- [docs/adr/20260605-2059-bootstrap.md](20260605-2059-bootstrap.md)
- [docs/architecture/overview.md](../architecture/overview.md)
