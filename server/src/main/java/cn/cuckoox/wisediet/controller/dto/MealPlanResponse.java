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
