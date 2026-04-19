---
description: Spring Kotlin/Java TDD 워크플로우. Red-Green-Refactor 사이클로 새 기능/도메인 로직 구현 시 사용. "구현해줘", "기능 추가", "TDD로 만들어줘" 등에 트리거.
argument-hint: [구현할 기능 설명] e.g. "쿠폰 도메인 서비스 - 쿠폰 적용 로직"
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(./gradlew *)
model: sonnet
---

요청: **$ARGUMENTS**

---

## TDD 원칙

> **Red → Green → Refactor** 순서를 반드시 지킨다.
> 각 단계는 독립적으로 실행하고, 이전 단계가 완료된 것을 확인 후 다음 단계로 진행한다.

---

## Phase 0. 탐색 (변경 없음)

구현 전에 반드시 기존 코드를 파악한다.

### 0-1. 관련 도메인 구조 파악

```
도메인별 패키지 구조:
src/main/kotlin/com/hhplus/ecommerce/{domain}/
  ├── api/                  ← Controller, Request/Response DTO
  ├── domain/               ← Service, Domain DTO, Repository Interface
  │   ├── dto/
  │   └── repository/       ← I{Name}Repository (인터페이스)
  ├── infrastructure/       ← Repository 구현체, JPA Entity, Exception
  │   ├── jpa/entity/
  │   └── exception/
  └── usecase/              ← Facade, UseCase DTO
```

파악할 것:
- 동일 도메인의 기존 Service / Facade 클래스
- 기존 테스트 파일 위치 및 패턴
- 사용 중인 Repository 인터페이스
- 관련 Exception 클래스

### 0-2. 테스트 위치 결정

| 테스트 대상 | 위치 | 설정 |
|---|---|---|
| Domain Service | `src/test/.../domain/{domain}/` | `@ExtendWith(MockitoExtension::class)` |
| Facade / UseCase | `src/test/.../facade/` | `@ExtendWith(MockitoExtension::class)` |
| Controller | `src/test/.../api/{domain}/` | `@ExtendWith(MockitoExtension::class)` |
| Repository / 통합 | `src/test/.../domain/{domain}/` | `IntegrationConfig` 상속 |
| 동시성 | `src/test/.../` (루트) | `IntegrationConfig` 상속 |

---

## Phase 1. RED — 실패하는 테스트 작성

> 테스트를 먼저 작성하고, 컴파일 가능한 최소한의 구현만 존재하는 상태를 만든다.

### 1-1. 테스트 파일 작성 규칙

**단위 테스트 (Service / Facade / Controller)**

```kotlin
package com.hhplus.ecommerce.domain.{domain}

import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.BDDMockito
import org.mockito.BDDMockito.then
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension
import kotlin.test.assertEquals

@ExtendWith(MockitoExtension::class)
class {Domain}ServiceTest {
    @Mock
    private lateinit var {domain}Repository: I{Domain}Repository

    private lateinit var {domain}Service: {Domain}Service

    @BeforeEach
    fun before() {
        {domain}Service = {Domain}Service({domain}Repository)
    }

    @DisplayName("성공: [기능 설명]")
    @Test
    fun [camelCase테스트명]() {
        // Given
        ...

        // When
        val result = {domain}Service.{method}(...)

        // Then
        assertEquals(expected, result)
    }
}
```

**통합 테스트 (실제 DB/Kafka/Redis 필요)**

```kotlin
package com.hhplus.ecommerce.domain.{domain}

import com.hhplus.ecommerce.common.config.IntegrationConfig
import org.springframework.beans.factory.annotation.Autowired

class {Domain}IntegrationTest : IntegrationConfig() {
    @Autowired
    private lateinit var {domain}Service: {Domain}Service

    @DisplayName("성공: [기능 설명]")
    @Test
    fun [camelCase테스트명]() {
        // Given / When / Then
    }
}
```

**동시성 테스트**

```kotlin
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors

@Test
fun concurrentTest() {
    val threadCount = 10
    val executor = Executors.newFixedThreadPool(threadCount)
    val readyLatch = CountDownLatch(threadCount)
    val completeLatch = CountDownLatch(threadCount)
    val successResults = Collections.synchronizedList(mutableListOf<Any>())
    val failResults = Collections.synchronizedList(mutableListOf<Exception>())

    repeat(threadCount) {
        executor.submit {
            readyLatch.countDown()
            readyLatch.await()
            try {
                // 테스트 대상 호출
                successResults.add(...)
            } catch (e: Exception) {
                failResults.add(e)
            } finally {
                completeLatch.countDown()
            }
        }
    }
    completeLatch.await()
    executor.shutdown()

    // Then
    assertEquals(expected, successResults.size)
}
```

### 1-2. RED 검증

테스트 작성 후 반드시 실행해서 **실패(빨간불)** 를 확인한다.

```bash
./gradlew test --tests "{TestClassName}"
```

- **컴파일 에러** → 최소한의 빈 구현체(stub)를 추가해서 컴파일만 통과시킨다 (로직 없음)
- **런타임 실패** → 예상한 실패인지 확인 (AssertionError, 예외 등)
- **예상치 못한 통과** → 테스트가 의미 없는 것. 테스트를 수정한다.

---

## Phase 2. GREEN — 최소한의 구현

> 테스트를 통과시키는 데 필요한 **최소한의 코드**만 작성한다. 완벽한 코드를 쓰지 않아도 된다.

### 2-1. 구현 위치 규칙

| 구현체 | 위치 |
|---|---|
| Domain Service | `domain/{service}.kt` |
| Repository Interface | `domain/repository/I{Name}Repository.kt` |
| Repository 구현체 | `infrastructure/{Name}Repository.kt` |
| JPA Entity | `infrastructure/jpa/entity/{Name}Entity.kt` |
| Facade | `usecase/{Name}Facade.kt` |
| Exception | `infrastructure/exception/{Name}Exception.kt` |

### 2-2. 아키텍처 의존성 규칙

```
api → usecase(Facade) → domain(Service) ← infrastructure(Repository 구현체)
```

- Domain Service는 `I{Name}Repository` 인터페이스에만 의존한다
- Infrastructure는 Domain을 구현하되, Domain이 Infrastructure를 import하지 않는다
- Facade는 여러 Domain Service를 조합한다

### 2-3. GREEN 검증

```bash
./gradlew test --tests "{TestClassName}"
```

모든 테스트가 **통과(초록불)** 되어야 다음 단계로 넘어간다.

---

## Phase 3. REFACTOR — 코드 개선

> 테스트는 그대로 유지하면서 코드 품질을 높인다.

### 3-1. 리팩토링 체크리스트

- [ ] 중복 로직이 있으면 추출 (단, 재사용이 1회뿐이면 하지 않는다)
- [ ] 메서드/클래스명이 도메인 언어를 반영하는가
- [ ] 예외 처리가 적절한가 (infrastructure 계층에서 throw, domain에서 catch)
- [ ] 불필요한 주석 제거
- [ ] Kotlin 관용구 적용 (let, also, run, apply, takeIf 등 — 의미가 명확할 때만)

### 3-2. 프로젝트 고유 패턴 준수

**인터페이스 접두사**
```kotlin
interface IOrderRepository  // ← I 접두사 필수
```

**예외 계층**
```kotlin
// infrastructure/exception/ 아래에 위치
class {Domain}NotFoundException : RepositoryException("메시지")
class {Domain}ServiceException : ServiceException("메시지")
```

**분산락 적용 시**
```kotlin
@RedisLock(key = "'lock:' + #param")
fun criticalMethod(param: Long) { ... }
```

**Outbox 패턴 (Kafka 이벤트 발행 시)**
- `OutboxEventService`를 통해 저장 후 발행
- `@TransactionalEventListener`로 트랜잭션 커밋 후 처리

### 3-3. REFACTOR 검증

리팩토링 후 반드시 다시 실행한다.

```bash
./gradlew test --tests "{TestClassName}"
```

통과 확인 후, 연관된 다른 테스트도 함께 확인한다.

```bash
# 전체 빌드 확인 (선택)
./gradlew build
```

---

## Phase 4. 완료 체크

- [ ] RED: 테스트가 실패하는 것을 확인했다
- [ ] GREEN: 최소 구현으로 테스트가 통과한다
- [ ] REFACTOR: 코드가 정리되어 있고 테스트가 여전히 통과한다
- [ ] 통합 테스트가 필요한 경우 추가 작성했다
- [ ] 동시성 이슈가 있는 기능은 동시성 테스트를 추가했다

---

## 빠른 참조

### 테스트 실행 명령어

```bash
# 단일 클래스
./gradlew test --tests "CartServiceTest"

# 단일 메서드
./gradlew test --tests "CartServiceTest.getCartByProductNullTest"

# 패키지 전체
./gradlew test --tests "com.hhplus.ecommerce.domain.cart.*"
```

### Mockito BDDMockito 패턴

```kotlin
// given: 반환값 설정
BDDMockito.given(repository.findById(id)).willReturn(entity)

// given: 예외 발생
BDDMockito.given(repository.findById(id)).willThrow(RuntimeException())

// then: 호출 여부 검증
then(service).should().commit(orderId)
then(service).should(BDDMockito.never()).rollback()
```

### IntegrationConfig 상속

```kotlin
// TestContainers (MySQL + Kafka + Redis) 자동 실행
class MyIntegrationTest : IntegrationConfig() {
    @Autowired lateinit var myService: MyService
}
```
