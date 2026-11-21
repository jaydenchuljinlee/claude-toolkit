# 분산락, DB 락, 재고 예약

## 분산락 애너테이션: 읽는 순서

1. `MAIN/common/anotation/RedisLock.kt`
2. `MAIN/common/anotation/aspect/RedisLockAspect.kt` : 이 파일이 핵심이다.
3. `MAIN/infrastructure/redis/IRedisLockSupporter.kt`
4. `MAIN/infrastructure/redis/PubSubLockSupporter.kt` : 기본 전략.
5. `MAIN/balance/domain/BalanceService.kt` : `charge()`, `use()`가 사용 예다.
6. `MAIN/coupon/domain/CouponService.kt` : `issue()`는 분산락과 DB 락을 같이 쓴다.

## 핵심 아이디어

- **락 획득 → 트랜잭션 시작 → 커밋 → 락 해제 순서를 Aspect가 보장한다.** `RedisLockAspect`가 락 안에서 `REQUIRES_NEW` 트랜잭션을 직접 열고 닫는다. 순서가 반대면(트랜잭션 안에서 락) 커밋 전에 락이 풀려서 다음 스레드가 커밋되지 않은 옛 값을 읽는다.
- **그래서 `@RedisLock` 메서드에는 `@Transactional`을 붙이지 않는다.** Aspect가 트랜잭션을 만든다. 호출자의 트랜잭션과는 별개로 커밋되므로, 호출자가 나중에 실패해도 이 메서드의 변경은 롤백되지 않는다. 호출자가 보상해야 한다.
- **키는 SpEL로 쓴다.** `"'balance:' + #item.userId"`처럼 "접두사 + 경합 단위의 식별자"다. 락 범위는 경합이 실제로 일어나는 가장 작은 단위(사용자, 쿠폰 정책, 상품 옵션)로 잡는다.
- **락 구현은 인터페이스 뒤에 둔다.** `withLock(key) { ... }` 하나만 노출하고, 해제는 `finally`에서 `isHeldByCurrentThread`를 확인한 뒤 한다.
- **대기 10초, 점유 5초.** 점유 시간 안에 작업이 끝나지 않으면 락이 먼저 풀린다. 락 안의 작업은 짧게 유지한다.
- **분산락과 DB 비관적 락을 겹쳐 쓴 곳이 있다.** `CouponService.issue()`는 `@RedisLock` 안에서 쿠폰 정책 행을 `PESSIMISTIC_WRITE`로 한 번 더 잠근다 (`MAIN/coupon/infrastructure/jpa/CouponPolicyJpaRepository.kt`의 `findByIdWithLock`). Redis 락이 만료되거나 실패해도 DB가 마지막 방어선이 된다.

## 재고 예약: 읽는 순서

1. `MAIN/product/domain/StockReservationService.kt` : `reserve()`, `commit()`, `release()`, `expireOverdue()`만 본다.
2. `MAIN/product/domain/repository/IRedisStockRepository.kt`
3. `MAIN/product/infrastructure/redis/RedisStockRepository.kt`
4. `MAIN/product/infrastructure/redis/StockLuaScripts.kt`
5. `MAIN/product/infrastructure/redis/RedisStockSyncScheduler.kt`
6. `MAIN/common/schedular/StockReservationExpiryScheduler.kt`
7. `MAIN/order/usecase/OrderFacade.kt`의 `order()`, `MAIN/payment/usecase/PaymentFacade.kt`의 `pay()` : 예약과 확정을 호출하는 쪽.

## 재고 핵심 아이디어

- **예약과 확정을 나눈다.** 주문 시점에는 Redis의 가용 재고만 줄이고(`reserve`), 결제가 끝나면 MySQL의 실제 재고를 줄인다(`commit`). 결제하지 않은 주문은 30분 뒤 만료되어 재고가 돌아온다.
- **"검사 후 차감"을 Lua 스크립트 하나로 한다.** `GET`과 `DECRBY`가 원자적으로 실행되므로 락 없이도 초과 판매가 없다. 락 방식보다 빠르다.
- **Redis와 MySQL 사이는 보상으로 맞춘다.** Redis 차감 뒤 MySQL 예약 행 저장이 실패하면 catch에서 Redis를 되돌린다.
- **확정은 DB 비관적 락으로 한다.** `commit()`이 `findByIdForUpdate`로 행을 잠그고 줄인다.
- **Redis는 정답이 아니라 캐시다.** 기동 시 MySQL에서 전체 재고를 Redis로 올리고, 10분마다 다시 맞추도록 짜여 있다. 만료 스케줄러 주기는 5분이다. 단, 본보기는 `@EnableScheduling`이 주석 처리되어 있어 코드상 기동 시 초기화만 실행된다. 옮길 때는 스케줄링을 켠다.
- **주문별 예약 내역도 Redis 해시에 둔다.** 해제할 때 DB를 조회하지 않고 되돌릴 수량을 안다.

## 따라 하지 말 것

- **`reserveWithLock`, `reserveWithSpinLock`, `releaseByLock`, `releaseBySpinLock`, `MAIN/infrastructure/redis/SpinLockSupporter.kt`.** Lua 방식과 성능을 비교하려고 만든 것이다. 락으로 직렬화한 뒤 읽기와 차감을 따로 한다. 새로 만들 때는 Lua 방식 하나만 가져간다.
- **`reserve()`와 `reserveWithExpiry()`가 거의 같은 코드다.** 만료 시각을 인자로 받는 메서드 하나로 합친다.
- **10분 주기 재조정은 Redis 값을 MySQL 값으로 통째로 덮어쓴다.** 그 순간 진행 중인 예약과 어긋날 수 있다. 정합성이 중요하면 덮어쓰지 말고 차이를 감지해 알리는 방식으로 바꾼다.
- **락 획득 실패가 `IllegalStateException`이다.** 공통 예외 핸들러에서 500으로 나간다. 옮길 때는 전용 예외를 만들어 409나 429로 응답한다.
- **락 획득/해제마다 INFO 로그를 남긴다.** 트래픽이 많으면 DEBUG로 낮춘다.

## 검증에 쓰는 테스트

동시성 로직을 옮겼으면 반드시 동시 요청 테스트를 쓴다. 형식은 `references/testing.md`의 동시성 항목을 따른다.
