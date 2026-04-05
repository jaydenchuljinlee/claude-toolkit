---
description: 정리된 학습 내용을 Notion 학습 데이터베이스에 저장합니다
argument-hint: [topic]
allowed-tools: mcp__notion__*
model: sonnet
---

주제: **$ARGUMENTS**

다음 순서로 Notion에 저장하세요:

1. `notion_search`로 "학습 노트" 데이터베이스 찾기
2. 해당 DB에 새 페이지 생성:
   - 제목: $ARGUMENTS
   - 태그: 학습
   - 날짜: 오늘
3. 직전 대화에서 정리한 내용을 페이지 본문에 그대로 작성
4. 저장 완료 후 페이지 URL 출력
