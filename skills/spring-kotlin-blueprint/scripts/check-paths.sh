#!/usr/bin/env bash
# 스킬 문서가 가리키는 본보기 경로(`MAIN/...`, `TEST/...`)가 실제로 있는지 확인한다.
# 사용: check-paths.sh [확인할 저장소 루트]   (생략하면 원격 main을 받아 와서 확인)
set -u

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAIN="src/main/kotlin/com/hhplus/ecommerce"
TEST="src/test/kotlin/com/hhplus/ecommerce"

if [ $# -ge 1 ]; then
  REPO="$1"
else
  REPO="$("$SKILL_DIR/scripts/fetch-blueprint.sh" | tail -1)" || exit 2
fi

if [ ! -d "$REPO/$MAIN" ]; then
  echo "본보기 저장소를 찾을 수 없음: $REPO"
  exit 2
fi

total=0
missing=0
while IFS= read -r ref; do
  case "$ref" in
    MAIN/*) path="$MAIN/${ref#MAIN/}" ;;
    TEST/*) path="$TEST/${ref#TEST/}" ;;
    *) continue ;;
  esac
  total=$((total + 1))
  if [ ! -e "$REPO/$path" ]; then
    echo "없음: $ref"
    missing=$((missing + 1))
  fi
done < <(grep -rhoE '`(MAIN|TEST)/[^` ]*`' "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references" | tr -d '`' | sort -u)

echo "확인: $REPO"
echo "경로 ${total}개 중 ${missing}개 없음"
[ "$missing" -eq 0 ]
