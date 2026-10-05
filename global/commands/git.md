---
description: GitHub 작업 통합 커맨드. Repo 생성, 커밋/푸시, 브랜치 관리, PR 생성/리뷰/머지, Reset을 처리합니다.
argument-hint: [요청] e.g. "새 repo 만들어줘", "PR 만들어줘", "feature/login 브랜치 만들어줘"
allowed-tools: mcp__github__*, Bash(git rev-parse *), Bash(git status *), Bash(git log *), Bash(git remote *), Bash(git branch *), Bash(git init *), Bash(git add *), Bash(git commit *), Bash(git push *), Bash(git reset *), Bash(mkdir *), Bash(touch *), Bash(echo *), Bash(ls *)
model: sonnet
---

요청: **$ARGUMENTS**

---

## Phase 1. 탐색 (변경 없음)

### 1-1. 대상 디렉토리 결정
$ARGUMENTS에서 경로 패턴을 먼저 파싱한다.

| 패턴 예시 | 처리 |
|---|---|
| `~/some/path 에 ...` | target_dir = ~/some/path |
| `/absolute/path 안에 ...` | target_dir = /absolute/path |
| `./relative 폴더에 ...` | target_dir = ./relative |
| 경로 없음 | target_dir = 현재 디렉토리 |

경로가 있으면:
```bash
ls {target_dir} 2>&1   # 존재 여부 확인
mkdir -p {target_dir}  # 없으면 생성
```
이후 모든 작업은 해당 경로 기준으로 수행한다.

### 1-2. Git 상태 탐색
```bash
git rev-parse --is-inside-work-tree 2>&1
```
- `true` → 기존 repo. 아래 추가 탐색 실행:
  ```bash
  git remote -v 2>&1
  git branch -a 2>&1
  git status --short 2>&1
  git log --oneline -5 2>&1
  ```
- 에러 → repo 없음. **Phase 2-A로 이동**

### 1-3. 맥락 추론
owner / repo / branch 등 필수 정보가 없을 때 아래 순서로 추론한다:
1. $ARGUMENTS에서 직접 추출
2. 이번 대화의 이전 메시지에서 언급된 값 참조
3. 탐색 결과(remote URL, 현재 브랜치)에서 파싱
4. GitHub MCP로 원격 상태 조회 (`list_branches` 등)
5. 위 모두 불명확할 때만 사용자에게 질문

---

## Phase 2. 계획 및 실행

요청 내용을 분석해 아래 케이스 중 하나로 분기한다.

---

### A. Repo 생성

**해당 조건**: git repo가 없거나 "새 repo", "repo 만들어줘" 요청

**계획 수립 후 사용자에게 확인:**
- Repo 이름: $ARGUMENTS에서 추출 → 없으면 현재 폴더명
- 공개 여부: 명시 없으면 private

**실행 순서:**

① 보안 파일 먼저 생성
```bash
echo ".env\n.env.local\n*.pem\n*.key\nsecrets.*\n.DS_Store\nnode_modules/" > .gitignore
```

② 로컬 초기화 및 스테이징
```bash
git init
git add .
git status --short
```

③ 검증: 민감파일 staged 여부 확인
- `.env`, `*.pem`, `*.key`, `secrets.*` 감지 시 → **즉시 중단 + 경고**
- 이상 없으면 계속

④ 첫 커밋
```bash
git commit -m "feat: initial commit"
```

⑤ GitHub MCP로 원격 Repo 생성
- 툴: `create_repository`
- name, private 값 적용

⑥ 연결 및 푸시
```bash
git remote add origin https://github.com/{owner}/{repo}.git
git branch -M main
git push -u origin main
```

**검증**: push 성공 여부 확인 후 Repo URL 출력

---

### B. 커밋 / 푸시

**해당 조건**: "커밋", "푸시", "올려줘" 요청

**탐색**: 변경 파일 목록 확인 후 사용자에게 표시
```bash
git status --short
git diff --stat
```

**검증**: 민감파일 staged 여부 확인 → 감지 시 중단

**실행**: GitHub MCP `push_files` 사용
- `branch`: 현재 브랜치
- `files`: 변경된 파일 목록 + 내용
- `message`: $ARGUMENTS에서 추출 → 없으면 변경 내용 기반 자동 생성
  - Conventional Commits 형식: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`

**검증**: push 완료 후 커밋 SHA 출력

---

### C. 브랜치 관리

**해당 조건**: "브랜치 만들어줘", "브랜치 삭제", "브랜치 목록" 요청

**from_branch 결정 (생성 시):**
1. $ARGUMENTS에 명시된 브랜치 (`"develop 기준으로"`)
2. 대화 이전 메시지에서 언급된 브랜치
3. `list_branches` MCP로 조회 후 `develop` → `main` 순 존재 확인
4. 불명확 시 사용자에게 선택지 제시 (절대 묵시적으로 기본값 사용 금지)

**작업별 처리:**

| 요청 | 툴 |
|---|---|
| 브랜치 생성 | MCP `create_branch` (from_branch 위 규칙 적용) |
| 브랜치 목록 | MCP `list_branches` |
| 로컬 삭제 | `git branch -d {name}` (병합 여부 확인 후) |
| 강제 삭제 | `git branch -D {name}` ⚠️ 사용자 확인 필수 |
| PR 브랜치 업데이트 | MCP `update_pull_request_branch` |

**검증**: 생성/삭제 후 `list_branches`로 결과 확인

---

### D. PR 생성 / 리뷰 / 머지

**해당 조건**: "PR 만들어줘", "PR 리뷰해줘", "머지해줘" 요청

#### D-1. PR 생성

**탐색**: 현재 브랜치 커밋 내역 분석
- MCP `list_commits`로 base 브랜치 이후 커밋 목록 조회

**계획**: PR 초안 자동 작성 후 사용자에게 확인
```
제목: 커밋 내용 기반 한 줄 요약
본문:
  ## 변경사항
  (커밋 목록 기반 자동 서술)

  ## 체크리스트
  - [ ] 테스트 완료
  - [ ] 문서 업데이트
```
- base 브랜치: 대화 맥락 → 없으면 main
- draft 여부: $ARGUMENTS에 "draft" 언급 시 true

**실행**: MCP `create_pull_request`

**검증**: PR URL 출력

#### D-2. PR 리뷰

**탐색**: 컨텍스트 오염 방지를 위해 서브에이전트로 위임
```
use a subagent to review PR #{number}:
- pull_request_read(get_diff): 변경 코드 분석
- pull_request_read(get_files): 변경 파일 목록
- pull_request_read(get_review_comments): 기존 리뷰 확인
- pull_request_read(get_check_runs): CI/CD 상태 확인
Report: 변경사항 요약, 잠재적 이슈, 개선 제안
```

#### D-3. PR 머지

**탐색**: CI 상태 확인
- MCP `pull_request_read(get_check_runs)`

**계획**: merge_method 결정
- "squash" 언급 또는 기본값 → `squash`
- "rebase" 언급 → `rebase`
- "merge commit" 언급 → `merge`

**실행**: 사용자 확인 후 MCP `merge_pull_request`

**검증**: 머지 완료 후 base 브랜치 최신 커밋 확인

---

### E. Reset

**해당 조건**: "reset", "되돌려줘", "취소해줘" 요청

> ⚠️ Reset은 GitHub MCP 미지원 — 로컬 Bash만 사용

**탐색**: 현재 상태 표시
```bash
git log --oneline -10
git status
```

**계획**: 영향 범위 설명 후 사용자 확인 필수

| 옵션 | 동작 | 복구 가능 |
|---|---|---|
| `--soft` | 커밋만 취소, staged 유지 | ✅ |
| `--mixed` | 커밋 + staged 취소, 파일 유지 (기본값) | ✅ |
| `--hard` | 모든 변경사항 완전 삭제 | ❌ |

**실행**: 사용자 확인 후
```bash
git reset --{soft|mixed|hard} HEAD~{N}
```

**검증**:
```bash
git log --oneline -5
git status
```
결과를 보여주며 의도한 대로 반영됐는지 확인

---

## 🔒 보안 규칙 (모든 케이스 공통)

- push/commit 전 반드시 `.env`, `*.pem`, `*.key`, `secrets.*` staged 여부 체크
- 민감파일 감지 시 즉시 중단 + 경고
- `--hard` reset, force push는 반드시 사용자 확인 후 실행
- GitHub MCP 토큰은 `~/.claude/.env`에서만 관리
