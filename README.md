# Claude Toolkit

Claude 관련 자주 사용하는 스킬, 에이전트, 커맨드 등을 관리하는 레포지토리입니다.

## 구조

```
claude-toolkit/
├── skills/         # 재사용 가능한 스킬 모음
├── agents/         # 서브에이전트 정의
├── commands/       # 커스텀 커맨드
└── templates/      # 템플릿 파일
```

## 설치 방법

```bash
# 전역 커맨드로 사용
ln -s $(pwd)/commands/* ~/.claude/commands/

# 전역 에이전트로 사용
ln -s $(pwd)/agents/* ~/.claude/agents/

# 전역 스킬로 사용
ln -s $(pwd)/skills/* ~/.claude/skills/
```

## SDD 워크플로우 스킬 (`sdd-*`)

[spec-kit](https://github.com/github/spec-kit)이 산출물을 쓰고 [gstack](https://github.com/garrytan/gstack)이 검증하는 개발 워크플로우입니다. 두 도구의 공식 통합이 아니라 이 저장소에서 정한 조합입니다.

사전 설치:

```bash
uv tool install specify-cli
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

프로젝트 폴더에서 `/sdd-flow <만들 기능>`으로 시작합니다. 빈 폴더여도 됩니다.

| 스킬 | 단계 |
|---|---|
| `/sdd-flow` | 진입점. 현재 단계 확인, 트랙 선택, 버그 트랙 |
| `/sdd-setup` | 프로젝트 준비 (git, spec-kit, CLAUDE.md, constitution) |
| `/sdd-spec` | 요구사항 분석 |
| `/sdd-plan` | 플래닝과 설계 리뷰 |
| `/sdd-build` | 유저 스토리 단위 구현 |
| `/sdd-review` | 모델별 독립 리뷰어(`sdd-code-reviewer`, `sdd-spec-reviewer`)와 gstack 리뷰 |
| `/sdd-qa` | 인수 시나리오 기반 QA |

## `spring-kotlin-blueprint`

Spring Boot + Kotlin 프로젝트에서 [hhplus-ecommerce](https://github.com/jaydenchuljinlee/hhplus-ecommerce)를 본보기로 삼아, 작업 유형별로 어느 패키지를 읽고 어떻게 옮길지 안내합니다.

## 참고

- [Claude Code 공식 문서](https://code.claude.com/docs)
- [Best Practices](https://code.claude.com/docs/en/best-practices)
