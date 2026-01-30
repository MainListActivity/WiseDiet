package cn.cuckoox.wisediet.repository;

import cn.cuckoox.wisediet.model.AdminWhitelist;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Mono;

public interface AdminWhitelistRepository extends ReactiveCrudRepository<AdminWhitelist, Long> {
    Mono<AdminWhitelist> findByUserId(Long userId);
}
