---
name: sdd-flow
description: spec-kit(산출물 작성)과 gstack(검증)을 조합한 개발 워크플로우의 진입점. 지금 어느 단계인지 확인하고, 작업 크기에 맞는 트랙과 다음에 실행할 스킬을 정한다. 프로젝트에 spec-kit이 없으면 준비 절차도 안내한다. "스펙 기반으로 개발하자", "spec-kit이랑 gstack으로 진행", "다음에 뭐 해야 해", "이 기능 어떤 순서로 만들지" 같은 요청에 사용한다.
argument-hint: "[만들 기능 또는 고칠 버그 설명]"
allowed-tools: Read, Grep, Glob, Skill
---

# SDD Flow

요구사항 분석부터 QA까지를 spec-kit과 gstack으로 진행한다.

## 원칙

- **산출물은 spec-kit이 소유한다.** `spec.md`, `plan.md`, `tasks.md`는 `/speckit-*` 스킬로만 만들고 고친다.
- **gstack은 검증한다.** 산출물과 코드를 리뷰하고, 지적 사항은 spec-kit 산출물에 반영한다.
- **gstack의 `/autoplan`과 `/spec`은 쓰지 않는다.** spec-kit과 역할이 겹쳐 계획이 두 벌이 된다.
- **동작이 바뀌는 수정은 스펙을 먼저 고친다.** `/review`나 `/qa`가 코드를 고쳐서 동작이 달라졌으면 `spec.md`와 `tasks.md`도 같이 맞춘다.
- gstack 스킬에 spec-kit 파일을 넘기는 방식은 두 도구의 공식 통합이 아니다. 이 스킬들이 정한 조합이다.

## 1. 현재 상태 확인 (먼저 실행)

```bash
~/.claude/skills/sdd-flow/scripts/status.sh
```

출력의 "다음 단계"를 따른다.

## 2. 프로젝트 준비 (다음 단계가 `/sdd-setup`일 때)

빈 폴더이거나, git 저장소, spec-kit, CLAUDE.md, constitution 중 하나라도 없으면 `status.sh`가 `/sdd-setup`을 가리킨다.

1. Skill 도구로 `sdd-setup`을 호출한다. 사용자가 준 기능 설명에 기술 스택이 들어 있으면 인자로 넘긴다.
2. 끝나면 `status.sh`를 다시 실행한다. "다음 단계"가 `/sdd-spec`으로 바뀌었으면 아래 트랙 선택으로 이어 간다. 사용자가 처음에 준 기능 설명은 그대로 들고 간다.
3. `sdd-setup`이 세션 재시작이 필요하다며 멈췄으면, 재시작 후 `/sdd-flow`를 다시 실행하라고 알리고 멈춘다.

## 3. 트랙 선택

작업 크기에 맞는 트랙 하나를 고른다. 애매하면 사용자에게 묻는다.

| 트랙 | 언제 | 순서 |
|---|---|---|
| 버그 수정 | 기존 동작이 틀렸다 | 아래 "버그 트랙" |
| 중간 기능 | 요구사항이 분명한 기능 하나 | `/sdd-spec` → `/sdd-plan` → `/sdd-build` → `/sdd-review` → `/sdd-qa` |
| 큰 기능 | 요구사항이 모호하거나 여러 도메인에 걸친다 | 위와 같되 모든 선택 게이트를 켠다 |

큰 기능에서 켜는 선택 게이트: `/sdd-spec`의 `/office-hours`, `/sdd-plan`의 `/plan-ceo-review`와 `/speckit-checklist`, `/sdd-review`의 `/codex`와 `/cso`.

## 4. 버그 트랙

스펙 워크플로우를 거치지 않는다.

1. 프로젝트에 bug 확장이 없으면 한 번 설치한다: `specify extension add bug`
2. `/speckit-bug-assess "<증상>" slug=<짧은-이름>`
3. `/speckit-bug-fix slug=<짧은-이름>`
4. `/speckit-bug-test slug=<짧은-이름>`. 판정이 `verified`일 때만 고쳐진 것이다. `partial`이나 `failed`면 2번으로 돌아간다.
5. `/review`로 diff를 검토한다.

보고서는 `.specify/bugs/<짧은-이름>/`에 남는다.

## 5. 검증

단계를 하나 마칠 때마다 `status.sh`를 다시 실행한다. "다음 단계"가 바뀌지 않았으면 그 단계가 끝나지 않은 것이다. 사용자에게 무엇이 남았는지 알린다.
