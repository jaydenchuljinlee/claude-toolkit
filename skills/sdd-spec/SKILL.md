---
name: sdd-spec
description: spec-kit + gstack 워크플로우의 요구사항 분석 단계. /speckit-specify로 spec.md를 만들고 /speckit-clarify로 모호한 부분을 없앤다. 아이디어 자체가 불확실하면 먼저 gstack의 /office-hours로 다듬는다. "요구사항 정리해줘", "스펙 작성", "이 기능 명세부터 쓰자" 같은 요청에 사용한다.
argument-hint: "<만들 기능 설명>"
allowed-tools: Read, Grep, Glob, Skill
---

# SDD 1단계: 요구사항 분석

산출물은 `specs/<기능>/spec.md`다.

## 탐색

1. `~/.claude/skills/sdd-flow/scripts/status.sh`를 실행한다. "다음 단계"가 `/sdd-setup`이면 Skill 도구로 `sdd-setup`을 먼저 호출한다.
2. 기능 설명이 없으면 사용자에게 무엇을 만들지 묻는다.

## 실행

1. **(선택) `/office-hours`.** "무엇을 만들지"가 불확실할 때만 쓴다. 요구사항이 이미 분명하면 건너뛴다. 결과로 나온 디자인 문서를 다음 단계의 입력으로 넘긴다.
2. **`/speckit-specify <기능 설명>`.** 무엇을, 왜 만드는지만 넘긴다. 기술 스택과 구현 방법은 넣지 않는다. 그건 plan 단계의 몫이다.
3. **`/speckit-clarify`.** 건너뛰지 않는다. 모호함이 남은 채로 설계하면 plan과 tasks 전체가 그 위에 쌓인다. 질문에는 사용자가 답한다. 대신 답하지 않는다.

## 검증

1. `status.sh`를 다시 실행한다. "미해결 NEEDS CLARIFICATION 0개"여야 한다. 남아 있으면 `/speckit-clarify`를 다시 실행한다.
2. `spec.md`를 읽고 확인한다.
   - 유저 스토리마다 "Acceptance Scenarios"가 있다. 이것이 QA 단계의 검증 대상이 된다.
   - 구현 세부 사항(프레임워크, 클래스명, 테이블명)이 들어 있지 않다.
3. 유저 스토리 목록과 우선순위를 사용자에게 한 줄씩 보여 주고 승인받는다.

## 다음

`/sdd-plan`
