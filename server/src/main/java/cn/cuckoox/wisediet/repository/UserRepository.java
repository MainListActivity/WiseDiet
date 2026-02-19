package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.User;
import org.springframework.data.r2dbc.repository.Modifying;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Mono;

public interface UserRepository extends ReactiveCrudRepository<User, Long> {
    Mono<User> findByProviderAndProviderUserId(String provider, String providerUserId);

    @Modifying
    @Query("UPDATE users SET onboarding_step = 0 WHERE id = :userId")
    Mono<Void> completeOnboarding(Long userId);
}
