# Save Playbook

> **Универсальная процедура.** Читается любым AI: Claude, Codex, DeepSeek, Minimax, Cursor, Gemini, Aider и т.п.
> **Триггер:** `/save` или соответствующая фраза на естественном языке (см. таблицу триггеров в [AGENTS.md](../AGENTS.md)).
> **Тонкая обёртка для Claude Code:** [.claude/skills/save/SKILL.md](../.claude/skills/save/SKILL.md).

---

Локальный коммит. **Без push.**

## Алгоритм

1. `git status` — посмотри что изменилось.
2. **Stage поимённо**, не `git add .`:
   - Прочитай diff каждого файла кратко.
   - Сгруппируй связанные файлы.
   - `git add <file1> <file2> ...` явно.
3. Запусти `scripts/validate-links.sh --changed` — должен быть зелёным.
4. Сгенерируй Conventional Commit message:
   - `feat(scope): ...` — новая фича
   - `fix(scope): ...` — баг
   - `refactor(scope): ...` — рефакторинг без поведенческих изменений
   - `docs(scope): ...` — только документация
   - `docs(adr): YYYYMMDD-HHmm <title>` — для нового ADR
   - `test(scope): ...` — только тесты
   - `chore(scope): ...` — инфра, конфиги
   - `ci(scope): ...` — CI-пайплайн
   - `build(scope): ...` — сборка, зависимости
   - `perf(scope): ...` — производительность
   - `style(scope): ...` — форматирование (редко — обычно автомат)
5. Subject: императив, без точки в конце, до 72 символов.
6. Body (опционально): почему, что именно, что осталось.
7. **Покажи commit message пользователю перед коммитом** — пусть подтвердит.
8. `git commit -F <message-file>`.

## Правила

- **Никогда** `git add .`, `git add -A`, `git add *`.
- **Никогда** `--no-verify` без явной причины — если хук падает, пиши follow-up.
- Если в коммит просится несколько несвязанных изменений — разбей на несколько коммитов.

## Что НЕ делает

- Не пушит. Push — отдельной командой `/save-all`.
- Не запускает полный CI — для этого `/full-ahead`.

## Связки

- [save-all playbook](save-all.md) — коммит + push
- [full-ahead playbook](full-ahead.md) — полный цикл проверок
- [AGENTS.md §4.3](../AGENTS.md#43-git) — конвенции Git
