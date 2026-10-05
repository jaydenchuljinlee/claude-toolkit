# Claude Toolkit

Claude Code에서 자주 쓰는 스킬, 에이전트, 커맨드, 프로젝트 템플릿을 관리하는 레포지토리입니다.

## 구조

```
claude-toolkit/
├── install.sh                 # global/ → ~/.claude 심볼릭 링크 설치
├── global/                    # 모든 프로젝트에 적용 (~/.claude 로 링크)
│   ├── CLAUDE.md              # 전역 지시문: 보안 · 맥락 추론 · 코딩 원칙 · 커밋 규칙
│   ├── skills/
│   │   ├── skill-authoring/                 # 스킬/커맨드/에이전트 작성 가이드
│   │   ├── verification-before-completion/  # 증거 없는 "완료" 주장 금지 (obra/superpowers, MIT)
│   │   ├── cover-letter-writer/             # 자소서 작성
│   │   ├── notion-page-organizer/
│   │   └── notion-page-review/
│   ├── output-styles/
│   │   └── attention-kind.md  # 결론부터, 짧게 답하는 스타일 (alexgreensh/attention-span, AGPL-3.0)
│   └── commands/              # git, study, study-save
├── licenses/                  # 서드파티 라이선스 원문
└── templates/
    └── spring-kotlin/         # 프로젝트에 복사해서 쓰는 설정
        ├── CLAUDE.md          # 프로젝트 지시문 템플릿
        └── .claude/
            ├── settings.json  # Stop hook 품질 게이트 (ktlint + detekt)
            ├── hooks/quality-gate.sh
            ├── commands/      # /implement, /spring-tdd
            └── agents/        # feature-planner, feature-implementer, test-runner, code-validator
```

### 나누는 기준

| 위치 | 넣는 것 | 예 |
|---|---|---|
| `global/` | 어떤 프로젝트에서도 같은 의미인 것 | 코딩 원칙, 검증 규칙, 개인 워크플로우 |
| `templates/<스택>/` | 특정 프로젝트 구조나 컨벤션에 묶인 것 | DDD 패키지 구조, Gradle 명령, 도메인 컨벤션 |

이름이 같을 때의 우선순위: 스킬/커맨드는 **전역이**, 서브에이전트는 **프로젝트가** 이깁니다. 그래서 프로젝트 전용 버전은 다른 이름을 씁니다 (예: `~/.claude`의 `tdd` 스킬과 겹치지 않도록 프로젝트용은 `spring-tdd`).

## 설치

### 전역 설정

```bash
./install.sh --dry-run   # 미리보기
./install.sh             # 설치. 기존 파일은 ~/.claude/backups/toolkit-<시각>/ 으로 이동
```

`global/`에 있는 항목만 `~/.claude`에 심볼릭 링크로 연결합니다. 링크된 항목은 레포를 수정하면 바로 반영됩니다. `~/.claude`에만 있고 레포에 없는 항목은 건드리지 않습니다.

### 프로젝트 템플릿

[templates/spring-kotlin/README.md](templates/spring-kotlin/README.md)를 참고하세요.

### 답변 스타일 (Attention-kind)

`install.sh`가 `global/output-styles/attention-kind.md`를 `~/.claude/output-styles/`에 링크합니다. 기본 스타일로 쓰려면 `~/.claude/settings.json`에 다음을 추가합니다 (대소문자 구분):

```json
{ "outputStyle": "Attention-kind" }
```

되돌리려면 `/output-style default`. 원본은 [alexgreensh/attention-span](https://github.com/alexgreensh/attention-span) v0.8이며 업데이트는 수동으로 반영합니다.

## 설계 원칙

AI가 만드는 불필요하게 많은 코드(slop)를 줄이기 위해, 강제력이 약한 것부터 강한 것까지 단계별로 둡니다.

| 단계 | 수단 | 이 레포의 위치 |
|---|---|---|
| 지시 | 답변 스타일 (결론부터, 짧게) | `global/output-styles/attention-kind.md` |
| 지시 | 코딩 원칙 (가정 금지, 최소 코드, 필요한 줄만 변경, 성공 기준) | `global/CLAUDE.md` |
| 증거 요구 | 검증 없는 "완료" 주장 금지 | `global/skills/verification-before-completion` |
| 게이트 | 실패하면 종료를 막는 lint와 정적분석 | `templates/*/.claude/hooks/quality-gate.sh` |

참고: [Claude Code 문서](https://code.claude.com/docs) · [Best Practices](https://code.claude.com/docs/en/best-practices) · 외부 출처는 [THIRD_PARTY.md](THIRD_PARTY.md)
