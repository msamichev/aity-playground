#!/usr/bin/env bash
#
# pre-push-guard.sh — git pre-push hook.
#
# Этот hook работает НЕЗАВИСИМО от AI. Защищает от:
#   - force-push в main / master
#   - push, когда рабочая директория грязная (опасно — закоммитятся непроверенные изменения)
#   - push, когда .claude/settings.json расходится с источником
#
# Регистрируется через .pre-commit-config.yaml (stages: [pre-push]).
#
# Внимание: pre-commit framework передаёт хукам аргументы git pre-push hook
# (remote, url) через stdin. Мы их игнорируем — нам важно факт push.
#

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

ERRORS=0

# -----------------------------------------------------------------------------
# 1. Текущая ветка
# -----------------------------------------------------------------------------

CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")"

# -----------------------------------------------------------------------------
# 2. Проверка: force-push в main/master
# -----------------------------------------------------------------------------
#
# pre-commit framework сам не знает, был ли --force; но мы можем посмотреть
# на параметры git push через env:
#   PRE_COMMIT_FROM_REF / PRE_COMMIT_TO_REF
# или через stdin от git: <local ref> <local sha> <remote ref> <remote sha>
#
# Самый надёжный способ — проверить, что remote-ветка является предком local-ветки
# (т.е. push fast-forward). Если нет — это force-push.

if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  REMOTE_REF="refs/remotes/origin/$CURRENT_BRANCH"
  if git rev-parse --verify "$REMOTE_REF" >/dev/null 2>&1; then
    REMOTE_SHA="$(git rev-parse "$REMOTE_REF")"
    LOCAL_SHA="$(git rev-parse HEAD)"

    # 2a. Force-push в main/master — запрещён всегда (не обходится env-флагом).
    if ! git merge-base --is-ancestor "$REMOTE_SHA" "$LOCAL_SHA" 2>/dev/null; then
      echo "✗ Force-push в $CURRENT_BRANCH запрещён." >&2
      echo "  Локальный HEAD ($LOCAL_SHA) не является потомком origin/$CURRENT_BRANCH ($REMOTE_SHA)." >&2
      echo "  В team+ai $CURRENT_BRANCH защищён и теги релизов не переписываются." >&2
      ERRORS=$((ERRORS + 1))
    fi

    # 2b. Любой push в main/master — только релиз-инженером с явным env-флагом.
    if [[ "${PRE_PUSH_GUARD_ALLOW_MAIN:-0}" != "1" ]]; then
      echo "✗ Push в $CURRENT_BRANCH запрещён." >&2
      echo "  В team+ai все изменения в $CURRENT_BRANCH идут только через MR (см. AGENTS.md §4.3)." >&2
      echo "  Создай feature-ветку: git checkout -b feature/<ID>-<slug>; /open-mr." >&2
      echo "  Исключение для релиз-инженера (push release-коммита + тега):" >&2
      echo "    PRE_PUSH_GUARD_ALLOW_MAIN=1 git push origin $CURRENT_BRANCH" >&2
      echo "    PRE_PUSH_GUARD_ALLOW_MAIN=1 git push origin vX.Y.Z" >&2
      ERRORS=$((ERRORS + 1))
    fi
  else
    # 2c. Origin не имеет $CURRENT_BRANCH — это первый push при init-project.
    # Разрешаем без env-флага (это однократный bootstrap репозитория).
    echo "ℹ origin/$CURRENT_BRANCH не существует — это первый push (bootstrap)." >&2
    echo "  После этого push не забудь включить branch protection на $CURRENT_BRANCH в GitLab." >&2
  fi
fi

# -----------------------------------------------------------------------------
# 3. Проверка: рабочая директория чистая
# -----------------------------------------------------------------------------
#
# Push с грязной рабочей директорией обычно означает: «забыл что-то закоммитить»
# или «закоммитил половину». Это часто приводит к сломанному main.

if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  echo "✗ Рабочая директория не чистая." >&2
  echo "  Незакоммиченные или непроиндексированные изменения:" >&2
  git status --short | sed 's/^/    /' >&2
  echo "  Закоммить или спрячь (git stash) перед push." >&2
  ERRORS=$((ERRORS + 1))
fi

# -----------------------------------------------------------------------------
# 4. Проверка: .claude/settings.json синхронизирован с источником
# -----------------------------------------------------------------------------

if [[ -x "$REPO_ROOT/scripts/gen-claude-deny.sh" ]]; then
  if ! "$REPO_ROOT/scripts/gen-claude-deny.sh" --check >/dev/null 2>&1; then
    echo "✗ .claude/settings.json расходится с security/dangerous-commands.md" >&2
    echo "  Запусти: scripts/gen-claude-deny.sh" >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# -----------------------------------------------------------------------------
# Финал
# -----------------------------------------------------------------------------

if [[ $ERRORS -gt 0 ]]; then
  echo "" >&2
  echo "Push заблокирован: $ERRORS ошибок." >&2
  echo "Чтобы обойти (НЕ рекомендуется): git push --no-verify" >&2
  exit 1
fi

exit 0
