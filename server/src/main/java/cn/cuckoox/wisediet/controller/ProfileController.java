package cn.cuckoox.wisediet.controller;

import cn.cuckoox.wisediet.controller.dto.ProfileUpdateRequest;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.security.CurrentUserService;
import cn.cuckoox.wisediet.service.ProfileService;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    private final ProfileService profileService;
    private final CurrentUserService currentUserService;

    public ProfileController(ProfileService profileService, CurrentUserService currentUserService) {
        this.profileService = profileService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    public Mono<UserProfile> getProfile() {
        return currentUserService.currentUserId()
                .flatMap(profileService::getProfile);
    }

    @PatchMapping
    public Mono<UserProfile> patchProfile(@RequestBody ProfileUpdateRequest request) {
        return currentUserService.currentUserId()
                .flatMap(userId -> profileService.patchProfile(userId, request));
    }
}
