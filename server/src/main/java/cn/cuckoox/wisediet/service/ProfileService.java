package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.controller.dto.ProfileUpdateRequest;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

@Service
public class ProfileService {

    private final UserProfileRepository userProfileRepository;

    public ProfileService(UserProfileRepository userProfileRepository) {
        this.userProfileRepository = userProfileRepository;
    }

    public Mono<UserProfile> getProfile(Long userId) {
        return userProfileRepository.findByUserId(userId)
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found")));
    }

    public Mono<UserProfile> patchProfile(Long userId, ProfileUpdateRequest req) {
        return userProfileRepository.findByUserId(userId)
                .switchIfEmpty(Mono.error(new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found")))
                .flatMap(profile -> {
                    if (req.gender() != null) profile.setGender(req.gender());
                    if (req.age() != null) profile.setAge(req.age());
                    if (req.height() != null) profile.setHeight(req.height());
                    if (req.weight() != null) profile.setWeight(req.weight());
                    if (req.familyMembers() != null) profile.setFamilyMembers(req.familyMembers());
                    if (req.occupationTagIds() != null) profile.setOccupationTagIds(req.occupationTagIds());
                    if (req.allergenTagIds() != null) profile.setAllergenTagIds(req.allergenTagIds());
                    if (req.dietaryPreferenceTagIds() != null) profile.setDietaryPreferenceTagIds(req.dietaryPreferenceTagIds());
                    if (req.customAvoidedIngredients() != null) profile.setCustomAvoidedIngredients(req.customAvoidedIngredients());
                    return userProfileRepository.save(profile);
                });
    }
}
