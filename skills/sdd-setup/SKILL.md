---
name: sdd-setup
description: spec-kit + gstack 워크플로우를 시작할 수 있게 프로젝트를 준비한다. 빈 폴더나 spec-kit이 없는 프로젝트에서 git 저장소, .gitignore, spec-kit 초기화, CLAUDE.md, constitution, 초기 커밋까지 필요한 것만 채운다. 이미 있는 것은 건드리지 않는다. sdd-flow가 준비가 안 된 프로젝트를 만나면 호출하고, "sdd 세팅해줘", "빈 폴더에서 시작하자", "spec-kit 초기화" 같은 요청에도 사용한다.
argument-hint: "[기술 스택, 예: Spring Boot + Kotlin]"
allowed-tools: Read, Grep, Glob, Skill, Write, Edit, Bash(specify:*), Bash(git init:*), Bash(git status:*)
---

# SDD Setup

워크플로우에 필요한 최소한의 뼈대만 만든다. 애플리케이션 코드는 만들지 않는다. 프로젝트 구조와 빌드 설정은 `/sdd-plan`이 정하고 `/sdd-build`의 Setup 작업이 만든다.

## 탐색

1. 상태를 확인한다.
   ```bash
   ~/.claude/skills/sdd-flow/scripts/status.sh
   ```
   "준비 상태"의 각 줄에서 "없음"인 항목만 아래에서 처리한다. 전부 "있음"이면 할 일이 없다. 사용자에게 알리고 `/sdd-flow`로 돌아간다.
2. 도구가 없다고 나오면 멈추고 설치 명령을 알린다.
   - `specify CLI: 없음` → `uv tool install specify-cli`
   - `gstack: 없음` → `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup`
3. `git rev-parse --show-toplevel`을 실행한다. 결과가 현재 폴더가 아닌 상위 폴더면, 이 폴더는 다른 저장소 안에 있는 것이다. 여기서 새 저장소를 만들지, 상위 저장소를 그대로 쓸지 사용자에게 묻는다.
4. 기술 스택을 정한다. 인자로 받았으면 그것을 쓴다. 기존 코드가 있으면 빌드 파일에서 읽는다. 둘 다 없으면 사용자에게 한 번 묻는다. 정해지지 않았다고 답하면 "미정"으로 두고 진행한다.

## 계획

만들 것의 목록을 사용자에게 한 번 보여 주고 승인받는다. 프로젝트에 파일을 추가하고 커밋하는 작업이기 때문이다. 예:

```
만들 것: git 저장소, .gitignore, .specify/ 와 speckit 스킬, CLAUDE.md, constitution, 초기 커밋
건드리지 않는 것: (이미 있는 파일 목록)
```

## 실행

없는 항목만 순서대로 처리한다.

1. **git 저장소.** `git init`. 기본 브랜치 이름은 `main`으로 한다 (`git init -b main`).
2. **`.gitignore`.** 없을 때만 만든다. 공통 항목(`.env`, `*.pem`, `*.key`, `secrets.*`, `.DS_Store`, IDE 폴더)과 기술 스택의 빌드 산출물을 넣는다. 스택이 "미정"이면 공통 항목만 넣는다.
3. **spec-kit 초기화.**
   ```bash
   specify init --here --integration claude --script sh --force
   ```
   `.specify/`와 `.claude/skills/speckit-*`가 생긴다. `--force`는 비어 있지 않은 폴더에 합치기 위한 것이고, 기존 파일을 덮어쓰지 않는지 실행 후 `git status`로 확인한다.
4. **`CLAUDE.md`.** 없을 때만 만든다. 짧게 쓴다. 아래 항목만 넣고, 아직 모르는 것은 지어내지 않고 "`/sdd-plan` 이후 작성"이라고 적는다.
   - 기술 스택
   - 빌드와 테스트 명령
   - 워크플로우: "기능 개발은 `/sdd-flow`로 시작한다. 산출물은 `specs/<기능>/`에 있고 `/speckit-*` 스킬로만 고친다."

   이미 있으면 워크플로우 한 줄만 추가할지 사용자에게 묻는다.
5. **constitution.** `/speckit-*` 스킬이 목록에 보이지 않으면 세션을 다시 시작해야 한다. 그 경우 여기서 멈추고, 재시작 후 `/sdd-flow`를 다시 실행하라고 알린다. 보이면 `/speckit-constitution`을 실행한다.
   - 입력: CLAUDE.md의 규칙, 사용자가 말한 원칙.
   - Spring Boot + Kotlin이면 `spring-kotlin-blueprint` 스킬의 "옮기는 규칙"과 `references/layering.md`의 핵심 아이디어를 원칙의 출발점으로 제안한다.
   - 원칙은 사용자가 확정한다. 근거 없이 채우지 않는다.
6. **초기 커밋.** 리뷰 단계가 기준 브랜치와의 diff를 보므로 기준이 될 커밋이 필요하다. 커밋 전에 `git status`로 민감 파일(`.env`, `*.pem`, `*.key`, `secrets.*`)이 포함되지 않았는지 확인하고, 사용자에게 확인받은 뒤 `chore: SDD 워크플로우 초기 설정`으로 커밋한다.

## 검증

1. `status.sh`를 다시 실행한다. "준비 상태"가 전부 "있음"이고 "다음 단계"가 `/sdd-spec`이어야 한다.
2. `git status`가 깨끗하다.
3. 그렇지 않으면 무엇이 남았는지 사용자에게 알린다. 끝났다고 보고하지 않는다.

## 하지 말 것

- 애플리케이션 코드, 빌드 파일, 폴더 구조를 만들지 않는다. 스택이 정해졌어도 마찬가지다.
- 이미 있는 `.gitignore`, `CLAUDE.md`, `.specify/`를 덮어쓰지 않는다.
- 원격 저장소를 만들거나 푸시하지 않는다. 필요하면 사용자가 따로 요청한다.

## 다음

`/sdd-flow`로 돌아가 트랙을 고른다. 호출한 쪽이 `/sdd-flow`였으면 그 흐름을 이어 간다.
