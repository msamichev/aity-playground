# Запрещённые команды

> **Единый источник правды** для всех AI и для git hooks.
> **Этот файл редактируется руками.**
> Производные (`.claude/settings.json`, и т.п.) генерируются скриптом `scripts/gen-claude-deny.sh` автоматически на pre-commit. Не редактируй их вручную.

---

## Как использовать

- **Для Claude Code:** правила автоматически попадают в `.claude/settings.json` через генератор.
- **Для других AI (Codex, Cursor, DeepSeek, Minimax, GLM, Aider и т.п.):** AI читает этот файл напрямую (через ссылку в `AGENTS.md §4.4 Безопасность`).
- **Для git и системы:** часть правил продублирована в `scripts/pre-push-guard.sh` — работает независимо от AI.

---

## Категория: deny (никогда не выполнять)

Это команды, которые **нельзя выполнять никогда**, даже если пользователь прямо просит. Если запрос требует чего-то из этого списка — отказывайся и предложи безопасную альтернативу.

<!-- claude-deny-start -->
- `Bash(rm -rf /*)` — уничтожение корня файловой системы
- `Bash(rm -rf ~/*)` — уничтожение домашней директории
- `Bash(rm -rf /)` — то же, более короткая форма
- `Bash(git push --force*)` — переписывание истории на удалённом репозитории (всюду)
- `Bash(git push -f*)` — то же, короткая форма
- `Bash(git push origin main*)` — прямой push в main запрещён; изменения только через MR
- `Bash(git push origin master*)` — то же для master
- `Bash(git push * main*)` — broad-form (любой remote)
- `Bash(git reset --hard*)` — потеря всех незакоммиченных изменений
- `Bash(git clean -fdx*)` — удаление всех неотслеживаемых файлов вместе с gitignored
- `Bash(git commit *--no-verify*)` — обход pre-commit хуков (валидация коммита)
- `Bash(git push *--no-verify*)` — обход pre-push хуков (force-push guard, push-to-main guard)
- `Bash(git tag -d v*)` — удаление release-тега (vX.Y.Z локально)
- `Bash(git push * --delete *v*)` — удаление release-тега на сервере
- `Bash(git push * :refs/tags/v*)` — то же, alternative syntax
- `Bash(git update-ref -d refs/tags/v*)` — низкоуровневое удаление release-тега
- `Bash(git tag -f v*)` — перезапись release-тега
- `Bash(git filter-branch*)` — массовое переписывание истории
- `Bash(git filter-repo*)` — то же, новый инструмент
- `Bash(git rebase -i*)` — interactive rebase: требует терминала, AI не должен запускать
- `Bash(curl * | sh*)` — выполнение неаудированного кода из сети
- `Bash(curl * | bash*)` — то же
- `Bash(curl * | sudo *)` — то же с повышением привилегий
- `Bash(wget * | sh*)` — то же через wget
- `Bash(wget * | bash*)` — то же
- `Bash(sudo *)` — повышение привилегий без явной необходимости
- `Bash(chmod 777*)` — мировые права на запись (security smell)
- `Bash(chmod -R 777*)` — рекурсивные мировые права
- `Bash(eval *)` — выполнение динамически собранной команды
- `Bash(dd if=*)` — низкоуровневая запись на блочное устройство
- `Bash(mkfs*)` — форматирование файловой системы
- `Bash(:(){:|:&};:)` — fork bomb
- `Read(.env)` — чтение файла с секретами целиком
- `Read(.env.*)` — другие env-файлы с секретами
- `Read(*.pem)` — приватные сертификаты
- `Read(*.key)` — ключи
- `Read(*.p12)` — keystores
- `Read(*.pfx)` — keystores
- `Read(id_rsa)` — SSH приватный ключ
- `Read(id_ed25519)` — SSH приватный ключ
- `Read(id_ecdsa)` — SSH приватный ключ
- `Read(~/.ssh/*_rsa)` — любые SSH приватники в home
- `Read(~/.aws/credentials)` — AWS credentials
- `Read(~/.kube/config)` — Kubernetes config с credentials
<!-- claude-deny-end -->

## Категория: ask (требует подтверждения)

Команды, которые **разрешены, но только с явным подтверждением пользователя** в чате. AI должен спросить «выполнить X?», дождаться `да`, только тогда запускать.

<!-- claude-ask-start -->
- `Bash(git push*)` — публикация в удалённый репозиторий
- `Bash(git push --force-with-lease*)` — допустим только в **свою** feature-ветку после rebase; всегда подтверждать
- `Bash(git reset*)` — может потерять изменения (любая форма reset)
- `Bash(git rebase*)` — переписывание локальной истории
- `Bash(git rebase origin/main*)` — обновление feature-ветки на свежий main (типовой шаг team+ai)
- `Bash(git merge*)` — локальный merge (в team+ai мерж в main делается через MR squash, не локально)
- `Bash(git checkout -- *)` — отказ от незакоммиченных правок в файлах
- `Bash(git tag*)` — создание тегов (vX.Y.Z делает /release с подтверждением)
- `Bash(rm *)` — удаление (любая форма rm)
- `Bash(rmdir *)` — удаление каталогов
- `Bash(npm publish*)` — публикация npm-пакета
- `Bash(cargo publish*)` — публикация crate
- `Bash(twine upload*)` — публикация Python-пакета
- `Bash(gh release create*)` — создание GitHub release
- `Bash(pip install*)` — установка зависимостей в окружение
- `Bash(npm install*)` — то же
- `Bash(brew install*)` — то же
- `Bash(apt-get install*)` — то же на системном уровне
- `Bash(docker run*)` — запуск контейнеров
- `Bash(docker rmi*)` — удаление образов
- `Bash(kubectl delete*)` — удаление ресурсов в k8s
- `Bash(terraform destroy*)` — уничтожение инфраструктуры
- `Bash(terraform apply*)` — изменение инфраструктуры
<!-- claude-ask-end -->

## Что AI должен делать с этим списком

1. **Перед любым `Bash(...)` или `Read(...)`** — мысленно сверить с этим списком.
2. **Если паттерн в deny** — отказаться и объяснить почему. Предложить альтернативу.
3. **Если паттерн в ask** — спросить разрешения в чате, дождаться явного `да`, только потом выполнять.
4. **Если паттерн не в списке, но опасный по сути** — не молчать, поднять вопрос (это правило важнее самого списка — список не полный).

### Известное ограничение Claude Code (deny-rule bypass)

В 2026 году Adversa AI зафиксировала, что Claude Code в некоторых сценариях может обойти `permissions.deny` при сложных составных командах (длинная цепочка `&&` / `||` или большое число subcommand'ов в одном вызове). В таких случаях клиент показывает пользователю prompt «не могу гарантировать safety-check, выполнить?» — это **последняя линия обороны, не пропускай этот prompt**.

Дополнительные слои защиты, работающие независимо от deny-list:
- **`scripts/pre-push-guard.sh`** — git pre-push hook, ловит force-push и расхождение `.claude/settings.json` с источником. Срабатывает даже если AI обошёл deny-list, потому что это уровень git, не клиента.
- **PreToolUse hooks Claude Code** (опционально) — bash-скрипт, перехватывающий `Bash/Edit/Write/Read` до выполнения. Используй для критичных production-проектов как ещё один слой к `permissions.deny`.
- **Sandbox** (см. ниже) — изолированный контейнер, где даже выполненная destructive команда не уносит хост.

---

## Категория: sensitive (никогда не показывать в выводе)

Файлы и команды, **результаты выполнения которых нельзя показывать в чате**, даже если их разрешено читать частично.

- Конкретные значения переменных в `.env` (даже если читаем через `grep` — не цитировать значение).
- Содержимое `~/.git-credentials`.
- Конкретные токены, ключи, пароли — если случайно увидел в коде или выводе команды.
- Личные данные (паспорта, телефоны, email-адреса клиентов).

Если случайно показал — сразу redact: замени значение на `***`, предупреди пользователя.

---

## Дополнительные меры безопасности (опциональные, настраиваются вне seed)

Эти меры **не управляются методологией**, но рекомендуются для production-репозиториев. Включи их под себя на уровне платформы:

### Branch protection на GitLab — обязательно для team+ai

В team+ai эти настройки **обязательны** для работы методологии (не опциональны). Применяются Maintainer'ом после первого push:

- **Protected branches** для `main`:
  - Allowed to push and merge: **No one** — прямой push запрещён всем.
  - Allowed to merge: Developers + Maintainers — через MR.
  - Allow force push: **Off**.
  - Require approval from code owners: **On** (если есть `CODEOWNERS`).
- **Protected tags** — паттерн `v*`, allowed to create: Maintainers. **Запрещено** удалять и переписывать release-теги.
- **Merge requests:**
  - Squash commits when merging: Encourage / Require.
  - Pipelines must succeed.
  - All threads must be resolved.
  - Delete source branch by default.
  - Prevent approval by author.
- **Merge request approvals:** минимум 1 approval от Developer+.
- **CI/CD:** production-секреты — Protected + Masked.

Без этого настройки методологии на сервере не enforce'ятся — pre-push hook можно обойти `--no-verify`, и тогда защиту держит только GitLab.

### Shell aliases на машине разработчика

Для параноиков — настроить в `~/.bashrc` / `~/.zshrc`:

```bash
alias rm='rm -i'                     # rm всегда с подтверждением
alias mv='mv -i'                     # то же для mv
alias cp='cp -i'                     # и для cp
```

### Sandbox для AI

Запускать Claude Code / Codex CLI / aider внутри Docker-контейнера с read-only mount всего кроме рабочей директории. Так даже `rm -rf /*` ничего не сломает в основной системе.

### Pre-receive hooks на сервере git

Если используется самохостинг (Gitea, GitLab self-hosted) — добавить pre-receive hook на запрет force-push и большим файлам. Это страховка от обхода `--no-verify`.

---

## Связки

- [AGENTS.md §4.4 Безопасность](../AGENTS.md#44-безопасность) — ссылка на этот файл для AI
- [scripts/gen-claude-deny.sh](../scripts/gen-claude-deny.sh) — генератор `.claude/settings.json` из этого файла
- [scripts/pre-push-guard.sh](../scripts/pre-push-guard.sh) — git pre-push hook (Слой 2)
- [METHODOLOGY.md §10 Совместимость](../METHODOLOGY.md#10-совместимость-с-другими-ai-и-ide) — как это работает с не-Claude AI
- [.claude/settings.json](../.claude/settings.json) — **АВТОГЕНЕРИРОВАН**, не редактировать
