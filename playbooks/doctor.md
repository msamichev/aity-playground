# Doctor Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/doctor` или фразы «проверь окружение», «что у меня установлено», «health check».
> **Тонкая обёртка для Claude Code:** [.claude/skills/doctor/SKILL.md](../.claude/skills/doctor/SKILL.md).

---

## Что делает

Главная команда пред-фазной проверки. Определяет текущую фазу проекта, читает каталоги [`.claude/expected-tools.md`](../.claude/expected-tools.md) и [`.claude/recommended-skills.md`](../.claude/recommended-skills.md), сопоставляет с установленным окружением и выдаёт **единый отчёт**:

- что установлено / отсутствует среди ожидаемых CLI, MCP-серверов, runtimes;
- какие skills уже стоят;
- какие skills и инструменты рекомендуются под **текущую фазу**;
- какие установленные сущности **конфликтуют** между собой;
- команды установки и предупреждения.

**Ничего не устанавливает автоматически.** Решение — за пользователем.

## Когда запускать

- **Один раз в конце `/init-project`** — автоматически.
- **В конце `/adopt-stack`** — автоматически (вместе с `/skills-suggest`).
- **Перед каждой фазой** — рекомендованный ручной запуск, особенно перед `/adopt-architecture`, `/adopt-stack`, новой фичей в Steady state.
- **Вручную в любой момент** — по команде `/doctor`.

## Алгоритм

### Шаг 0. Определи текущую фазу проекта

Используй эвристику по наблюдаемому состоянию:

| Сигнал | Что это значит |
|---|---|
| `AGENTS.md §0` содержит «🚧 stack: not yet chosen» И `docs/architecture/overview.md` отсутствует или содержит только шаблон | **phase-0** (Discovery) |
| Метка «🚧 stack: not yet chosen» И `docs/architecture/overview.md` содержит реальный контент (есть mermaid-блок и наполнение подпапок `core/`, `data/`, ...) | **phase-0.5** (Architecture) |
| `AGENTS.md §0` содержит «✅ stack: <type>» И отсутствует активный план в `plans/` | **phase-1** (Stack scaffolding только что сделан, кода ещё нет / минимальный) |
| Метка «✅ stack: <type>» И в `plans/` есть план с незавершёнными `[ ]`-пунктами (исключая `plans/TEMPLATE.md`, `plans/README.md` и недельные планы в `plans/weeks/`) | **phase-2-feature** (фича в работе) |
| Метка «✅ stack: <type>» И нет активных планов | **phase-2** (между фичами) |

Если эвристика даёт двойственный ответ — задай пользователю **один** уточняющий вопрос с вариантами:

> Не могу однозначно определить фазу. Это:
> - (a) Discovery (только idea, нет архитектуры)
> - (b) Architecture (idea готова, выбираем архитектурные паттерны)
> - (c) Stack (стек выбран, кода нет)
> - (d) Steady state — между фичами
> - (e) Steady state — работаем над конкретной фичей

Запиши определённую фазу в шапку отчёта.

### Шаг 1. Прочитай оба каталога

- [`.claude/expected-tools.md`](../.claude/expected-tools.md) — CLI, MCP, runtimes. Маркеры: `expected-required`, `expected-recommended`, `expected-contextual`, `expected-mcp`, `expected-phase-0`, `expected-phase-0.5`, `expected-phase-1`, `expected-phase-2-feature`.
- [`.claude/recommended-skills.md`](../.claude/recommended-skills.md) — Claude Code skills. Группировка по применимости (универсальные / фронт / React / RN / документы / тестирование UI / MCP-builder).

Парсинг inline-полей в каждом bullet/skill:
- `**Why:** ...` — попадёт в отчёт.
- `**Conflicts with:** X, Y` — список конфликтующих имён.
- `**Replaces:** Z` — текущий замещает Z.
- `**Применимо в фазах:** ...` (только в `recommended-skills.md`) — фильтр.

Парсер должен быть терпимым: отсутствующие поля не считаются ошибкой.

### Шаг 2. Отфильтруй по фазе

**Из `expected-tools.md` показываем:**

| Категория | Когда показываем |
|---|---|
| `required` | всегда |
| `recommended` | всегда |
| `contextual` | если непустой (заполняется на `/adopt-stack`) |
| `mcp` | всегда (как опциональный раздел) |
| `phase-X` | только если `X` совпадает с текущей фазой |

**Из `recommended-skills.md` показываем:**

- Skills, у которых `Применимо в фазах:` включает текущую фазу.
- Skills из универсального раздела (без явной фазы) показываем для всех фаз ≥ 0.5.
- Skills, требующие конкретного стека (фронт / React / RN / документы) — показываем только если контекст этому соответствует (проверяй наличие папок `frontend/`, `src/components/`, наличие React в стеке `AGENTS.md §1`).

### Шаг 3. Проверь установленность

Для каждого элемента из отфильтрованного списка:

**CLI:**
```bash
command -v <tool>
```

**Runtime (с проверкой версии):**
```bash
node --version    # сравни с минимумом из каталога
python3 --version
```

**MCP-сервер:**
```bash
claude mcp list 2>/dev/null | grep <name>
```

**Skill (Claude Code plugin):**
```bash
claude plugin list 2>/dev/null | grep <name>
# плюс проверь папки:
ls ~/.claude/skills/<name>/ 2>/dev/null   # global
ls .claude/skills/<name>/ 2>/dev/null     # project-level
ls ~/.claude/plugins/cache/<name>* 2>/dev/null
```

Помечай каждый элемент: `installed` / `missing` / `unknown` (если способ проверки не сработал).

### Шаг 3.1. Проверь активацию git-хуков pre-commit

Самая частая silent-проблема: бинарь `pre-commit` установлен, но `pre-commit install` не выполнен — хуки не активированы, и проверки уходят в тишину. Поэтому если `pre-commit` помечен как `installed` — отдельно проверь, что **все три** типа хуков активированы:

```bash
HOOKS_DIR="$(git rev-parse --git-path hooks 2>/dev/null)"
for h in pre-commit commit-msg pre-push; do
  if [[ -f "$HOOKS_DIR/$h" ]] && grep -q "generated by pre-commit" "$HOOKS_DIR/$h"; then
    echo "$h: active"
  elif [[ -f "$HOOKS_DIR/$h" ]]; then
    echo "$h: present-but-not-pre-commit"   # чужой хук / sample
  else
    echo "$h: missing"
  fi
done
```

Маппинг на статусы:

| Состояние | Что значит | Что показать в отчёте |
|---|---|---|
| Все три `active` | Хуки активированы корректно | Не показывать ничего (тихо ок). |
| Хотя бы один `missing` | Хук не активирован. **Это и есть та silent-дыра.** | В отчёте отдельный раздел «⚠️ pre-commit hooks не активированы» с тройной командой `pre-commit install ...` (см. Шаг 6). |
| Хотя бы один `present-but-not-pre-commit` | Стоит чужой хук (например, husky из старого проекта). | Предупреждение: «`.git/hooks/<имя>` существует, но не от pre-commit framework. Возможно, конфликт с другим инструментом — проверь содержимое.» |

Если бинарь `pre-commit` сам по себе `missing` — этот шаг пропускается (нечего проверять, и так уже понятно).

**Эвристика «generated by pre-commit»:** маркер появляется в первой строке хука pre-commit framework начиная с версии 1.0. Если маркер не найден, но файл содержит `pre-commit run`, — тоже считай `active` (на случай нестандартных инсталляций).

### Шаг 4. Найди конфликты

Пройди по элементам со статусом `installed`. Для каждого с непустым `Conflicts with:`:

- Если **хотя бы один** из перечисленных конфликтующих тоже `installed` — это **конфликт**, попадает в раздел отчёта «⚠️ Конфликты».
- Если установлен **сам элемент** и в его описании `Replaces: X`, а `X` тоже `installed` — это **избыточность**, попадает в «⚠️ Конфликты» с пояснением «X можно удалить, заменяется на <текущий>».

Конфликты — рекомендация, не блокировка.

### Шаг 5. Сформируй единый отчёт

**Прочитай версию методологии:** `cat VERSION 2>/dev/null` (файл в корне проекта). Если файла нет — пометь «версия не зафиксирована» (старая копия методологии или ручная правка). Это первая строка шапки.

Структура (адаптируй под пустоту секций — пустые скрывай):

```
🔍 Окружение для <project-name>
Методология: solo+ai v<X.Y.Z>    (или: «версия не зафиксирована — см. VERSION»)
Фаза: <phase-id> (<one-line описание>)

Сводка:
  Required:                      ✓ N / ✗ M
  Recommended:                   ✓ N / ✗ M
  Contextual (под стек):         ✓ N / ✗ M       (или: пусто — заполнится на /adopt-stack)
  Под фазу <X>:                  ✓ N / ✗ M       (если у фазы есть свои инструменты)
  MCP-серверы установлены:       N (имена: ...)
  Skills установлены:            N (имена: ...)

⚠️ Конфликты:
  - <X> и <Y> установлены одновременно. <X описание>. Оставь одно — рекомендуем <которое> (см. <ссылка-на-ADR-или-METHODOLOGY>).
  (раздел скрыт если конфликтов нет)

📋 Отсутствует и стоит поставить:
  ✗ <tool>
      Why: <из каталога>
      Install: <команда из каталога>
      Conflicts with: <если есть>
      Категория: required | recommended | contextual | phase-<X> | mcp

📦 Рекомендуемые skills под фазу <X>:
  - <skill-name> (<источник>)
      Why: <короткое описание из каталога>
      Install: <команда>
      Conflicts with: <если есть>

  (показываем максимум 3-4 skills; если рекомендаций больше — пишем
   «ещё N кандидатов, подробнее — /skills-suggest»)

ℹ️ Дополнительно:
  - Bundled skills всегда доступны: /simplify, /batch, /debug, /loop, /claude-api
  - Подробный обзор только по skills: /skills-suggest
  - Каталоги: .claude/expected-tools.md, .claude/recommended-skills.md
```

### Шаг 6. Если есть критические пропуски в `required` — выдели жирным

Если из секции `required` отсутствует хотя бы один пункт:

> ⚠️ Без `<tool>` следующие команды не будут работать: `<список команд>`.
> Установи прежде чем продолжать. Команда установки выше.

Не блокируй сессию — пользователь сам решит.

**Отдельный случай: бинарь `pre-commit` есть, но хуки не активированы** (см. Шаг 3.1). Это не пропуск из `required`, а silent-дыра, и её надо подсветить явно:

> ⚠️ `pre-commit` установлен, но git-хуки **не активированы**: `<список missing-хуков>`.
> Это значит, что коммиты уходят без проверок (lint, secrets, conventional-commits, validate-links, pre-push-guard).
> Выполни:
> ```
> pre-commit install \
>   && pre-commit install --hook-type commit-msg \
>   && pre-commit install --hook-type pre-push
> ```
> Все три команды обязательны — каждая активирует свой stage.

### Шаг 7. Сохрани состояние пропуска (опционально)

Если пользователь увидел `/doctor`-отчёт и больше не хочет автозапусков — сохрани в `.claude/settings.local.json` (gitignored):

```json
{
  "doctorAcknowledged": true,
  "doctorLastRun": "2026-05-17T22:30:00Z",
  "doctorLastPhase": "phase-1"
}
```

**Эффект `doctorAcknowledged: true`:** автозапуски `/doctor` в конце `/init-project` и `/adopt-stack` пропускаются. **Ручной запуск через `/doctor` работает всегда** — он перезаписывает `doctorLastRun` и `doctorLastPhase`.

Если `doctorLastPhase` отличается от текущей определённой фазы — автозапуск **не пропускается** даже при `doctorAcknowledged: true` (потому что фаза сменилась — пользователю полезно увидеть новые рекомендации).

## Что НЕ делает

- **Не устанавливает ничего автоматически.** Только показывает команды установки.
- **Не падает на отсутствующих инструментах** — это диагностика, не контроль.
- **Не лезет в личные настройки** Claude Code за пределами `.claude/settings.local.json`.
- **Не дублирует `/skills-suggest`** — даёт компактный список под фазу; подробный разбор каждого skill'а — у `/skills-suggest`.
- **Не блокирует** при конфликтах — только предупреждает.

## Связки

- [.claude/expected-tools.md](../.claude/expected-tools.md) — каталог CLI/MCP/runtimes (источник правды)
- [.claude/recommended-skills.md](../.claude/recommended-skills.md) — каталог skills (источник правды)
- [METHODOLOGY.md](../METHODOLOGY.md) §3 — четыре фазы; §6 — таблица команд; §10 — MCP vs CLI
- [init-project playbook](init-project.md) — первый автозапуск (Шаг 9)
- [adopt-stack playbook](adopt-stack.md) — второй автозапуск (Шаг 11)
- [skills-suggest playbook](skills-suggest.md) — фокусированный разбор skills
