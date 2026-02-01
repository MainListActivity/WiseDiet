package cn.cuckoox.wisediet.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@ConfigurationProperties(prefix = "app.jwt")
public class JwtProperties {
    private String secret;
    private long accessTtlMinutes = 15;
    private long refreshTtlDays = 30;
}
