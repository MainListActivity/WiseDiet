package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/onboarding")
public class OnboardingController {

    private final UserProfileRepository userProfileRepository;

    public OnboardingController(UserProfileRepository userProfileRepository) {
        this.userProfileRepository = userProfileRepository;
    }

    @PostMapping("/profile")
    public Mono<UserProfile> saveProfile(@RequestBody UserProfile profile) {
        return userProfileRepository.save(profile);
    }

    @GetMapping("/strategy")
    public Mono<Map<String, Object>> getStrategy() {
        // Mock Strategy Report
        Map<String, Object> response = new HashMap<>();
        response.put("date", LocalDate.now().toString());
        response.put("title", "Personalized Health Strategy");
        response.put("summary", "Based on your occupation as a Programmer (Sedentary), we have tailored a Low-GI diet plan to maintain your energy levels throughout the day and protect your eyes.");

        Map<String, String> keyPoints = new HashMap<>();
        keyPoints.put("Energy", "Stable release carbs to avoid afternoon crash.");
        keyPoints.put("Eyes", "Lutein-rich foods for screen time protection.");
        keyPoints.put("Stress", "Magnesium-rich ingredients for nervous system support.");

        response.put("key_points", keyPoints);

        return Mono.just(response);
    }
}
