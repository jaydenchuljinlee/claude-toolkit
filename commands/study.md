---
description: 공부하고 싶은 주제를 알아서 검색하고 핵심 자료를 정리해줍니다
argument-hint: [topic] e.g. "LangGraph", "Rust ownership", "Next.js App Router"
allowed-tools: WebSearch, WebFetch
model: sonnet
---

공부 주제: **$ARGUMENTS**

## 수행 순서

### 1. Google 검색
다음 키워드 조합으로 각각 검색하세요:
- `$ARGUMENTS tutorial 2025`
- `$ARGUMENTS best practices`
- `$ARGUMENTS site:dev.to OR site:medium.com`

### 2. YouTube 검색
- `$ARGUMENTS tutorial`
- `$ARGUMENTS 2025`

YouTube 검색은 `https://www.youtube.com/results?search_query=...` URL을 WebFetch로 읽어서
상위 영상 제목과 채널명을 추출하세요.

### 3. 결과 정리

아래 형식으로 출력해주세요:

---
## 📌 $ARGUMENTS — 학습 가이드

### 🧠 개념 한 줄 요약
(핵심 개념을 한 문장으로)

### 🔥 최신 동향
(2025~2026 기준 주요 변화나 트렌드)

### 📖 읽을거리 (Articles)
1. [제목](URL) — 한 줄 설명, 난이도: ⭐/⭐⭐/⭐⭐⭐
2. ...

### 🎥 볼거리 (YouTube)
1. [영상 제목] — 채널명, 한 줄 설명
2. ...

### 🗺 학습 순서 추천
입문 → 중급 → 심화 순으로 위 자료를 번호로 나열

### 🔑 같이 검색하면 좋은 키워드
- keyword1, keyword2, keyword3
---
