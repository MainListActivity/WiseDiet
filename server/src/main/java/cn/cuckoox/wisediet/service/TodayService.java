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
                            new Dish(null, savedPlan.getId(), "Greek Yogurt Berry Bowl",
                                    "High-protein breakfast to stabilize morning blood sugar",
                                    "https://images.unsplash.com/photo-1488477181946-6428a0291777", 1, 5, 5, "High Protein,Probiotics", false, "breakfast"),
                            new Dish(null, savedPlan.getId(), "Spinach Egg Wrap",
                                    "Iron-rich greens with eggs for longer satiety",
                                    "https://images.unsplash.com/photo-1513442542250-854d436a73f2", 2, 8, 6, "Iron,High Protein", false, "breakfast"),
                            new Dish(null, savedPlan.getId(), "Quinoa Avocado Salad",
                                    "Low GI lunch to avoid afternoon energy crash",
                                    "https://images.unsplash.com/photo-1546069901-ba9599a7e63c", 2, 10, 8, "Low GI,High Fiber", false, "lunch"),
                            new Dish(null, savedPlan.getId(), "Miso Chicken Rice Bowl",
                                    "Balanced carb + lean protein for focused work blocks",
                                    "https://images.unsplash.com/photo-1512621776951-a57141f2eefd", 3, 12, 14, "Lean Protein,B Vitamins", false, "lunch"),
                            new Dish(null, savedPlan.getId(), "Apple Peanut Butter Cups",
                                    "Portable snack with fiber and healthy fats",
                                    "https://images.unsplash.com/photo-1560807707-8cc77767d783", 1, 5, 3, "Fiber,Healthy Fats", false, "snack"),
                            new Dish(null, savedPlan.getId(), "Edamame Citrus Mix",
                                    "Plant protein snack to curb pre-dinner cravings",
                                    "https://images.unsplash.com/photo-1615486363979-110f1dc7f9c3", 1, 6, 4, "Plant Protein,Vitamin C", false, "snack"),
                            new Dish(null, savedPlan.getId(), "Grilled Salmon & Asparagus",
                                    "Omega-3 rich dinner supports recovery after long days",
                                    "https://images.unsplash.com/photo-1467003909585-2f8a72700288", 3, 10, 20, "Omega-3,High Protein", false, "dinner"),
                            new Dish(null, savedPlan.getId(), "Zucchini Noodles Pesto",
                                    "Lower-carb dinner helps avoid late-night heaviness",
                                    "https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5", 2, 10, 15, "Low Carb,Vitamins", false, "dinner")
                    );
                    return Flux.fromIterable(mockDishes)
                            .flatMap(dishRepository::save)
                            .then(Mono.just(savedPlan));
                });
    }
}
