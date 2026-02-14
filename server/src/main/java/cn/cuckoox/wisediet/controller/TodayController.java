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
