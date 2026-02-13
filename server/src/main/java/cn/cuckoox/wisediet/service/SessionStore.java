package cn.cuckoox.wisediet.service;

import java.time.Duration;
import org.springframework.data.redis.core.ReactiveStringRedisTemplate;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class SessionStore {
    private final ReactiveStringRedisTemplate redisTemplate;

    public SessionStore(ReactiveStringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public Mono<Boolean> saveSession(String jti, Long userId, Duration ttl) {
        String sessionKey = sessionKey(jti);
        String userKey = userKey(userId);
        return redisTemplate.opsForValue()
                .set(sessionKey, String.valueOf(userId), ttl)
                .flatMap(saved -> redisTemplate.opsForSet().add(userKey, jti).thenReturn(saved));
    }

    public Mono<Boolean> exists(String jti) {
        return redisTemplate.hasKey(sessionKey(jti));
    }

    public Mono<Void> revokeUserSessions(Long userId) {
        String userKey = userKey(userId);
        return redisTemplate.opsForSet()
                .members(userKey)
                .flatMap(jti -> redisTemplate.delete(sessionKey(jti)))
                .then(redisTemplate.delete(userKey))
                .then();
    }

    private static final Duration OAUTH_STATE_TTL = Duration.ofMinutes(5);

    public Mono<Boolean> saveOAuthState(String state) {
        return redisTemplate.opsForValue()
                .set(oauthStateKey(state), "1", OAUTH_STATE_TTL);
    }

    public Mono<Boolean> validateAndConsumeOAuthState(String state) {
        if (state == null || state.isBlank()) {
            return Mono.just(false);
        }
        return redisTemplate.delete(oauthStateKey(state))
                .map(deleted -> deleted > 0);
    }

    private String oauthStateKey(String state) {
        return "oauth:state:" + state;
    }

    private String sessionKey(String jti) {
        return "session:" + jti;
    }

    private String userKey(Long userId) {
        return "user:" + userId + ":sessions";
    }
}
