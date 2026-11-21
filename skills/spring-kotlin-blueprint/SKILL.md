---
name: spring-kotlin-blueprint
description: Spring Boot + Kotlin 백엔드에서 새 도메인/API, 계층 구조, Kafka 아웃박스 이벤트, Saga 보상, Redis 분산락과 재고 동시성, 캐시/RateLimit, TestContainers 테스트를 만들 때, 검증된 본보기 프로젝트의 어느 패키지를 읽고 어떻게 옮길지 안내한다. "구조 어떻게 잡지", "새 도메인 추가", "아웃박스 패턴 구현", "분산락 붙여줘", "동시성 테스트 작성" 같은 요청에 사용한다.
---

# Spring Kotlin Blueprint

본보기 프로젝트의 실제 코드를 읽고, 그 구조를 지금 작업 중인 프로젝트에 맞게 옮긴다.
이 스킬에는 코드가 없다. 어디를 읽을지, 왜 그렇게 짰는지, 무엇을 베끼면 안 되는지만 있다.

## 1. 본보기 위치 확인 (먼저 실행)

순서대로 시도해서 처음 성공한 곳을 `REPO`로 쓴다.

1. 환경변수 `SPRING_KOTLIN_BLUEPRINT_HOME`
2. `~/hanghae/hhplus-ecommerce`
3. 둘 다 없으면 임시 디렉터리에 받는다: `gh repo clone jaydenchuljinlee/hhplus-ecommerce <임시경로> -- --depth 1`

1번이나 2번을 찾았으면 `git -C REPO diff --name-only --diff-filter=U`를 실행한다. 출력이 있으면 병합 충돌이 진행 중이라 소스에 충돌 표시가 섞여 있다. 그 작업 트리는 쓰지 말고 3번으로 받는다.

이 스킬의 설명은 `origin/main` 기준이다.

이 문서와 `references/`의 경로는 아래 약어를 쓴다.

- `MAIN/` = `REPO/src/main/kotlin/com/hhplus/ecommerce/`
- `TEST/` = `REPO/src/test/kotlin/com/hhplus/ecommerce/`

본보기는 읽기 전용이다. 절대 수정하지 않는다.

## 2. 작업 유형별로 읽을 곳

해당하는 참조 파일 하나만 읽고, 그 파일이 가리키는 본보기 코드를 읽는다.

| 작업 | 참조 파일 | 기준 패키지 |
|---|---|---|
| 새 도메인, API 엔드포인트, 계층과 DTO 흐름 | `references/layering.md` | `MAIN/order/` |
| Kafka 이벤트, 아웃박스, Saga 보상 | `references/event-outbox.md` | `MAIN/outboxevent/`, `MAIN/balance/`, `MAIN/payment/` |
| 분산락, DB 락, 재고 예약 | `references/concurrency.md` | `MAIN/common/anotation/`, `MAIN/product/` |
| 예외 응답, 캐시, RateLimit, 스케줄러, 인증 | `references/cross-cutting.md` | `MAIN/common/` |
| 단위/통합/동시성 테스트 | `references/testing.md` | `TEST/` |

## 3. 옮기는 규칙

- **대상 프로젝트가 우선이다.** 먼저 대상 프로젝트의 CLAUDE.md와 기존 코드 2~3개를 읽는다. 이미 정해진 컨벤션(네이밍, 패키지 배치, 응답 형식)이 있으면 그쪽을 따르고, 본보기에서는 구조와 흐름만 가져온다.
- **가져갈 것:** 계층 분리와 의존 방향, DTO 변환 흐름, 아웃박스 저장/발행 분리, 락과 트랜잭션의 순서, 보상 처리 방식, 테스트 배치.
- **가져가지 않을 것:** `com.hhplus.ecommerce` 패키지명, `hhplus.kafka.*` 설정 키, 도메인 이름과 비즈니스 규칙, 한글 메시지 문구, 성능 비교용으로 중복된 메서드.
- **오타 패키지명을 옮기지 않는다.** 본보기의 `anotation`, `schedular`는 `annotation`, `scheduler`로 쓴다.
- 각 참조 파일의 "따라 하지 말 것" 항목은 본보기에 실제로 있는 약점이다. 그대로 복제하지 않는다.
- 본보기 코드를 통째로 붙여 넣지 않는다. 대상 프로젝트의 도메인에 맞게 새로 쓴다.

## 4. 검증

1. 대상 프로젝트의 빌드와 관련 테스트를 실행한다 (Gradle이면 `./gradlew test --tests "<테스트클래스>"`). 실패하면 원인을 고친다. Mock으로 덮어서 통과시키지 않는다.
2. 의존 방향을 확인한다: api → usecase → domain, infrastructure → domain. domain 코드가 api나 usecase를 import하면 잘못된 것이다.
3. 이 스킬의 경로가 깨졌다고 의심되면 `scripts/check-paths.sh [REPO]`를 실행한다. "없음"으로 나온 경로는 본보기에서 이름이 바뀐 것이니, 근처 디렉터리를 직접 찾아 읽고 사용자에게 스킬 갱신이 필요하다고 알린다.
