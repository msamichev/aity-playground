# Recommended Skills

> Каталог Claude Code skills, рекомендуемых под разные типы проектов.
> Все указанные skills **проверены по первоисточникам** (GitHub репозитории, marketplace).
> Редактируется руками. `/skills-suggest` читает этот файл.

---

## Принципы

1. **Только проверенные.** Каждый skill в этом каталоге существует, имеет публичный репозиторий, и можно его установить указанной командой.
2. **Без выдумок.** Если в каталоге чего-то нет — значит, я не нашёл такого skill'а с реальной адопцией. Это **не значит**, что задачу не решить — её решает либо наш собственный playbook, либо обычный промпт.
3. **Лимит на проект — 8-12 skills.** Больше — налог на контекст. См. `/skills-audit`.
4. **Bundled (`/simplify`, `/batch`, `/debug`, `/loop`, `/claude-api`)** — доступны всегда, не требуют установки.

## Семантика полей

Каждый раздел и каждый отдельный skill могут иметь два опциональных поля, которые читают `/doctor` и `/skills-suggest`:

- **Применимо в фазах:** `0` / `0.5` / `1` / `2-feature` через запятую. Если у раздела одно значение, а у конкретного skill'а внутри — другое, **значение skill'а имеет приоритет**.
- **Conflicts with:** какие skills/MCP/playbook'и конфликтуют. Если установлены оба — `/doctor` выводит предупреждение, но не блокирует.

Поля пишутся жирными метками в начале блока («**Применимо в фазах:** 1, 2-feature») — это совместимо с обычным markdown и понятно человеку.

---

## Универсальные (для любого проекта)

**Применимо в фазах:** 0.5, 1, 2-feature

### Superpowers — процессная дисциплина

**Применимо в фазах:** 0.5, 1, 2-feature
**Conflicts with:** наш playbook `/plan` (и косвенно `/adopt-architecture`).

**Репозиторий:** https://github.com/obra/superpowers (193k+ звёзд)

**Что делает:** TDD-discipline + структурированный workflow brainstorming → write-plan → execute-plan. Подходит когда хочется системность.

**Установка:**
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

**Совместимость:** Claude Code, Codex CLI/App, Factory Droid, Gemini CLI, OpenCode, Cursor, GitHub Copilot CLI.

**⚠️ Важно:** пересекается с нашим [`/plan`](../playbooks/plan.md) playbook. Если устанавливаешь — придётся выбирать, какой workflow использовать (наш `/plan` или Superpowers `brainstorm+write-plan+execute-plan`). Не ставь без явного намерения. Рекомендуется зафиксировать решение через ADR.

---

### skill-creator — утилита создания skills

**Применимо в фазах:** 2-feature (после 2-4 недель работы с проектом)

**Репозиторий:** https://github.com/anthropics/skills (часть example-skills)

**Что делает:** Помогает создавать собственные skills интерактивно. Полезен когда захочется свой узкий skill под конкретные задачи проекта.

**Установка:**
```
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
```

(установит сразу несколько example-skills, в т.ч. skill-creator)

**Когда ставить:** не сразу. После того, как поработал с проектом 2-4 недели и начал замечать повторяющиеся инструкции — пора их превратить в skill через skill-creator.

---

## Если в проекте есть фронт

**Применимо в фазах:** 0.5 (если по idea понятно что будет фронт), 1, 2-feature

### frontend-design (Anthropic)

**Репозиторий:** https://github.com/anthropics/skills/tree/main/skills/frontend-design

**Что делает:** Заставляет Claude **думать про дизайн до того как писать код**. Выбрать aesthetic direction (brutalist / maximalist / refined minimal / etc.), отказаться от generic «AI slop» (Inter font + purple gradient + центрированный hero + 3 карточки).

**Установка:**
```
npx skills add https://github.com/anthropics/skills --skill frontend-design
```

Или через Claude Code marketplace:
```
/plugin marketplace add anthropics/skills
/plugin install example-skills@anthropic-agent-skills
```

**На что обращать внимание:** даёт максимальный эффект для marketing-страниц, лендингов, дашбордов. Для уже устоявшегося дизайн-системы менее полезен.

---

### web-design-guidelines (Vercel)

**Репозиторий:** https://github.com/vercel-labs/agent-skills (22.1k+ звёзд)

**Что делает:** 100+ правил для проверки UI-кода: accessibility (ARIA, semantic HTML, keyboard nav), focus states, forms, animation (prefers-reduced-motion), typography, images, performance, touch & i18n.

**Установка:**
```
npx skills add vercel-labs/agent-skills
```

(установит все 5 Vercel agent-skills сразу: web-design-guidelines, react-best-practices, composition-patterns, react-native-guidelines, vercel-deploy-claimable)

**Можно выборочно** через `npx skills add vercel-labs/agent-skills --skill web-design-guidelines`.

**Когда триггерится:** «Review my UI», «Check accessibility», «Audit design», «Review UX».

---

### composition-patterns (Vercel)

**Репозиторий:** https://github.com/vercel-labs/agent-skills

**Что делает:** Паттерны композиции компонентов: compound components, lifting state, internal composition, против boolean-prop proliferation.

**Установка:**
```
npx skills add vercel-labs/agent-skills --skill composition-patterns
```

**Когда нужен:** при рефакторинге компонентов с большим количеством boolean-props, при дизайне переиспользуемых библиотек.

---

## Если React или Next.js

**Применимо в фазах:** 1, 2-feature

### react-best-practices (Vercel)

**Репозиторий:** https://github.com/vercel-labs/agent-skills

**Что делает:** 40+ правил производительности React/Next.js по 8 категориям: eliminating waterfalls, bundle size, server-side performance, client data fetching, re-render optimization, rendering performance, JS micro-optimizations, advanced patterns. Каждое правило с примерами «плохо/хорошо».

**Установка:**
```
npx skills add vercel-labs/agent-skills --skill react-best-practices
```

---

## Если React Native

**Применимо в фазах:** 1, 2-feature

### react-native-guidelines (Vercel)

**Репозиторий:** https://github.com/vercel-labs/agent-skills

**Что делает:** 16 правил по 7 категориям: performance (FlashList, memoization), layout (flex, safe areas, keyboard), animation (Reanimated, gestures), images (expo-image), state management (Zustand), architecture (monorepo), platform-specific.

**Установка:**
```
npx skills add vercel-labs/agent-skills --skill react-native-guidelines
```

---

## Документы (только если генерируешь docx/xlsx/pdf/pptx)

**Применимо в фазах:** 2-feature (если фича требует генерации документов)

### docx, xlsx, pdf, pptx (Anthropic)

**Репозиторий:** https://github.com/anthropics/skills (subdirs `skills/docx`, `skills/xlsx`, `skills/pdf`, `skills/pptx`)

**Что делает:** Создание, редактирование, парсинг реальных файлов соответствующих форматов через Python-скрипты. Это **те же skills**, которые используются в Claude.ai для создания документов.

**Установка** (только нужное, не все четыре сразу если не нужно):
```
npx skills add https://github.com/anthropics/skills --skill docx
npx skills add https://github.com/anthropics/skills --skill xlsx
npx skills add https://github.com/anthropics/skills --skill pdf
npx skills add https://github.com/anthropics/skills --skill pptx
```

Или сразу все через document-skills плагин:
```
/plugin install document-skills@anthropic-agent-skills
```

**Когда ставить:** если в фичах есть генерация отчётов, инвойсов, экспорт данных в Excel, и т.п.

---

## Тестирование web-приложений

**Применимо в фазах:** 1, 2-feature (когда фича касается UI и нужны e2e-проверки)

### webapp-testing (Anthropic)

**Применимо в фазах:** 1, 2-feature
**Conflicts with:** MCP `playwright` (выбирать одно — CLI дешевле по токенам, см. METHODOLOGY.md §10).

**Репозиторий:** https://github.com/anthropics/skills/tree/main/skills/webapp-testing

**Что делает:** Toolkit для тестирования локальных web-приложений через **Playwright CLI**. Проверка функциональности, debug UI, скриншоты, чтение console-логов. **Использует CLI, не MCP** — токены не тратятся на schema-нагрузку.

**Установка:**
```
npx skills add https://github.com/anthropics/skills --skill webapp-testing
```

**Альтернативы:**
- Если хочется MCP-режим Playwright — `claude mcp add playwright -- npx -y @microsoft/playwright-mcp-server`. **Не рекомендуем** — ~4x токенов на типичный e2e-сценарий.

---

## Создание MCP-серверов (опционально, для авторов плагинов)

**Применимо в фазах:** 2-feature (только когда сознательно решено написать свой MCP)

### mcp-builder (Anthropic)

**Репозиторий:** https://github.com/anthropics/skills/tree/main/skills/mcp-builder

**Что делает:** Помогает писать собственные MCP-серверы под нужды проекта.

**Установка:**
```
npx skills add https://github.com/anthropics/skills --skill mcp-builder
```

**Когда ставить:** только если решил написать свой MCP-сервер (редко).

---

## Чего НЕТ в каталоге (и не появится без подтверждения)

- ❌ **Универсальный «архитектурный» skill** — нет такого в marketplace с подтверждённой адопцией. Используем наш [`/adopt-architecture`](../playbooks/adopt-architecture.md) playbook.
- ❌ **Skill для написания backend API** — стандартного нет. Делаем промптом + следуем ADR.
- ❌ **Skill для unit/integration тестирования бэка** — стандартного нет. Покрываем через наш [`/full-ahead`](../playbooks/full-ahead.md) + mutation testing.
- ❌ **Skill для CI/CD pipeline** — нет хорошего общего, разные провайдеры разные skills. Делаем в `/adopt-stack` руками.
- ❌ **Skill для Docker/Kubernetes optimization** — нет хорошего общего. Используем `hadolint` (CLI) и обычные промпты.
- ❌ **Code review skills** — есть кандидаты (Agensi `code-reviewer` ~116 установок, `/simplify` bundled), но статистика на текущий момент не показывает явного лидера. Используем bundled `/simplify` + наш `/critic`.

Если найдёшь skill с подтверждённой адопцией (>1k звёзд / >10k installs), который закрывает один из этих gaps — обнови этот файл вручную, добавь в нужный раздел.

---

## Связки

- [skills-suggest playbook](../playbooks/skills-suggest.md) — читает этот файл
- [skills-audit playbook](../playbooks/skills-audit.md) — обратная сторона: чистка
- [METHODOLOGY.md](../METHODOLOGY.md) §10 — про MCP vs CLI, оптимум 8-12 skills
- [expected-tools.md](expected-tools.md) — отдельный каталог CLI/MCP/runtimes
