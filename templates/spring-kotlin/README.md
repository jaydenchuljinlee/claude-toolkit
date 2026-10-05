# Spring Kotlin 프로젝트 템플릿

Spring Boot + Kotlin (DDD 패키지 구조) 프로젝트에 복사해서 쓰는 Claude 설정입니다.

## 구성

| 파일 | 역할 |
|---|---|
| `CLAUDE.md` | 프로젝트 지시문 템플릿. `{...}` 부분을 채운다 |
| `.claude/settings.json` | Gradle 명령 사전 승인 + **Stop hook 품질 게이트** |
| `.claude/hooks/quality-gate.sh` | 응답 종료 시 `ktlintCheck detekt` 실행. 실패하면 종료를 막고 오류를 Claude에게 돌려준다 (세션당 최대 3회) |
| `.claude/commands/implement.md` | `/implement` — 계획 → 구현 → 테스트 → 검증 에이전트 체인 |
| `.claude/commands/spring-tdd.md` | `/spring-tdd` — Spring용 Red-Green-Refactor |
| `.claude/agents/*` | feature-planner, feature-implementer, test-runner, code-validator |

`implement`와 `spring-tdd`는 `disable-model-invocation: true`라 직접 호출할 때만 실행됩니다.

## 적용

```bash
# 프로젝트 루트에서 (기존 CLAUDE.md / .claude 가 있으면 먼저 확인)
cp -R /path/to/claude-toolkit/templates/spring-kotlin/.claude .
cp /path/to/claude-toolkit/templates/spring-kotlin/CLAUDE.md .
```

## 품질 게이트 준비 (Gradle)

hook은 Gradle 태스크를 실행할 뿐이므로 프로젝트에 플러그인이 있어야 합니다. 예시 (`build.gradle.kts`):

```kotlin
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "<버전>"
    id("io.gitlab.arturbosch.detekt") version "<버전>"
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom("$rootDir/config/detekt/detekt.yml") // 팀 규칙으로 조정
}
```

- 처음 도입하면 기존 코드에서 위반이 많이 나올 수 있습니다. 이때는 `detektBaseline`으로 baseline을 만들어 **새로 생기는 위반만** 막는 것을 권장합니다.
- 실행 명령은 `.claude/settings.json`의 `env.CLAUDE_QUALITY_GATE_CMD`로 바꿉니다. 예: Spotless를 쓰면 `./gradlew --quiet spotlessCheck detekt`.
- 테스트까지 게이트에 넣으면 매 응답마다 오래 걸립니다. 기본값은 lint와 정적분석만 돌립니다.

## 왜 Stop hook인가

CLAUDE.md의 지시는 컨텍스트가 길어지면 덜 지켜집니다. 반면 실패하는 lint 명령은 무시할 수 없습니다.
AI가 자주 만드는 패턴(미사용 코드, 긴 파라미터 목록, 복잡한 메서드 등)은 detekt 기본 규칙으로 먼저 잡습니다. 반복해서 보이는 패턴이 생기면 커스텀 규칙으로 추가합니다.
