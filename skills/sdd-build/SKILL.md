---
name: sdd-build
description: spec-kit + gstack 워크플로우의 개발 단계. /speckit-implement로 tasks.md를 유저 스토리 단위로 구현하고, 스토리마다 테스트를 실행한 뒤, /speckit-converge로 구현과 산출물이 일치할 때까지 반복한다. 범위 보호가 필요하면 gstack의 /freeze를 쓴다. "구현 시작", "tasks대로 개발해줘", "다음 스토리 구현" 같은 요청에 사용한다.
argument-hint: "[구현할 유저 스토리 번호]"
allowed-tools: Read, Grep, Glob, Skill
---

# SDD 3단계: 개발

산출물은 코드와 단위 테스트, 그리고 체크된 `tasks.md`다.

## 탐색

1. `~/.claude/skills/sdd-flow/scripts/status.sh`를 실행한다. `tasks.md`가 없으면 `/sdd-plan`으로 돌아간다.
2. `tasks.md`를 읽고 유저 스토리별 작업 묶음과 남은 작업을 파악한다.
3. 프로젝트의 테스트 실행 명령을 CLAUDE.md나 빌드 파일에서 확인한다.

## 실행

1. **(선택) `/freeze <디렉터리>`.** 이번 기능과 무관한 코드를 건드리면 안 될 때 편집 범위를 묶는다. 파괴적 명령 경고까지 필요하면 `/guard`. 끝나면 `/unfreeze`.
2. **`/speckit-implement`를 유저 스토리 단위로 실행한다.** 한 번에 전부 돌리지 않는다. 입력으로 범위를 지정한다: "Setup과 Foundational 단계, 그리고 User Story 1의 작업만 실행해줘." 다음 번에는 "User Story 2의 작업만"처럼 이어 간다.
3. **스토리 하나가 끝날 때마다 테스트를 실행한다.** 실패하면 로직을 고친다. Mock으로 덮어 통과시키지 않는다. 통과하면 변경 요약을 사용자에게 보여 주고 다음 스토리로 간다.
4. **모든 스토리가 끝나면 `/speckit-converge`.** 구현을 `spec.md`, `plan.md`, `tasks.md`와 대조해 빠진 작업을 `tasks.md`에 추가한다.
5. **"Converged"가 나올 때까지 2~4를 반복한다.** 추가된 작업이 있으면 `/speckit-implement`로 처리하고 다시 converge한다.

## 구현 중 문제가 생기면

- **버그를 만났다:** 이번 기능의 작업에서 생긴 것이면 그 자리에서 고친다. 기존 코드의 버그면 `/sdd-flow`의 버그 트랙으로 따로 처리한다.
- **스펙이 틀렸거나 빠진 걸 발견했다:** 코드로 우회하지 않는다. 멈추고 사용자에게 알린 뒤 `spec.md`를 고치고(`/speckit-clarify` 또는 `/speckit-specify`), `/speckit-plan`과 `/speckit-tasks`를 다시 맞춘다.

## 검증

1. `/speckit-converge`가 "Converged"를 보고했다.
2. `status.sh`에서 `tasks.md`의 "남음"이 0이다.
3. 전체 테스트(또는 이번 기능과 관련된 테스트 전부)가 통과한다. 실행한 명령과 결과를 사용자에게 그대로 보여 준다.

## 다음

`/sdd-review`
