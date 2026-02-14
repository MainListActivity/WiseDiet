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
