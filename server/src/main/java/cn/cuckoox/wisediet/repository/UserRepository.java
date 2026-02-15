package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.User;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Mono;

public interface UserRepository extends ReactiveCrudRepository<User, Long> {
    Mono<User> findByProviderAndProviderUserId(String provider, String providerUserId);
}
