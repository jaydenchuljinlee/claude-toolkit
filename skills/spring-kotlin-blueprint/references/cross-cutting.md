# 공통 관심사: 예외 응답, 캐시, RateLimit, 스케줄러, 인증

전부 `MAIN/common/` 아래에 있다.

## 예외와 응답 형식

읽을 파일:

1. `MAIN/common/exception/ServiceException.kt` (같은 디렉터리의 `ControllerException`, `FacadeException`, `RepositoryException`도 같은 모양)
2. `MAIN/common/advice/ApiControllerAdvice.kt`
3. `MAIN/common/dto/CustomApiResponse.kt`, `MAIN/common/dto/CustomErrorResponse.kt`

핵심 아이디어:

- **예외를 "어느 계층에서 났는가"로 나눈다.** 계층별 추상 예외를 두고, 도메인 예외가 그것을 상속한다. 핸들러는 계층 타입만 보고 상태 코드를 정한다: Controller 400, Service 422, Facade 422, Repository 500, RateLimit 429.
- **성공 응답은 `CustomApiResponse.success(data)` 하나로 감싼다.**

따라 하지 말 것:

- **`CustomErrorResponse.fail()`은 본문의 `code`와 `status`를 항상 500으로 채운다.** HTTP 상태는 400이나 422인데 본문은 500이 된다. 옮길 때는 상태를 인자로 받는다.
- **"없음"이 `RepositoryException`이라 500으로 나간다.** 조회 실패는 404로 매핑되는 예외를 따로 둔다.
- **마지막 `Exception` 핸들러가 `e.message`를 그대로 응답한다.** 내부 메시지가 노출된다. 고정 문구를 쓴다.

## 캐시

읽을 파일: `MAIN/common/anotation/RedisCacheable.kt`, `MAIN/common/anotation/aspect/RedisCacheableAspect.kt`, 사용 예 `MAIN/product/domain/ProductService.kt`의 `getProductCache()`.

- SpEL 키, TTL 지정, 반환 타입 기반 JSON 코덱으로 Redis에 저장하는 커스텀 애너테이션이다.
- 조회될 때마다 TTL을 다시 늘린다. 자주 읽히는 키는 만료되지 않으므로, 데이터가 바뀌면 명시적으로 지워야 한다.
- **제약:** 포인트컷이 `args(dto)`라서 인자가 정확히 하나인 메서드에만 걸리고, SpEL 변수명이 `#dto`로 고정이다. 옮길 때는 `RateLimitAspect`의 `parseKey()`처럼 실제 파라미터 이름을 쓰게 바꾼다.
- 같은 서비스에 Spring `@Cacheable`도 섞여 있다. 대상 프로젝트에서는 한 가지 방식만 쓴다.

## RateLimit

읽을 파일: `MAIN/common/anotation/RateLimit.kt`, `MAIN/common/anotation/aspect/RateLimitAspect.kt`, 사용 예 `MAIN/order/api/IOrderController.kt`.

- Redisson `RRateLimiter`로 "메서드명 + SpEL 키"별 한도를 건다. 초과하면 `RateLimitExceededException`, 응답은 429다.
- 컨트롤러 인터페이스 메서드에 붙인다.
- **주의:** 키가 요청 본문의 `userId`다. 인증이 있는 프로젝트에서는 인증된 사용자 ID를 키로 쓴다.

## 스케줄러

읽을 파일: `MAIN/common/schedular/StockReservationExpiryScheduler.kt`, `MAIN/common/config/SchedulerConfig.kt`.

- 스케줄러 클래스는 주기만 정하고 Service 메서드 하나를 호출한다. 로직은 Service에 있어서 단위 테스트가 쉽다.
- **주의:** `SchedulerConfig`의 `@EnableScheduling`이 주석 처리되어 있어 본보기의 `@Scheduled` 메서드는 코드상 실행되지 않는다. `@EnableAsync`도 없다. 옮길 때는 둘 다 켠다.
- **주의:** 여러 인스턴스로 띄우면 모든 인스턴스가 같은 작업을 돌린다. 본보기에는 중복 실행 방지가 없다. 다중 인스턴스 환경이면 ShedLock이나 분산락을 건다.

## 요청 추적

읽을 파일: `MAIN/common/filter/MdcFilter.kt`. 요청마다 UUID를 MDC에 넣어 로그를 묶는다. 옮길 때는 `MDC.clear()`를 `finally`에 둔다 (본보기는 예외 시 지워지지 않는다).

## 인증: 본보기로 쓰지 않는다

`MAIN/common/filter/JwtTokenFilter.kt`와 `MAIN/common/config/WebMvcConfig.kt`는 빈 등록 애너테이션이 주석 처리되어 **동작하지 않는 코드**다. `MAIN/common/interceptor/AdminInterceptor.kt`도 등록되지 않는다. 구조 참고만 가능하고, 인증이 필요하면 대상 프로젝트의 방식이나 Spring Security를 쓴다.
