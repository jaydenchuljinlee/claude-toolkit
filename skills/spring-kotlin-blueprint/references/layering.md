# 계층 구조와 새 도메인/API

기준 도메인은 `order`다. 네 계층을 모두 갖춘 도메인은 `order`와 `payment`뿐이다.

## 읽는 순서

요청이 들어오는 방향대로 읽는다.

1. `MAIN/order/api/IOrderController.kt` : 매핑, Swagger, `@RateLimit`은 전부 인터페이스에 둔다.
2. `MAIN/order/api/OrderController.kt` : 구현체는 변환과 위임만 한다.
3. `MAIN/order/api/dto/OrderCreationRequest.kt`, `MAIN/order/api/dto/OrderResponse.kt`
4. `MAIN/order/usecase/OrderFacade.kt` : `order()` 메서드만 본다.
5. `MAIN/order/usecase/dto/OrderCreation.kt`, `MAIN/order/usecase/dto/OrderInfo.kt`
6. `MAIN/order/domain/OrderService.kt`
7. `MAIN/order/domain/dto/OrderCreationCommand.kt`, `MAIN/order/domain/dto/OrderResult.kt`
8. `MAIN/order/domain/repository/IOrderRepository.kt`
9. `MAIN/order/infrastructure/OrderRepository.kt` : 인터페이스 구현체, JPA 리포지토리를 감싼다.
10. `MAIN/order/infrastructure/jpa/entity/OrderEntity.kt`
11. `MAIN/order/infrastructure/exception/OrderNotFoundException.kt`

Facade 없이 단순한 도메인은 `MAIN/cart/`를 본다 (Controller가 Service를 직접 호출).

## 패키지 배치

```
{domain}/
├── api/            I{Domain}Controller, {Domain}Controller, dto/{X}Request, {X}Response
├── usecase/        {Domain}Facade, dto/{X}Creation, {Domain}Info      (여러 서비스를 엮을 때만)
├── domain/         {Domain}Service, dto/{X}Command, {X}Query, {X}Result, repository/I{Domain}Repository
├── infrastructure/ {Domain}Repository, jpa/{Domain}JpaRepository, jpa/entity/, exception/, event/
└── common/         도메인 전용 enum ({Domain}Status 등)
```

여러 도메인이 같이 쓰는 것은 최상위 `MAIN/common/`(설정, 예외 기반 클래스, 애너테이션)과 `MAIN/infrastructure/`(Kafka 프로듀서, Redis 락)에 둔다.

## 핵심 아이디어

- **계층마다 DTO가 따로 있고, 변환 메서드는 "아는 쪽"에 둔다.** 들어갈 때는 바깥 DTO가 `toXxx()`로 안쪽 DTO를 만든다 (`Request.toOrderCreation()`, `OrderCreation.toOrderCreationCommand()`, `Command.toEntity()`). 나올 때는 바깥 DTO의 `companion object { fun from(안쪽) }`이 받는다 (`OrderResult.from(entity)`, `OrderInfo.from(result)`, `OrderResponse.from(info)`). 안쪽 계층은 바깥 타입을 모른다.
- **Facade DTO가 다른 도메인의 입력도 만든다.** `OrderCreation`이 `toUserQuery()`, `toBalanceTransaction()`을 갖고 있어서 Facade 본문이 호출 나열로만 읽힌다.
- **Service는 리포지토리 인터페이스에만 의존한다.** 구현체가 `orElseThrow { OrderNotFoundException() }`로 "없음"을 예외로 바꿔서, Service에는 null 처리가 없다.
- **Facade는 `@Component`이고 트랜잭션을 걸지 않는다.** 각 Service 메서드가 자기 `@Transactional`로 짧게 커밋하고, 실패하면 Facade가 try/catch로 보상한다 (재고 해제 후 주문 CANCELED). 긴 유스케이스가 DB 커넥션을 오래 잡지 않게 하려는 선택이다.
- **상태를 바꾸는 Service 메서드에만 `@Transactional`을 건다.** 단순 조회에는 없다.
- **엔티티가 자기 규칙을 가진다.** `OrderEntity.removeOf()`처럼 상태 변경 로직을 엔티티 메서드로 둔다.
- **예외는 계층별 추상 클래스를 상속한다.** `{Domain}RepositoryException : RepositoryException` 형태다. HTTP 상태 매핑은 `references/cross-cutting.md`를 본다.

## 따라 하지 말 것

- **`OrderFacade`의 `orderWithLock()`, `orderWithSpinLock()`.** 성능 비교용으로 `order()`를 복사한 것이다. 엔드포인트 `/lock`, `/spin`도 같은 이유로 있다.
- **domain이 infrastructure의 엔티티와 예외를 import한다.** `IOrderRepository`가 `OrderEntity`를 반환하고, `Command.toEntity()`가 엔티티를 만든다. "도메인은 인프라에 의존하지 않는다"는 원칙이 리포지토리 구현체에만 지켜진 상태다. 대상 프로젝트가 엔티티를 domain에 두거나 도메인 모델을 분리했으면 그 방식을 따른다. 새 프로젝트면 엔티티와 도메인 예외를 `domain/` 아래에 두는 쪽을 권한다.
- **예외 위치가 도메인마다 다르다.** `order`는 `infrastructure/exception/`, `payment`는 `domain/exception/`, `balance`는 `api/exception/`도 쓴다. 대상 프로젝트에서는 한 곳으로 정한다.
- **DTO가 `var` 필드의 일반 class인 곳이 있다.** 새로 쓸 때는 `data class`와 `val`을 쓴다.
- **`I` 접두사 인터페이스 이름**은 이 프로젝트의 컨벤션이다. 대상 프로젝트가 쓰지 않으면 따르지 않는다.

## 새 도메인을 만들 때 순서

1. 엔티티와 리포지토리 인터페이스, 구현체.
2. Service와 domain DTO. Service 단위 테스트를 같이 쓴다 (`references/testing.md`).
3. 다른 도메인 서비스를 엮어야 하면 Facade와 usecase DTO. 아니면 생략한다.
4. Controller 인터페이스, 구현체, Request/Response.
5. 관련 테스트 실행.
