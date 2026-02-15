package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.User;
import cn.cuckoox.wisediet.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class UserRepositoryIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void shouldPersistUserWithOnboardingStep() {
        Mono<User> flow = userRepository.save(new User(null, "a@b.com", "google", "gid-repo-" + System.nanoTime(), 1))
                .flatMap(saved -> userRepository.findById(saved.getId()));

        StepVerifier.create(flow)
                .expectNextMatches(user -> user.getId() != null && Integer.valueOf(1).equals(user.getOnboardingStep()))
                .verifyComplete();
    }
}
