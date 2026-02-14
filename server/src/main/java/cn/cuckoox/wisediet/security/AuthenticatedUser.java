package cn.cuckoox.wisediet.security;

public record AuthenticatedUser(
        Long userId,
        String email,
        Integer onboardingStep,
        String sessionId
) {
}
