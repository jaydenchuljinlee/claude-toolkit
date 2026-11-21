# Kafka 이벤트, 아웃박스, Saga 보상

기준은 `balance`(아웃박스 전체 흐름)와 `payment`(Saga)다.

## 아웃박스: 읽는 순서

1. `MAIN/balance/domain/BalanceService.kt` : `charge()`가 `BalanceChangedEvent`를 발행한다. Service는 Kafka를 모른다.
2. `MAIN/balance/domain/event/BalanceChangedEvent.kt`
3. `MAIN/balance/infrastructure/event/BalanceOutboxEventHandler.kt` : 도메인 이벤트를 `OutboxEventInfo`로 바꿔 다시 발행한다.
4. `MAIN/outboxevent/infrastructure/event/dto/OutboxEventInfo.kt`
5. `MAIN/outboxevent/infrastructure/event/OutboxEventListener.kt` : 저장과 발행이 여기서 갈린다.
6. `MAIN/outboxevent/infrastructure/jpa/entity/OutboxEventEntity.kt`
7. `MAIN/infrastructure/kafka/KafkaProducer.kt`
8. `MAIN/balance/infrastructure/event/BalanceKafkaConsumer.kt`
9. `MAIN/outboxevent/domain/OutboxEventService.kt` : `processFailedOutbox()`가 재시도다.
10. `MAIN/common/schedular/BalanceOutboxScheduler.kt`
11. `MAIN/common/properties/BalanceKafkaProperties.kt`

## 흐름

```
Service (트랜잭션 안) → publishEvent(도메인 이벤트)
  → {Domain}OutboxEventHandler   @EventListener : OutboxEventInfo로 변환해 재발행
  → OutboxEventListener.handleOutboxEvent   @EventListener : outbox 테이블에 INIT으로 저장 (같은 트랜잭션)
  → [커밋]
  → OutboxEventListener.publish   @Async + AFTER_COMMIT : PUBLISH로 바꾸고 Kafka 전송, 실패 시 FAILED
  → {Domain}KafkaConsumer   처리 후 SUCCESS, 예외 시 FAILED
  → 스케줄러   FAILED를 주기적으로 재전송 (retryCnt 증가)
```

## 핵심 아이디어

- **저장은 동기, 발행은 커밋 이후.** outbox 행이 비즈니스 데이터와 같은 트랜잭션으로 저장되므로, 커밋되면 이벤트 기록도 반드시 남는다. Kafka 전송은 커밋 뒤에 따로 하므로 Kafka 장애가 비즈니스 트랜잭션을 롤백시키지 않는다.
- **도메인 서비스는 도메인 이벤트만 발행한다.** 토픽, 그룹, 직렬화는 `infrastructure/event/`의 핸들러가 맡는다.
- **봉투(envelope) 하나로 통일한다.** 모든 토픽이 `OutboxEventInfo`(id, groupId, topic, payload JSON, eventType, schemaVersion)를 실어 보낸다. 컨슈머는 `event.id`로 outbox 행을 찾아 상태를 갱신한다.
- **컨슈머가 스키마 버전을 먼저 검사한다.** `SUPPORTED_VERSIONS`에 없으면 경고 로그만 남기고 건너뛴다.
- **상태는 `INIT → PUBLISH → SUCCESS | FAILED`.** 재시도 대상은 FAILED뿐이다.
- **토픽과 그룹은 설정에서 받는다.** 도메인별 `@ConfigurationProperties` 클래스 하나, 컨슈머는 `@KafkaListener`에서 같은 설정 키를 참조한다.

## 따라 하지 말 것

- **본보기는 `@EnableScheduling`이 주석 처리되어 있고 `@EnableAsync`가 없다.** 코드상 재시도 스케줄러는 돌지 않고, `@Async`가 붙은 `publish`는 커밋 직후 같은 스레드에서 동기로 실행된다. 옮길 때는 둘 다 켠다.
- **트랜잭션 밖에서 `OutboxEventInfo`를 발행하지 않는다.** `publish`는 `@TransactionalEventListener(AFTER_COMMIT)`이고 `fallbackExecution` 설정이 없어서, 활성 트랜잭션이 없으면 Spring이 이 리스너를 실행하지 않는다. `MAIN/order/usecase/OrderFacade.kt`의 `order()`는 `@Transactional` 없이 발행하므로 코드상 outbox 행이 INIT으로만 남는다. `MAIN/payment/domain/PaymentService.kt`의 `pay()`처럼 `@Transactional` 메서드 안에서 발행한다.
- **INIT이나 PUBLISH에 멈춘 행은 재시도되지 않는다.** 전송 직전에 프로세스가 죽으면 그대로 남는다. 옮길 때는 "일정 시간 지난 INIT/PUBLISH"도 재시도 대상에 넣는다.
- **`BalanceOutboxScheduler`는 토픽명 `"PAY_HISTORY"`가 하드코딩이고 메서드명도 맞지 않는다.** 재시도 토픽은 설정 클래스에서 받는다.
- **컨슈머에 멱등 처리가 없다.** 재전송되면 같은 이벤트를 두 번 처리한다. `event.id`로 이미 SUCCESS인지 확인하고 건너뛰는 검사를 넣는다.
- **`payload.id == "ERROR"`면 예외를 던지는 테스트용 분기**가 컨슈머와 리스너에 들어 있다. 옮기지 않는다.
- **`MAIN/payment/infrastructure/event/PaymentSpringEventListener.kt`** 는 `@EventListener`와 `@TransactionalEventListener`를 같이 붙였다. 하나만 쓴다.
- **`MAIN/notification/infrastructure/event/NotificationEventPublisher.kt`** 는 outbox를 거치지 않고 Kafka로 바로 보내며 실패를 삼킨다. 유실돼도 되는 알림이라서 그렇다. 유실되면 안 되는 이벤트에 이 방식을 쓰지 않는다.

## Saga 보상: 읽는 순서

1. `MAIN/payment/usecase/PaymentFacade.kt` : `pay()`와 `compensate()`.
2. `MAIN/payment/domain/PaymentSagaService.kt`
3. `MAIN/payment/common/PaymentSagaStatus.kt`
4. `MAIN/payment/infrastructure/jpa/entity/PaymentSagaEntity.kt`
5. `MAIN/common/schedular/PaymentSagaRecoveryScheduler.kt`

## Saga 핵심 아이디어

- **한 프로세스 안의 오케스트레이션 Saga다.** Facade가 단계(잔액 차감, 포인트 차감, 결제 생성, 주문 확정, 재고 확정)를 순서대로 호출하고, 각 단계는 자기 트랜잭션으로 커밋한다.
- **어디까지 성공했는지 플래그로 기억한다.** `balanceDeducted` 같은 단계별 플래그를 보고 성공한 단계만 역순으로 되돌린다.
- **Saga 상태 기록은 `REQUIRES_NEW`다.** 본 흐름이 롤백돼도 진행 기록은 남는다.
- **보상마저 실패하면 `COMPENSATION_FAILED`로 남긴다.** 스케줄러가 주기적으로 찾아 경고 로그를 낸다. 자동 복구가 아니라 사람이 처리하라는 신호다.

## Saga에서 따라 하지 말 것

- **`PaymentSagaService.updateStatus(sagaId, ...)`** 는 인자 이름은 sagaId인데 `findByOrderId`로 조회한다. `updateStatusByOrderId`만 참고한다.
- **결제 생성과 주문 확정에는 보상이 없다.** 그 뒤 단계에서 실패하면 결제 행이 PAID로, 주문이 CONFIRMED로 남는다. 옮길 때는 모든 단계에 되돌리는 동작을 짝지어 둔다.
