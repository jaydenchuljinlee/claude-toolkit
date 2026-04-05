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
```

## 참고

- [Claude Code 공식 문서](https://code.claude.com/docs)
- [Best Practices](https://code.claude.com/docs/en/best-practices)
