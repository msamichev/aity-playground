#!/usr/bin/env bash
#
# dora-collect.sh — тонкий helper для сырых DORA-данных из git за период.
#
# Не пишет в файлы. Печатает на stdout сырые числа по Deployment Frequency
# и Lead Time (proxy). Change Failure Rate и MTTR заполняются вручную в
# retrospectives/YYYY-MM-DD-release-vX.Y.Z.md из incident tracker.
#
# Использование:
#   scripts/dora-collect.sh                  # с последнего тега vX.Y.Z до HEAD
#   scripts/dora-collect.sh <ref>            # с указанного ref до HEAD
#                                            # (ref может быть тегом, sha, датой)
#
# Примеры:
#   scripts/dora-collect.sh v0.4.0
#   scripts/dora-collect.sh "30.days.ago"
#   scripts/dora-collect.sh 2026-05-01
#
# См. ADR https://github.com/msamichev/methodology-ai/blob/main/docs/adr/20260522-1700-dora-four-keys-in-team-retro-and-solo-weekplan.md
#

# Это data-collection скрипт: он должен выдавать пустые/неполные результаты
# для репо без релизных тегов, а не валиться. Поэтому set -e и pipefail
# намеренно НЕ включены. Сохраняем -u для отлова опечаток в переменных.
set -u

# Аргумент или последний тег vX.Y.Z, или 30 дней назад
SINCE="${1:-$(git describe --tags --match 'v*' --abbrev=0 2>/dev/null || echo '30.days.ago')}"
TODAY=$(date +%Y-%m-%d)

# Самый старый коммит в диапазоне — для оценки длительности периода
OLDEST_COMMIT_DATE=$(git log "$SINCE..HEAD" --pretty=format:%cd --date=short 2>/dev/null | tail -1)
if [ -z "$OLDEST_COMMIT_DATE" ]; then
  OLDEST_COMMIT_DATE="(нет коммитов в диапазоне)"
fi

echo "===================================================================="
echo " DORA Four Keys — сырые данные из git"
echo " Период: с $SINCE по $TODAY"
echo " Самый старый коммит в диапазоне: $OLDEST_COMMIT_DATE"
echo "===================================================================="
echo

# --- 1. Deployment Frequency -----------------------------------------------
echo "1. DEPLOYMENT FREQUENCY"
echo
echo "   Релизных тегов (vX.Y.Z) за период:"
TAG_COUNT=$(git tag --sort=-creatordate --merged HEAD 2>/dev/null | grep -cE '^v[0-9]+\.[0-9]+\.[0-9]+$' 2>/dev/null)
TAG_COUNT=${TAG_COUNT:-0}
git tag --sort=-creatordate --merged HEAD \
  | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
  | head -10 \
  | while read -r tag; do
      tag_date=$(git log -1 --format=%cd --date=short "$tag" 2>/dev/null || echo "?")
      echo "     $tag_date  $tag"
    done
echo
echo "   Всего тегов: $TAG_COUNT"
echo "   Категория (примерно): "
if [ "$TAG_COUNT" -ge 30 ]; then
  echo "     ✓ multiple per day"
elif [ "$TAG_COUNT" -ge 7 ]; then
  echo "     ✓ daily"
elif [ "$TAG_COUNT" -ge 1 ]; then
  echo "     ✓ weekly или monthly (зависит от длины периода)"
else
  echo "     ✓ less than monthly"
fi
echo

# --- 2. Lead Time for Changes ---------------------------------------------
echo "2. LEAD TIME (proxy через squash-merge коммиты в main)"
echo
echo "   Squash-merge коммиты в main за период (первая колонка = дата merge):"
git log "$SINCE..HEAD" --merges --first-parent --pretty="format:%cd  %h  %s" --date=short 2>/dev/null \
  | head -20 \
  | sed 's/^/     /'
echo
echo "   Медиана Lead Time = ручной подсчёт:"
echo "     1. Найди feature-ветку для каждого squash-merge (по имени в %s)."
echo "     2. Найди время первого коммита в этой ветке: git log <feature-branch> --reverse | head"
echo "     3. Lead Time = время merge - время первого коммита."
echo "     4. Медиана 10-20 точек = впиши в retro."
echo

# --- 3. Change Failure Rate (proxy) ---------------------------------------
echo "3. CHANGE FAILURE RATE (proxy — заполнить вручную)"
echo
echo "   Прокси: PATCH-релизы (v*.*.X где X != 0) после MINOR/MAJOR за период."
PATCH_COUNT=$(git tag --sort=-creatordate --merged HEAD 2>/dev/null | grep -cE '^v[0-9]+\.[0-9]+\.[1-9][0-9]*$' 2>/dev/null)
PATCH_COUNT=${PATCH_COUNT:-0}
echo "   PATCH-тегов в системе всего: $PATCH_COUNT (из $TAG_COUNT релизных)"
if [ "$TAG_COUNT" -gt 0 ]; then
  CFR_PROXY=$(( PATCH_COUNT * 100 / TAG_COUNT ))
  echo "   Грубая прокси CFR: ${CFR_PROXY}%"
fi
echo
echo "   Лучше — из incident tracker:"
echo "     • Сколько релизов потребовали hotfix/rollback в 48ч после релиза?"
echo "     • Сколько релизов открыли P1/P2 инциденты?"
echo "     • CFR = (количество failure-релизов / общее количество релизов) * 100%"
echo

# --- 4. MTTR ---------------------------------------------------------------
echo "4. MEAN TIME TO RECOVER (заполнить вручную из incident tracker)"
echo
echo "   Если инцидентов не было — N/A."
echo "   Если были — медиана времени от появления инцидента до восстановления."
echo "   Источники: incident tracker (PagerDuty/Opsgenie/GitLab Incidents), Slack/MS Teams каналы."
echo

echo "===================================================================="
echo " Перепиши эти данные в retrospectives/$TODAY-release-vX.Y.Z.md"
echo " (секция «5. DORA Four Keys»). Тренд vs прошлой ретро — стрелка."
echo "===================================================================="
