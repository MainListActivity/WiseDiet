package cn.cuckoox.wisediet.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

/**
 * Hello World Controller
 * 用于验证WebFlux框架正确配置
 */
@RestController
@RequestMapping("/api")
public class HelloController {

    @GetMapping("/hello")
    public Mono<String> hello() {
        return Mono.just("Hello, World!");
    }
}
