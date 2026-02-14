package cn.cuckoox.wisediet.api;

import cn.cuckoox.wisediet.i18n.RequestLocaleResolver;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.context.MessageSource;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * Hello World Controller
 * 用于验证WebFlux框架正确配置
 */
@RestController
@RequestMapping("/api")
public class HelloController {

    private final MessageSource messageSource;
    private final RequestLocaleResolver requestLocaleResolver;

    public HelloController(MessageSource messageSource, RequestLocaleResolver requestLocaleResolver) {
        this.messageSource = messageSource;
        this.requestLocaleResolver = requestLocaleResolver;
    }

    @GetMapping("/hello")
    public Mono<String> hello(ServerWebExchange exchange) {
        var locale = requestLocaleResolver.resolve(exchange);
        return Mono.just(messageSource.getMessage("hello.world", null, locale));
    }
}
