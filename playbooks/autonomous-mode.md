# Autonomous Mode Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/autonomous` или соответствующая фраза на естественном языке (см. таблицу триггеров в [AGENTS.md](../AGENTS.md)).
> **Тонкая обёртка для Claude Code:** [.claude/skills/autonomous-mode/SKILL.md](../.claude/skills/autonomous-mode/SKILL.md).

---

Autonomous mode — опциональный режим работы методологии `team+ai`, в котором AI выполняет фичу с минимумом интеракций. Цель — дать сравнительно крупную, абстрактную задачу и получить готовый, выверенный результат за один заход.

Унаследован из `solo+ai` 0.3.0 (см. мета-ADR [`20260520-1700-autonomous-mode-with-readonly-subagents`](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260520-1700-autonomous-mode-with-readonly-subagents.md)). В team+ai режим **ограничен собственной feature-веткой разработчика**: писать он может только в свою ветку и никогда — в `main` или чужие защищённые ветки. См. [ADR `20260521-1100-team-ai-methodology-on-top-of-solo-ai`](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260521-1100-team-ai-methodology-on-top-of-solo-ai.md).

## Что входит в режим

1. **Front-loaded clarification в `/plan`.** Все уточняющие вопросы — одним блоком до начала реализации. См. [plan playbook](plan.md), Шаг 2.
2. **Машиночитаемый критерий приёмки** в каждом плане (`## Критерий приёмки` как markdown checklist).
3. **Three-gate review в `/full-ahead`.** После `local-ci.sh` зелёного — три read-only subagent-а: `code-reviewer`, `test-runner`, `security-auditor` (условно). См. [full-ahead playbook](full-ahead.md), Шаг 4.
4. **Stop hook чеклист.** Финальная страховка перед коммитом ([`scripts/stop-checklist.sh`](../scripts/stop-checklist.sh)).
5. **`permissionMode: acceptEdits`** для основной сессии на время цикла — без подтверждения каждого edit.
6. **Writes — только основная сессия.** Все три subagent-а read-only по контракту.

## Когда использовать

- Фича крупнее одного файла, с тестами и/или security-чувствительностью.
- Не хочется вести диалог по ходу — готов сформулировать критерий приёмки заранее.
- Есть инфраструктура тестов (Phase 1+) и/или security-чувствительные модули.
- **Ты в собственной feature-ветке**, не на `main` или чужой ветке. Перед стартом — `git fetch && git rebase origin/main`, чтобы стартовать с актуальной базы.

## Когда НЕ использовать

- Phase 0 / Phase 0.5 (нет кода, нечего проверять). Используй обычный режим.
- На ветке `main` или защищённой — режим должен отказаться стартовать (Stop hook проверяет ветку).
- Bug fix или правка в одном файле — single agent через `/save` дешевле и быстрее.
- Research-задача без конкретного критерия приёмки.
- Сильная неопределённость в требованиях — лучше обычный диалог.
- Чужая feature-ветка коллеги — режим пишет только в свою ветку, никогда не в чужую.

## Контракт работы

В autonomous mode AI **обязан**:

1. Собрать все вопросы одним блоком в `/plan` Шаг 2.
2. Формализовать критерий приёмки до начала кода.
3. Использовать three-gate review в `/full-ahead`.
4. Эскалировать пользователю, если цикл Subagent↔Coder не сходится за 2 раунда того же класса проблем.
5. Не помечать фичу как выполненную, пока Stop hook чеклист красный.

В autonomous mode AI **не должен**:

- Возвращаться за уточнениями по ходу реализации (исключения — в [plan playbook](plan.md), Шаг 2).
- Делегировать запись в файлы subagent-у (writes остаются за основной сессией).
- Запускать цикл review-loop больше 2 раундов — на 3-м обязательная эскалация.
- Использовать `--no-verify` или иначе обходить гейты.
- **Пушить в `main`** или любую защищённую ветку — только в собственную feature-ветку через `/save-all` или `/full-ahead`.
- **Менять чужие feature-ветки** или мерзить их без явного запроса пользователя.

## Эскалации

Список случаев, когда autonomous mode останавливается и обращается к пользователю:

| Триггер | Что делать |
|---|---|
| 3-й раунд того же класса проблем у `code-reviewer` | Спросить пользователя «как поступить» с конкретным file:line и 2-3 вариантами |
| 3-й раунд падения того же теста у `test-runner` | Спросить «бизнес-логика верна или тест неправильный» с file:line |
| Sev1 уязвимость, которая не лечится за 2 раунда | Остановиться, спросить «принимаем риск, фиксим иначе, отменяем фичу» |
| Stop hook чеклист не зеленеет после 2 итераций | Доложить какие пункты красные, спросить «продолжаем или ручной разбор» |
| Принципиальное противоречие плана и реальности кода | Остановиться, описать противоречие, предложить варианты, ждать ответа |
| MCP / внешняя зависимость недоступна | Доложить, ждать ответа (autonomous mode не покрывает офлайн-режим) |

Эскалация — **не провал режима**. Это нормальный механизм безопасности: лучше один разумный вопрос, чем 50 неверных правок.

## Включение

### Один проект — постоянно

В `AGENTS.md` §0 (заголовочный блок) добавь строку:

```markdown
**Фаза:** ✅ `stack: <type>` · 🤖 `autonomous_mode: enabled`
```

Без строки `autonomous_mode: enabled` методология работает как раньше (single-agent, без three-gate review, без front-loaded clarification — обычный диалог).

### Разовый прогон без флага

Скажи AI: «прогони эту фичу в autonomous mode» или вызови `/full-ahead --autonomous`. Применится только к текущему циклу.

### Готовность проекта

Перед включением проверь:

- Phase 1+ (есть код, есть `local-ci.sh`).
- `code-reviewer`, `test-runner`, `security-auditor` лежат в `.claude/agents/` (для Claude Code).
- `scripts/stop-checklist.sh` существует и исполняемый.
- В `.claude/settings.json` зарегистрирован Stop hook.

`/doctor` под `phase-2-feature` это всё проверит.

## Цена

По данным индустрии (Anthropic 2026 Trends Report, ksred, CloudZero):

- **Базовый режим:** 1× токенов.
- **Autonomous mode на средней фиче:** 1.5–3× (три subagent-а проходят по diff, не по всему коду; модель `inherit` сохраняет prompt cache).
- **Worst case** (длинный цикл с эскалациями): до 5× — но эскалация остановит раньше.

На Claude Max 5× ($100/мес) — комфортно для ежедневного использования. На Claude Pro ($20/мес) — выжрет лимит за 2-3 фичи в день; не рекомендуется как режим по умолчанию.

## Совместимость с другими AI

Autonomous mode полноценно работает **только в Claude Code** — нативные subagent-ы есть только там (на дату 0.3.0).

- **Gemini CLI** — нативные subagent-ы есть, но требуется отдельная папка `.gemini/agents/` (не входит в seed 0.3.0, возможный TODO).
- **Codex CLI** — нативные subagent-ы есть в TOML, требуется конвертер (не входит в seed 0.3.0).
- **Cursor / Aider / прочие** — autonomous mode деградирует в обычный single-agent: AI читает [`AGENTS.md`](../AGENTS.md) и таблицу триггеров, видит флаг `autonomous_mode: enabled`, играет роли последовательно в одном контексте. Три gate-проверки выполняются как промпт-секции, без изоляции контекста.

## Как `/autonomous` команда работает на старте

Когда пользователь говорит `/autonomous` (или «включи autonomous mode»):

1. Проверь `AGENTS.md` §0: уже включён или нет.
2. Прогони `/doctor` под `phase-2-feature` — убедись, что есть всё нужное.
3. Если каких-то компонентов нет — сообщи, что именно (например, «отсутствует `scripts/stop-checklist.sh`», «не зарегистрирован Stop hook», «`.claude/agents/` пуст»).
4. Спроси: «включаем постоянно (правим AGENTS.md §0) или используем разово?»
5. Если постоянно — впиши `autonomous_mode: enabled` в `AGENTS.md` §0 (после `stack: <type>`).
6. Доложи: «autonomous mode включён. Следующий `/plan` будет с front-loaded clarification, следующий `/full-ahead` запустит three-gate review».

## Связки

- [plan playbook](plan.md) — Шаг 2 (front-loaded clarification), Шаг 3 (критерий приёмки)
- [full-ahead playbook](full-ahead.md) — Шаг 4 (three-gate review), Шаг 5 (Stop hook)
- [save-all playbook](save-all.md) — финальный коммит в autonomous loop
- [release playbook](release.md) — `security-auditor` всегда запускается перед `/release`
- [.claude/agents/code-reviewer.md](../.claude/agents/code-reviewer.md)
- [.claude/agents/test-runner.md](../.claude/agents/test-runner.md)
- [.claude/agents/security-auditor.md](../.claude/agents/security-auditor.md)
- [scripts/stop-checklist.sh](../scripts/stop-checklist.sh)
- [../docs/adr/20260520-1700-autonomous-mode-with-readonly-subagents.md](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260520-1700-autonomous-mode-with-readonly-subagents.md) — ADR с обоснованием
- [../AGENTS.md](../AGENTS.md) §0 — флаг `autonomous_mode: enabled`
