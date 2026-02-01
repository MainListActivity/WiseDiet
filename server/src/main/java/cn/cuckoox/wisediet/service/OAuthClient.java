package cn.cuckoox.wisediet.service;

import reactor.core.publisher.Mono;

public interface OAuthClient {
    Mono<OAuthProfile> exchangeAndFetchProfile(String provider, String code);
}
