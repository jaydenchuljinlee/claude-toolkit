---
description: 채용공고 기반 자기소개서 작성. URL 또는 텍스트로 채용공고를 전달하면 이력서/포트폴리오 분석, 기업 리서치, 합격 자소서 참고까지 자동 수행 후 초안을 생성한다
argument-hint: [채용공고 URL] e.g. "https://career.hyundai-autoever.com/ko/o/210922"
model: opus
---

사용자가 자기소개서 작성을 요청했다.

## 입력 확인

$ARGUMENTS 를 확인한다:
- URL이면: 바로 Phase 1 진입
- 기업명+포지션명 텍스트면: 바로 Phase 1 진입 (채용공고 분석은 스킵)
- 비어있으면: 채용공고 URL 또는 기업명/포지션명을 요청

## 실행

cover-letter-writer 스킬의 파이프라인을 따라 실행한다.
스킬 파일(~/.claude/skills/cover-letter-writer/SKILL.md)의 오케스트레이션 절차를 참조하여
Phase 1 → Phase 2 → Phase 3 → Phase 4 순서로 진행한다.
