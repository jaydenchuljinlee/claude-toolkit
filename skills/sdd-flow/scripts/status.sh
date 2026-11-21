#!/usr/bin/env bash
# spec-kit + gstack 조합 워크플로우의 현재 상태와 다음 단계를 출력한다. 읽기 전용.
# 사용: status.sh [프로젝트 경로]   (생략하면 현재 디렉터리)
set -u

cd "${1:-.}" || { echo "경로 없음: ${1:-.}"; exit 2; }
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 2
echo "프로젝트: $ROOT"

# 도구
ready=1
if command -v specify >/dev/null 2>&1; then
  echo "specify CLI: 있음 ($(specify --version 2>/dev/null | head -1))"
else
  echo "specify CLI: 없음"; ready=0
fi
GSTACK="$HOME/.claude/skills/gstack"
if [ -f "$GSTACK/VERSION" ]; then
  echo "gstack: 있음 ($(cat "$GSTACK/VERSION"))"
else
  echo "gstack: 없음"; ready=0
fi

# 준비 상태: 하나라도 없으면 /sdd-setup
echo "준비 상태:"
files="$(find . -mindepth 1 -maxdepth 1 ! -name .git | wc -l | tr -d ' ')"
[ "$files" -eq 0 ] && echo "  (빈 폴더)"

if git rev-parse --git-dir >/dev/null 2>&1; then
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "  git 저장소: 있음"
  else
    echo "  git 저장소: 있음 (커밋 없음)"; ready=0
  fi
else
  echo "  git 저장소: 없음"; ready=0
fi

if [ -d .specify ]; then
  skills="$(ls -d .claude/skills/speckit-* 2>/dev/null | wc -l | tr -d ' ')"
  bug="없음"; [ -d .claude/skills/speckit-bug-assess ] && bug="있음"
  echo "  spec-kit: 있음 (speckit 스킬 ${skills}개, bug 확장 ${bug})"
else
  echo "  spec-kit: 없음"; ready=0
fi

if [ -f CLAUDE.md ]; then echo "  CLAUDE.md: 있음"; else echo "  CLAUDE.md: 없음"; ready=0; fi

CONST=".specify/memory/constitution.md"
if [ -f "$CONST" ] && ! grep -q '\[PROJECT_NAME\]' "$CONST"; then
  echo "  constitution: 있음"
else
  echo "  constitution: 없음 (템플릿 상태)"; ready=0
fi

if [ "$ready" -eq 0 ]; then
  echo "다음 단계: /sdd-setup"
  exit 0
fi

# 진행 중인 기능 폴더: feature.json 우선, 없으면 specs/ 의 마지막 폴더
FEATURE=""
if [ -f .specify/feature.json ]; then
  FEATURE="$(sed -n 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .specify/feature.json | head -1)"
fi
if [ -z "$FEATURE" ] || [ ! -d "$FEATURE" ]; then
  FEATURE="$(ls -d specs/*/ 2>/dev/null | sort | tail -1)"
  FEATURE="${FEATURE%/}"
fi
if [ -z "$FEATURE" ] || [ ! -f "$FEATURE/spec.md" ]; then
  echo "기능 폴더: 없음"
  echo "다음 단계: /sdd-spec"
  exit 0
fi
echo "기능 폴더: $FEATURE"

count() { grep -c -- "$1" "$2" 2>/dev/null || true; }

unclear="$(count 'NEEDS CLARIFICATION' "$FEATURE/spec.md")"
echo "  spec.md   있음 (미해결 NEEDS CLARIFICATION ${unclear}개)"
if [ "$unclear" -gt 0 ]; then
  echo "다음 단계: /sdd-spec (clarify부터)"
  exit 0
fi

if [ ! -f "$FEATURE/plan.md" ]; then
  echo "  plan.md   없음"
  echo "다음 단계: /sdd-plan"
  exit 0
fi
reviewed="아니오"; grep -q '^## Eng Review' "$FEATURE/plan.md" && reviewed="예"
echo "  plan.md   있음 (eng 리뷰 반영: ${reviewed})"

if [ ! -f "$FEATURE/tasks.md" ]; then
  echo "  tasks.md  없음"
  echo "다음 단계: /sdd-plan (tasks부터)"
  exit 0
fi
todo="$(count '^- \[ \]' "$FEATURE/tasks.md")"
done_n="$(count '^- \[[xX]\]' "$FEATURE/tasks.md")"
echo "  tasks.md  있음 (완료 ${done_n}, 남음 ${todo})"

if [ "$todo" -gt 0 ]; then
  echo "다음 단계: /sdd-build"
else
  echo "다음 단계: /sdd-review, 그다음 /sdd-qa"
fi
