#!/usr/bin/env bash
# Stop hook: Claude가 응답을 끝내려 할 때 lint/정적분석을 돌리고, 실패하면 종료를 막는다.
#
# - Kotlin/Java/Gradle 파일 변경이 없으면 건너뛴다.
# - 실패 시 exit 2 + stderr → Claude가 오류를 받아 수정을 이어간다.
# - 같은 세션에서 MAX_BLOCKS번 막은 뒤에는 막지 않고 경고만 남긴다 (무한 루프 방지).
#
# 실행할 명령은 .claude/settings.json 의 env.CLAUDE_QUALITY_GATE_CMD 로 바꾼다.
set -uo pipefail

GATE_CMD="${CLAUDE_QUALITY_GATE_CMD:-./gradlew --quiet ktlintCheck detekt}"
MAX_BLOCKS="${CLAUDE_QUALITY_GATE_MAX_BLOCKS:-3}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

input="$(cat)"
session_id="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
counter_file="${TMPDIR:-/tmp}/claude-quality-gate-${session_id:-unknown}"

cd "$PROJECT_DIR" || exit 0

# 변경된 소스가 없으면 검사하지 않는다 (staged, unstaged, untracked 모두 포함)
changed="$( { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } \
  | grep -E '\.(kt|kts|java)$' || true)"
if [ -z "$changed" ]; then
  rm -f "$counter_file"
  exit 0
fi

output="$(eval "$GATE_CMD" 2>&1)"
status=$?

if [ "$status" -eq 0 ]; then
  rm -f "$counter_file"
  exit 0
fi

blocks="$(cat "$counter_file" 2>/dev/null || echo 0)"
blocks=$((blocks + 1))
echo "$blocks" > "$counter_file"

if [ "$blocks" -gt "$MAX_BLOCKS" ]; then
  rm -f "$counter_file"
  echo "quality-gate: ${MAX_BLOCKS}회 수정 후에도 실패. 더 막지 않습니다. 남은 문제를 사용자에게 보고하세요." >&2
  printf '%s\n' "$output" | tail -n 40 >&2
  exit 0
fi

{
  echo "quality-gate 실패 (${blocks}/${MAX_BLOCKS}): \`${GATE_CMD}\` exit ${status}"
  echo "아래 문제를 고친 뒤 다시 마무리하세요. 규칙을 끄거나 suppress 하지 말고 코드를 고치세요."
  echo "---"
  printf '%s\n' "$output" | tail -n 80
} >&2
exit 2
