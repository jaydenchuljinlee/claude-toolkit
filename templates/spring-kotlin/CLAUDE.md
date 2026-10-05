# {프로젝트명}

> 이 파일은 프로젝트 루트에 둔다. 매 세션 로드되므로 "없으면 Claude가 실수할 내용"만 짧게 적는다.

## 빌드 / 검증 명령

| 목적 | 명령 |
|---|---|
| 컴파일 | `./gradlew compileKotlin` |
| 단일 테스트 | `./gradlew test --tests "{TestClassName}"` |
| 전체 테스트 | `./gradlew test` |
| 포맷 자동 수정 | `./gradlew ktlintFormat` |
| 린트 + 정적분석 (Stop hook과 동일) | `./gradlew ktlintCheck detekt` |

작업을 끝내기 전에 위 검증을 직접 실행하고, 출력을 근거로 결과를 보고한다.
lint 오류는 규칙을 끄거나 `@Suppress`로 숨기지 말고 코드를 고친다.

## 패키지 구조

```
src/main/kotlin/{base.package}/{domain}/
  ├── api/              Controller, Request/Response DTO
  ├── domain/           Service, Domain DTO, Repository 인터페이스
  ├── infrastructure/   Repository 구현체, JPA Entity, Exception
  └── usecase/          Facade, UseCase DTO
```

의존 방향: `api → usecase → domain ← infrastructure` (domain은 infrastructure를 import하지 않는다)

## 컨벤션

- {네이밍 규칙}
- {테스트 규칙: 단위 테스트는 MockitoExtension, 통합 테스트는 IntegrationConfig 상속 등}
- {동시성/분산락 규칙}

## 워크플로우

- 기능 구현 파이프라인: `/implement <기능 설명>` (계획 → 구현 → 테스트 → 검증)
- Spring TDD: `/spring-tdd <기능 설명>`
