# Today's Meal Recommendations API Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create backend API for daily meal recommendations with mock data, enabling the "Today" feed screen.

**Architecture:** Two new tables (`meal_plans`, `dishes`) with R2DBC entities. A `TodayService` generates mock N+1 dish recommendations per user. `TodayController` exposes two reactive endpoints behind existing JWT + OnboardingGate security. All data is user-scoped via `CurrentUserService`.

**Tech Stack:** Spring Boot 4.x, Spring WebFlux, Spring Data R2DBC, Reactor, JUnit 5 + Testcontainers

---

### Task 1: Database Schema — Add `meal_plans` and `dishes` tables

**Files:**
- Modify: `server/src/main/resources/schema.sql`

**Step 1: Add the DDL**

Append to `schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS "meal_plans" (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS "dishes" (
    id SERIAL PRIMARY KEY,
    meal_plan_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    recommendation_reason TEXT,
    image_url TEXT,
    difficulty INT DEFAULT 3,
    prep_min INT DEFAULT 10,
    cook_min INT DEFAULT 10,
    nutrient_tags TEXT,
    selected BOOLEAN DEFAULT FALSE,
    meal_type VARCHAR(20) NOT NULL
);
```

**Step 2: Commit**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
git add src/main/resources/schema.sql
git commit -m "feat: add meal_plans and dishes tables to schema"
```

---

### Task 2: Entity Classes — `MealPlan` and `Dish`

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/model/MealPlan.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/model/Dish.java`

**Step 1: Create `MealPlan` entity**

```java
package cn.cuckoox.wisediet.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDate;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("meal_plans")
public class MealPlan {
    @Id
    private Long id;
    private Long userId;
    private LocalDate date;
    private String status;
}
```

**Step 2: Create `Dish` entity**

```java
package cn.cuckoox.wisediet.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Table("dishes")
public class Dish {
    @Id
    private Long id;
    private Long mealPlanId;
    private String name;
    private String recommendationReason;
    private String imageUrl;
    private Integer difficulty;
    private Integer prepMin;
    private Integer cookMin;
    private String nutrientTags;
    private Boolean selected;
    private String mealType;
}
```

**Step 3: Commit**

```bash
git add src/main/java/cn/cuckoox/wisediet/model/MealPlan.java src/main/java/cn/cuckoox/wisediet/model/Dish.java
git commit -m "feat: add MealPlan and Dish entity classes"
```

---

### Task 3: Repositories — `MealPlanRepository` and `DishRepository`

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/repository/MealPlanRepository.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/repository/DishRepository.java`

**Step 1: Create `MealPlanRepository`**

```java
package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.MealPlan;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.time.LocalDate;

@Repository
public interface MealPlanRepository extends R2dbcRepository<MealPlan, Long> {
    Mono<MealPlan> findByUserIdAndDate(Long userId, LocalDate date);
}
```

**Step 2: Create `DishRepository`**

```java
package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.Dish;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.List;

@Repository
public interface DishRepository extends R2dbcRepository<Dish, Long> {
    Flux<Dish> findByMealPlanId(Long mealPlanId);
    Flux<Dish> findByMealPlanIdAndIdIn(Long mealPlanId, List<Long> ids);
}
```

**Step 3: Commit**

```bash
git add src/main/java/cn/cuckoox/wisediet/repository/MealPlanRepository.java src/main/java/cn/cuckoox/wisediet/repository/DishRepository.java
git commit -m "feat: add MealPlanRepository and DishRepository"
```

---

### Task 4: DTO Classes — `MealPlanResponse` and `ConfirmMenuRequest`

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/MealPlanResponse.java`
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/dto/ConfirmMenuRequest.java`

**Step 1: Create `MealPlanResponse`**

```java
package cn.cuckoox.wisediet.controller.dto;

import cn.cuckoox.wisediet.model.Dish;
import cn.cuckoox.wisediet.model.MealPlan;

import java.time.LocalDate;
import java.util.List;

public record MealPlanResponse(
        Long id,
        LocalDate date,
        String status,
        List<Dish> dishes
) {
    public static MealPlanResponse from(MealPlan plan, List<Dish> dishes) {
        return new MealPlanResponse(plan.getId(), plan.getDate(), plan.getStatus(), dishes);
    }
}
```

**Step 2: Create `ConfirmMenuRequest`**

```java
package cn.cuckoox.wisediet.controller.dto;

import java.util.List;

public record ConfirmMenuRequest(List<Long> dishIds) {}
```

**Step 3: Commit**

```bash
git add src/main/java/cn/cuckoox/wisediet/controller/dto/MealPlanResponse.java src/main/java/cn/cuckoox/wisediet/controller/dto/ConfirmMenuRequest.java
git commit -m "feat: add MealPlanResponse and ConfirmMenuRequest DTOs"
```

---

### Task 5: Service — `TodayService` with mock data generation

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/service/TodayService.java`

**Step 1: Create `TodayService`**

The service has two public methods:
- `getOrCreateTodayPlan(Long userId)` — finds or creates today's meal plan with 3 mock dishes
- `confirmMenu(Long userId, List<Long> dishIds)` — marks selected dishes and sets status to confirmed

```java
package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.MealPlanResponse;
import cn.cuckoox.wisediet.model.Dish;
import cn.cuckoox.wisediet.model.MealPlan;
import cn.cuckoox.wisediet.repository.DishRepository;
import cn.cuckoox.wisediet.repository.MealPlanRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDate;
import java.util.List;

@Service
public class TodayService {

    private final MealPlanRepository mealPlanRepository;
    private final DishRepository dishRepository;

    public TodayService(MealPlanRepository mealPlanRepository, DishRepository dishRepository) {
        this.mealPlanRepository = mealPlanRepository;
        this.dishRepository = dishRepository;
    }

    public Mono<MealPlanResponse> getOrCreateTodayPlan(Long userId) {
        LocalDate today = LocalDate.now();
        return mealPlanRepository.findByUserIdAndDate(userId, today)
                .flatMap(this::buildResponse)
                .switchIfEmpty(createMockPlan(userId, today).flatMap(this::buildResponse));
    }

    public Mono<MealPlanResponse> confirmMenu(Long userId, List<Long> dishIds) {
        LocalDate today = LocalDate.now();
        return mealPlanRepository.findByUserIdAndDate(userId, today)
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND, "No meal plan for today")))
                .flatMap(plan -> {
                    plan.setStatus("confirmed");
                    return mealPlanRepository.save(plan)
                            .then(dishRepository.findByMealPlanId(plan.getId())
                                    .flatMap(dish -> {
                                        dish.setSelected(dishIds.contains(dish.getId()));
                                        return dishRepository.save(dish);
                                    })
                                    .then())
                            .then(buildResponse(plan));
                });
    }

    private Mono<MealPlanResponse> buildResponse(MealPlan plan) {
        return dishRepository.findByMealPlanId(plan.getId())
                .collectList()
                .map(dishes -> MealPlanResponse.from(plan, dishes));
    }

    private Mono<MealPlan> createMockPlan(Long userId, LocalDate date) {
        MealPlan plan = new MealPlan(null, userId, date, "pending");
        return mealPlanRepository.save(plan)
                .flatMap(savedPlan -> {
                    List<Dish> mockDishes = List.of(
                            new Dish(null, savedPlan.getId(), "Grilled Salmon & Asparagus",
                                    "Rich in B vitamins for sustained energy during long work sessions",
                                    null, 3, 10, 20, "High Protein,Omega-3", false, "dinner"),
                            new Dish(null, savedPlan.getId(), "Quinoa Avocado Salad",
                                    "Light lunch for focus — low GI to avoid afternoon crash",
                                    null, 2, 10, 0, "Low GI,High Fiber", false, "lunch"),
                            new Dish(null, savedPlan.getId(), "Zucchini Noodles Pesto",
                                    "Low carb dinner to support recovery and restful sleep",
                                    null, 3, 10, 15, "Low Carb,Vitamins", false, "dinner")
                    );
                    return Flux.fromIterable(mockDishes)
                            .flatMap(dishRepository::save)
                            .then(Mono.just(savedPlan));
                });
    }
}
```

**Step 2: Commit**

```bash
git add src/main/java/cn/cuckoox/wisediet/service/TodayService.java
git commit -m "feat: add TodayService with mock meal plan generation"
```

---

### Task 6: Controller — `TodayController`

**Files:**
- Create: `server/src/main/java/cn/cuckoox/wisediet/controller/TodayController.java`

**Step 1: Create `TodayController`**

```java
package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.ConfirmMenuRequest;
import cn.cuckoox.wisediet.controller.dto.MealPlanResponse;
import cn.cuckoox.wisediet.security.CurrentUserService;
import cn.cuckoox.wisediet.service.TodayService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/today")
public class TodayController {

    private final TodayService todayService;
    private final CurrentUserService currentUserService;

    public TodayController(TodayService todayService, CurrentUserService currentUserService) {
        this.todayService = todayService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/recommendations")
    public Mono<MealPlanResponse> getRecommendations() {
        return currentUserService.currentUserId()
                .flatMap(todayService::getOrCreateTodayPlan);
    }

    @PostMapping("/confirm")
    public Mono<MealPlanResponse> confirmMenu(@RequestBody ConfirmMenuRequest request) {
        return currentUserService.currentUserId()
                .flatMap(userId -> todayService.confirmMenu(userId, request.dishIds()));
    }
}
```

**Step 2: Commit**

```bash
git add src/main/java/cn/cuckoox/wisediet/controller/TodayController.java
git commit -m "feat: add TodayController with recommendations and confirm endpoints"
```

---

### Task 7: Integration Test — `TodayApiIntegrationTest`

**Files:**
- Create: `server/src/test/java/cn/cuckoox/wisediet/TodayApiIntegrationTest.java`

**Context:**
- Extends `AbstractIntegrationTest` (same pattern as `OnboardingApiIntegrationTest`)
- Uses `issueAuthenticatedToken()` helper to create a user with `onboardingStep=0` (completed onboarding)
- Tests: unauthenticated 401, get recommendations 200, confirm menu 200

**Step 1: Write the integration test**

```java
package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.controller.dto.ConfirmMenuRequest;
import cn.cuckoox.wisediet.controller.dto.MealPlanResponse;
import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

import java.time.Duration;
import java.util.List;

class TodayApiIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void shouldReturn401WhenNotAuthenticated() {
        Mono<Boolean> flow = Mono.fromCallable(() -> {
            webTestClient.get()
                    .uri("/api/today/recommendations")
                    .exchange()
                    .expectStatus().isUnauthorized();
            return true;
        });

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturn403WhenOnboardingNotComplete() {
        Mono<Boolean> flow = issueAuthenticatedToken(1)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isForbidden();
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturnMockRecommendations() {
        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .value(response -> {
                                if (response.dishes() == null || response.dishes().size() != 3) {
                                    throw new AssertionError("Expected 3 mock dishes, got: " +
                                            (response.dishes() == null ? "null" : response.dishes().size()));
                                }
                                if (!"pending".equals(response.status())) {
                                    throw new AssertionError("Expected pending status, got: " + response.status());
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldReturnSamePlanOnSecondCall() {
        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    // First call creates the plan
                    MealPlanResponse first = webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .returnResult().getResponseBody();

                    // Second call returns the same plan
                    webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .value(second -> {
                                if (!first.id().equals(second.id())) {
                                    throw new AssertionError("Expected same plan ID on second call");
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    @Test
    void shouldConfirmMenuWithSelectedDishes() {
        Mono<Boolean> flow = issueAuthenticatedToken(0)
                .flatMap(token -> Mono.fromCallable(() -> {
                    // First get recommendations
                    MealPlanResponse plan = webTestClient.get()
                            .uri("/api/today/recommendations")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .returnResult().getResponseBody();

                    // Confirm with first two dishes
                    List<Long> selectedIds = List.of(
                            plan.dishes().get(0).getId(),
                            plan.dishes().get(1).getId()
                    );

                    webTestClient.post()
                            .uri("/api/today/confirm")
                            .header("Authorization", "Bearer " + token)
                            .bodyValue(new ConfirmMenuRequest(selectedIds))
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(MealPlanResponse.class)
                            .value(confirmed -> {
                                if (!"confirmed".equals(confirmed.status())) {
                                    throw new AssertionError("Expected confirmed status");
                                }
                                long selectedCount = confirmed.dishes().stream()
                                        .filter(d -> Boolean.TRUE.equals(d.getSelected()))
                                        .count();
                                if (selectedCount != 2) {
                                    throw new AssertionError("Expected 2 selected dishes, got: " + selectedCount);
                                }
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow)
                .expectNext(true)
                .verifyComplete();
    }

    private Mono<String> issueAuthenticatedToken(Integer onboardingStep) {
        String uniqueEmail = "today-api-" + System.nanoTime() + "@test.com";
        return userRepository.save(new User(null, uniqueEmail, "google", "today-provider-" + System.nanoTime(), onboardingStep))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }
}
```

**Step 2: Run tests to verify they pass**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test -pl . -Dtest=TodayApiIntegrationTest -Dmaven.test.timeout=120
```

Expected: All 5 tests PASS.

**Step 3: Commit**

```bash
git add src/test/java/cn/cuckoox/wisediet/TodayApiIntegrationTest.java
git commit -m "test: add integration tests for Today recommendations API"
```

---

### Task 8: Final Verification — Run full test suite

**Step 1: Run all tests**

```bash
cd /Users/y/IdeaProjects/WiseDiet/server
./mvnw test -Dmaven.test.timeout=120
```

Expected: All existing tests + new `TodayApiIntegrationTest` pass. No regressions.

**Step 2: Commit all changes together if any fixups needed**

```bash
git add -A
git commit -m "feat: complete Today recommendations API with mock data"
```
