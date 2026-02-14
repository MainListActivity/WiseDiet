package cn.cuckoox.wisediet.i18n;

import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;

import java.util.List;
import java.util.Locale;

@Component
public class RequestLocaleResolver {

    public Locale resolve(ServerWebExchange exchange) {
        List<Locale> accepted = exchange.getRequest().getHeaders().getAcceptLanguageAsLocales();
        for (Locale locale : accepted) {
            String language = locale.getLanguage();
            if ("zh".equalsIgnoreCase(language)) {
                return Locale.SIMPLIFIED_CHINESE;
            }
            if ("en".equalsIgnoreCase(language)) {
                return Locale.ENGLISH;
            }
        }
        return Locale.ENGLISH;
    }
}
