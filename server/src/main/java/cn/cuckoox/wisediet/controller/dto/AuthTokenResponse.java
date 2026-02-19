package cn.cuckoox.wisediet.controller.dto;

public record AuthTokenResponse(String accessToken, String refreshToken, int onboardingStep) {
}
