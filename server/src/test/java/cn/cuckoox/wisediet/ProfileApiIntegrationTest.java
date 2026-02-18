package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import cn.cuckoox.wisediet.repository.UserRepository;
import cn.cuckoox.wisediet.service.JwtService;
import cn.cuckoox.wisediet.service.SessionStore;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.test.StepVerifier;

import java.time.Duration;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

public class ProfileApiIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private UserProfileRepository userProfileRepository;
    @Autowired
    private JwtService jwtService;
    @Autowired
    private SessionStore sessionStore;

    @Test
    void getProfile_withoutToken_returns401() {
        webTestClient.get().uri("/api/profile")
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void getProfile_whenProfileExists_returns200WithData() {
        Mono<Boolean> flow = createUserWithProfile("get-profile@test.com")
                .flatMap(pair -> Mono.fromCallable(() -> {
                    webTestClient.get().uri("/api/profile")
                            .header("Authorization", "Bearer " + pair.token())
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(UserProfile.class)
                            .value(profile -> {
                                assertThat(profile.getGender()).isEqualTo("Male");
                                assertThat(profile.getAge()).isEqualTo(30);
                                assertThat(profile.getHeight()).isEqualTo(175.0);
                                assertThat(profile.getWeight()).isEqualTo(75.0);
                                assertThat(profile.getFamilyMembers()).isEqualTo(2);
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    @Test
    void getProfile_whenNoProfile_returns404() {
        Mono<Boolean> flow = createUserToken("no-profile@test.com")
                .flatMap(token -> Mono.fromCallable(() -> {
                    webTestClient.get().uri("/api/profile")
                            .header("Authorization", "Bearer " + token)
                            .exchange()
                            .expectStatus().isNotFound();
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    @Test
    void patchProfile_withoutToken_returns401() {
        webTestClient.patch().uri("/api/profile")
                .bodyValue(Map.of("weight", 80.0))
                .exchange()
                .expectStatus().isUnauthorized();
    }

    @Test
    void patchProfile_updatesWeightOnly() {
        Mono<Boolean> flow = createUserWithProfile("patch-weight@test.com")
                .flatMap(pair -> Mono.fromCallable(() -> {
                    webTestClient.patch().uri("/api/profile")
                            .header("Authorization", "Bearer " + pair.token())
                            .header("Content-Type", "application/json")
                            .bodyValue(Map.of("weight", 80.5))
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(UserProfile.class)
                            .value(profile -> {
                                assertThat(profile.getWeight()).isEqualTo(80.5);
                                assertThat(profile.getAge()).isEqualTo(30);
                            });
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    @Test
    void patchProfile_updatesOccupationTags() {
        Mono<Boolean> flow = createUserWithProfile("patch-tags@test.com")
                .flatMap(pair -> Mono.fromCallable(() -> {
                    webTestClient.patch().uri("/api/profile")
                            .header("Authorization", "Bearer " + pair.token())
                            .header("Content-Type", "application/json")
                            .bodyValue(Map.of("occupationTagIds", "3,4,5"))
                            .exchange()
                            .expectStatus().isOk()
                            .expectBody(UserProfile.class)
                            .value(profile -> assertThat(profile.getOccupationTagIds()).isEqualTo("3,4,5"));
                    return true;
                }).subscribeOn(Schedulers.boundedElastic()));

        StepVerifier.create(flow).expectNext(true).verifyComplete();
    }

    record UserTokenPair(Long userId, String token) {}

    private Mono<String> createUserToken(String email) {
        return userRepository.save(new User(null, email, "google",
                        "profile-test-provider-" + System.nanoTime(), 0))
                .flatMap(user -> jwtService.createAccessToken(user.getId())
                        .flatMap(token -> sessionStore.saveSession(
                                jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                .thenReturn(token)));
    }

    private Mono<UserTokenPair> createUserWithProfile(String email) {
        return userRepository.save(new User(null, email, "google",
                        "profile-test-provider-" + System.nanoTime(), 0))
                .flatMap(user -> {
                    UserProfile profile = new UserProfile();
                    profile.setUserId(user.getId());
                    profile.setGender("Male");
                    profile.setAge(30);
                    profile.setHeight(175.0);
                    profile.setWeight(75.0);
                    profile.setFamilyMembers(2);
                    profile.setOccupationTagIds("1,2");
                    return userProfileRepository.save(profile)
                            .then(jwtService.createAccessToken(user.getId()))
                            .flatMap(token -> sessionStore.saveSession(
                                    jwtService.extractJti(token), user.getId(), Duration.ofMinutes(15))
                                    .thenReturn(new UserTokenPair(user.getId(), token)));
                });
    }
}
