---
name: sdd-plan
description: spec-kit + gstack 워크플로우의 플래닝 단계. /speckit-plan으로 plan.md를 만들고, gstack의 /plan-eng-review로 검증해 지적 사항을 plan.md에 반영한 뒤, /speckit-tasks와 /speckit-analyze로 마무리한다. "설계하자", "구현 계획 세워줘", "plan 리뷰해줘", "작업 목록 뽑아줘" 같은 요청에 사용한다.
argument-hint: "[기술 스택이나 설계 제약]"
allowed-tools: Read, Grep, Glob, Skill
---

# SDD 2단계: 플래닝

산출물은 `specs/<기능>/plan.md`와 `tasks.md`다.

## 탐색

1. `~/.claude/skills/sdd-flow/scripts/status.sh`를 실행한다. `spec.md`가 없거나 NEEDS CLARIFICATION이 남아 있으면 `/sdd-spec`으로 돌아간다.
2. 출력의 "기능 폴더" 경로를 기억한다. 이후 gstack 스킬에 이 경로를 명시해야 한다.
3. 프로젝트의 CLAUDE.md와 기존 코드 구조를 확인한다. Spring Boot + Kotlin 프로젝트면 `spring-kotlin-blueprint` 스킬에서 해당 주제의 참조를 읽고 구조를 plan 입력에 반영한다.

## 실행

1. **`/speckit-plan <기술 스택과 설계 제약>`.** 프로젝트의 아키텍처 규칙(계층, 의존 방향, 테스트 방식)을 입력에 넣는다.
2. **`/plan-eng-review`.** 대상을 반드시 경로로 지정한다: "`specs/<기능>/plan.md`를 리뷰해줘. 요구사항은 같은 폴더의 `spec.md`다." gstack 리뷰는 원래 자체 디자인 문서를 찾으므로, 경로를 주지 않으면 엉뚱한 대상을 본다.
3. **지적 사항을 `plan.md`에 반영한다.** 받아들인 것은 본문을 고치고, 맨 끝에 `## Eng Review` 섹션을 두어 날짜, 반영한 항목, 반영하지 않은 항목과 이유를 적는다. 요구사항 자체가 바뀌는 지적이면 `plan.md`가 아니라 `spec.md`를 먼저 고치고 `/speckit-plan`을 다시 실행한다.
4. **(선택) 큰 기능일 때만.** 범위와 방향을 다시 보려면 `/plan-ceo-review`, 화면이 있으면 `/plan-design-review`, 요구사항 품질을 점검하려면 `/speckit-checklist`. 대상 경로를 같은 방식으로 지정한다.
5. **`/speckit-tasks`.** 리뷰 반영이 끝난 뒤에 실행한다. 먼저 만들면 리뷰로 바뀐 설계와 작업 목록이 어긋난다.
6. **`/speckit-analyze`.** `spec.md`, `plan.md`, `tasks.md` 사이의 불일치를 찾는다. CRITICAL 항목은 해당 산출물을 고친 뒤 다시 실행한다.

## 검증

1. `status.sh`를 다시 실행한다. "eng 리뷰 반영: 예"와 "tasks.md 있음"이 나와야 한다.
2. `/speckit-analyze` 결과에 CRITICAL 항목이 없어야 한다.
3. `tasks.md`에 테스트 작업이 포함되어 있는지 확인한다. 없으면 `/speckit-tasks`를 "테스트 작업 포함"으로 다시 실행한다.

## 하지 말 것

- gstack의 `/autoplan`으로 계획을 만들지 않는다.
- 리뷰 지적을 대화에만 남기지 않는다. `plan.md`에 없으면 구현 단계에서 사라진다.

## 다음

`/sdd-build`
