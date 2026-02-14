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
