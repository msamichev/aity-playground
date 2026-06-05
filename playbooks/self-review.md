# Self-Review Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Когда применяется:** **перед `/open-mr`** — в момент, когда автор открывает MR. Не перед каждым feature-checkpoint push. Не отдельный триггер, упоминается в [open-mr.md](open-mr.md), [full-ahead.md](full-ahead.md) и [AGENTS.md §5 п.10](../AGENTS.md).

---

7-пунктный смысловой чек-лист, который **читает автор MR** в момент `/open-mr` — глазами будущего ревьюера. Дополняет автоматику `scripts/ci-push.sh` и read-only subagent [`merge-coordinator`](../.claude/agents/merge-coordinator.md): они ловят механические и структурные ошибки, чек-лист ловит смысловые.

## Когда использовать

В момент `/open-mr` (после зелёного `scripts/ci-push.sh` и зелёного `merge-coordinator`-отчёта). **Не** перед каждым промежуточным push в feature-ветку — фича может быть ещё не готова, push в feature — это checkpoint, не финал.

В autonomous mode self-review встроен в [full-ahead.md](full-ahead.md) Шаг 6: если за push следует `/open-mr` — прочитать обязательно; если это просто checkpoint — пропустить.

## Self-review vs merge-coordinator

Они дополняют друг друга, не дублируют:

| | `merge-coordinator` (read-only subagent) | `self-review.md` (этот playbook) |
|---|---|---|
| Что проверяет | **Структурные** инварианты: rebased на main, нет коллизий timestamp в ADR, есть `changelogs/unreleased/<ID>.md`, в commit-message есть trailer `Refs: <ID>` | **Смысловые** инварианты: соответствие плану, отсутствие swallowed errors, secrets/PII в логах, обратная совместимость |
| Кто запускает | автоматически в `/open-mr` (Claude Code), либо вручную как gate | автор-человек (или AI докладывает человеку) |
| Можно ли пропустить | нет (блокер) | нет (правило в AGENTS.md §5 п.10), но не блокируется скриптом |

## Чек-лист (7 пунктов)

- [ ] **Изменение соответствует задаче** (план / ADR / тикет в трекере)? Если плана не было — стоит ли его сейчас задокументировать?
- [ ] **Контракт правильно понят** — входы, выходы, инварианты, граничные значения, обработка ошибок?
- [ ] **Нет дублирования** с существующим кодом — проверь имена соседних функций, утилит, хелперов, общих модулей команды?
- [ ] **Тесты адекватны бизнес-смыслу**, а не только покрытию — поломка кода в важном месте уронит тесты?
- [ ] **Нет «глотания» ошибок** (`catch (e) {}`, `except: pass`, swallowing `Result.Err`)?
- [ ] **Secrets / PII не утекают** в логи, response body, URL, error messages, аналитику, дамп переменных в ошибке?
- [ ] **Обратная совместимость** учтена (если фича публичная, меняет публичный API, или есть зависимые сервисы команды)?

## Что делать с результатами

- **Все пункты зелёные** → `/open-mr` (через [open-mr.md](open-mr.md)).
- **Один пункт красный** → почини, перепрогони `scripts/ci-push.sh`, перечитай чек-лист, потом `/open-mr`.
- **Несколько красных** → стоп, перечитай план / ADR. Возможно, фича не готова — лучше `/save` без MR и доделать, чем открыть MR, который вернётся «вернуть в работу».
- **Сомнение в формулировке** → один пункт, добавь в `## Открытые вопросы` плана или подними отдельным ADR. В описании MR указать, что именно остаётся открытым — это сигнал ревьюеру.

## Правила

- Чек-лист **обязателен перед `/open-mr`**: это правило AGENTS.md §5 п.10, но не блокируется скриптом — взрослая ответственность автора.
- В autonomous mode прохождение чек-листа фиксируется в финальном докладе пользователю.
- Если ловишь себя на «всё ок» больше 5 раз подряд без замедления — значит, листаешь формально. Перечитай вопросы вдумчиво либо предложи `/critic` для своего же MR.
- **Не превращай self-review в дублирование `merge-coordinator`.** Если subagent уже сказал «нет changelog-фрагмента» — это его поле, не лезь в чек-лист семёркой пунктов.

## Связки

- [open-mr.md](open-mr.md) — где self-review встроен в pre-MR гейт
- [full-ahead.md](full-ahead.md) — где self-review встроен в цикл (Шаг 6, опционально)
- [save-all.md](save-all.md) — push в feature-ветку (без self-review)
- [critic.md](critic.md) — более глубокая критика, если чек-лист стал формальностью
- [scripts/ci-push.sh](../scripts/ci-push.sh) — автоматическая часть pre-push гейта
- [scripts/ci-deep.sh](../scripts/ci-deep.sh) — opt-in локальные глубокие проверки (основное место — CI nightly)
- [.claude/agents/merge-coordinator.md](../.claude/agents/merge-coordinator.md) — read-only structural pre-MR gate
- [AGENTS.md §5 п.10](../AGENTS.md) — правило «перед `/open-mr` прочитан self-review»
- [https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1400-team-ai-ci-tiers-with-gitlab-nightly-deep.md) — ADR, обосновавший вынос self-review к моменту `/open-mr`
- [https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md](https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260518-1432-split-local-ci-into-tiers.md) — базовый ADR про разнесение local-ci
