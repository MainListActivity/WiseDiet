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
