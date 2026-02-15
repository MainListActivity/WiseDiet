package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.MealPlanResponse;
import cn.cuckoox.wisediet.model.Dish;
import cn.cuckoox.wisediet.model.MealPlan;
import cn.cuckoox.wisediet.repository.DishRepository;
import cn.cuckoox.wisediet.repository.MealPlanRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TodayServiceTest {

    @Mock
    private MealPlanRepository mealPlanRepository;
    @Mock
    private DishRepository dishRepository;

    @Test
    void shouldCreateMockPlanWithFourMealTypesAndNutritionMetadata() {
        TodayService service = new TodayService(mealPlanRepository, dishRepository);
        MealPlan savedPlan = new MealPlan(100L, 8L, LocalDate.now(), "pending");

        when(mealPlanRepository.findByUserIdAndDate(eq(8L), any(LocalDate.class))).thenReturn(Mono.empty());
        when(mealPlanRepository.save(any(MealPlan.class))).thenReturn(Mono.just(savedPlan));

        ArgumentCaptor<Dish> createdDish = ArgumentCaptor.forClass(Dish.class);
        when(dishRepository.save(createdDish.capture())).thenAnswer(invocation -> {
            Dish dish = invocation.getArgument(0);
            dish.setId((long) createdDish.getAllValues().size());
            return Mono.just(dish);
        });

        when(dishRepository.findByMealPlanId(anyLong())).thenAnswer(invocation -> Flux.fromIterable(createdDish.getAllValues()));

        Mono<MealPlanResponse> responseMono = service.getOrCreateTodayPlan(8L);

        StepVerifier.create(responseMono)
                .assertNext(response -> {
                    assertThat(response.dishes()).hasSize(8);
                    Set<String> mealTypes = response.dishes().stream()
                            .map(dish -> dish.getMealType().toLowerCase(Locale.ROOT))
                            .collect(Collectors.toSet());
                    assertThat(mealTypes).containsExactlyInAnyOrder("breakfast", "lunch", "snack", "dinner");
                    assertThat(response.dishes()).allSatisfy(dish -> {
                        assertThat(dish.getImageUrl()).isNotBlank();
                        assertThat(dish.getNutrientTags()).isNotBlank();
                    });
                })
                .verifyComplete();
    }
}
