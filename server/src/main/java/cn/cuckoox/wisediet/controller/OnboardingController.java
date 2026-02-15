package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.i18n.RequestLocaleResolver;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import org.springframework.context.MessageSource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ServerWebExchange;
import jakarta.validation.Valid;
import reactor.core.publisher.Mono;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/onboarding")
public class OnboardingController {

    private final UserProfileRepository userProfileRepository;
    private final MessageSource messageSource;
    private final RequestLocaleResolver requestLocaleResolver;

    public OnboardingController(UserProfileRepository userProfileRepository,
                                MessageSource messageSource,
                                RequestLocaleResolver requestLocaleResolver) {
        this.userProfileRepository = userProfileRepository;
        this.messageSource = messageSource;
        this.requestLocaleResolver = requestLocaleResolver;
    }

    @PostMapping("/profile")
    public Mono<UserProfile> saveProfile(@Valid @RequestBody UserProfile profile) {
        return userProfileRepository.save(profile);
    }

    @GetMapping("/strategy")
    public Mono<Map<String, Object>> getStrategy(ServerWebExchange exchange) {
        var locale = requestLocaleResolver.resolve(exchange);
        Map<String, Object> response = new HashMap<>();
        response.put("date", LocalDate.now().toString());
        response.put("title", messageSource.getMessage("onboarding.strategy.title", null, locale));
        response.put("summary", messageSource.getMessage("onboarding.strategy.summary", null, locale));

        Map<String, String> keyPoints = new LinkedHashMap<>();
        keyPoints.put(
                messageSource.getMessage("onboarding.strategy.key.energy", null, locale),
                messageSource.getMessage("onboarding.strategy.value.energy", null, locale)
        );
        keyPoints.put(
                messageSource.getMessage("onboarding.strategy.key.eyes", null, locale),
                messageSource.getMessage("onboarding.strategy.value.eyes", null, locale)
        );
        keyPoints.put(
                messageSource.getMessage("onboarding.strategy.key.stress", null, locale),
                messageSource.getMessage("onboarding.strategy.value.stress", null, locale)
        );

        response.put("key_points", keyPoints);
        Map<String, String> projectedImpact = new LinkedHashMap<>();
        projectedImpact.put("focus_boost", messageSource.getMessage("onboarding.strategy.impact.focusBoost", null, locale));
        projectedImpact.put("calorie_target", messageSource.getMessage("onboarding.strategy.impact.calorieTarget", null, locale));
        response.put("projected_impact", projectedImpact);

        Map<String, String> preferences = new LinkedHashMap<>();
        preferences.put("daily_focus", messageSource.getMessage("onboarding.strategy.preference.dailyFocus", null, locale));
        preferences.put("meal_frequency", messageSource.getMessage("onboarding.strategy.preference.mealFrequency", null, locale));
        preferences.put("cooking_level", messageSource.getMessage("onboarding.strategy.preference.cookingLevel", null, locale));
        preferences.put("budget", messageSource.getMessage("onboarding.strategy.preference.budget", null, locale));
        response.put("preferences", preferences);

        response.put("info_hint", messageSource.getMessage("onboarding.strategy.infoHint", null, locale));
        response.put("cta_text", messageSource.getMessage("onboarding.strategy.ctaText", null, locale));

        return Mono.just(response);
    }
}
