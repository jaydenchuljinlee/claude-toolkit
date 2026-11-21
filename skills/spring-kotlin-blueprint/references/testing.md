# 테스트

## 종류별로 읽을 파일

| 종류 | 본보기 | 방식 |
|---|---|---|
| Service 단위 | `TEST/domain/cart/CartServiceTest.kt` | Mockito, 리포지토리 인터페이스를 Mock |
| Facade 단위 | `TEST/facade/OrderFacadeTest.kt` | Mockito, Service들을 Mock |
| Controller 단위 | `TEST/api/order/OrderControllerTest.kt` | Mockito, Facade를 Mock하고 메서드를 직접 호출 |
| 엔티티 규칙 | `TEST/infrastructure/balance/jpa/entity/BalanceEntityTest.kt` | 순수 단위, Spring 없음 |
| 통합 | `TEST/domain/product/StockReservationIntegrationTest.kt` | `IntegrationConfig` 상속, 실제 컨테이너 |
| 동시성 | `TEST/OrderConcurrencyTest.kt`, `TEST/PaymentConcurrencyTest.kt` | 통합 + 스레드 풀 |
| Kafka | `TEST/infrastructure/kafka/KafkaIntegrationTest.kt` | 통합 + 테스트용 컨슈머 |

통합 테스트 기반: `TEST/common/config/IntegrationConfig.kt`, `TEST/common/config/MySqlTestContainerConfig.kt`, `TEST/common/config/RedisTestContainerConfig.kt`, `TEST/common/config/KafkaTestContainerConfig.kt`.

## 핵심 아이디어

- **단위 테스트는 Spring을 띄우지 않는다.** `@ExtendWith(MockitoExtension::class)`에 `@Mock` 필드를 두고, `@BeforeEach`에서 대상 객체를 생성자로 직접 만든다. 생성자 주입만 쓰기 때문에 가능하다.
- **Service가 인터페이스에 의존하니 Mock 대상이 인터페이스다.** 구현체나 JPA를 건드리지 않는다.
- **통합 테스트는 기반 클래스 하나를 상속한다.** `IntegrationConfig`가 `@SpringBootTest`, `@ActiveProfiles("test")`, 컨테이너 설정 `@Import`를 모아 둔다. 테스트 클래스는 `: IntegrationConfig()`만 쓰면 된다.
- **컨테이너는 `companion object`의 `init`에서 한 번 띄우고, 접속 정보를 `System.setProperty`로 넣는다.** 테스트 클래스가 여러 개여도 컨테이너는 JVM당 한 번만 뜬다.
- **운영용 Redis 설정은 `@Profile("!test")`로 빼고, 테스트 설정이 `RedissonClient` 빈을 대신 제공한다.** `MAIN/common/config/RedissonConfig.kt`와 짝이다.
- **테스트 이름은 `@DisplayName`에 한글 문장으로 쓴다.** "재고가 하나 남은 상품에 동시 신청하면 1명만 성공한다"처럼 조건과 결과를 적는다. 본문은 Given/When/Then 주석으로 나눈다.

## 동시성 테스트 형식

`TEST/OrderConcurrencyTest.kt`의 구조를 그대로 쓴다.

1. `@BeforeEach`에서 공유 상태(Redis 재고 등)를 명시적으로 초기화한다. 다른 테스트가 남긴 값에 기대지 않는다.
2. `CountDownLatch(1)`을 출발 신호로, `CountDownLatch(N)`을 완료 대기로 쓴다. 모든 스레드가 `await()`한 뒤 한꺼번에 출발해야 실제 경합이 생긴다.
3. 각 스레드는 예외를 잡고 `finally`에서 완료 래치를 내린다.
4. 검증은 "성공 건수"와 "최종 상태" 둘 다 한다 (성공 1건, 실패 4건, 남은 재고 0).

## 따라 하지 말 것

- **테스트 패키지가 계층별이다 (`api/`, `domain/`, `facade/`, `infrastructure/`).** 메인 코드는 도메인별인데 테스트만 다르다. 대상 프로젝트에서는 테스트 대상과 같은 패키지에 둔다.
- **동시성 테스트가 루트 패키지에 있다.** 해당 도메인 패키지에 `{Domain}ConcurrencyTest`로 둔다.
- **`Thread.sleep(500)`으로 비동기 완료를 기다린다.** Awaitility처럼 조건을 기다리는 방식으로 바꾼다.
- **동시성 테스트가 SQL 초기 데이터의 특정 ID(`product_detail.id=4`)에 의존한다.** 테스트 안에서 필요한 데이터를 직접 만든다.
- **Controller 테스트가 메서드를 직접 호출한다.** 매핑, 직렬화, 예외 핸들러는 검증되지 않는다. 그 부분이 중요하면 `@WebMvcTest`와 MockMvc를 쓴다.
- **컨테이너 이미지가 `redis:latest`다.** 버전을 고정한다.
- **MongoDB는 테스트 컨테이너가 없다.** Mongo를 쓰는 기능을 옮기면 컨테이너 설정을 추가한다.
- **`TEST/api/payment/PaymentEntityControllerTest.kt`** 는 이름이 대상과 맞지 않는다.
