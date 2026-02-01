package cn.cuckoox.wisediet.service;

import cn.cuckoox.wisediet.config.JwtProperties;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class JwtService {
    private final JwtProperties jwtProperties;
    private final JwtEncoder jwtEncoder;
    private final JwtDecoder jwtDecoder;

    public JwtService(JwtProperties jwtProperties) {
        this.jwtProperties = jwtProperties;
        SecretKey secretKey = new SecretKeySpec(hashSecret(jwtProperties.getSecret()), "HmacSHA256");
        this.jwtEncoder = NimbusJwtEncoder.withSecretKey(secretKey).build();
        this.jwtDecoder = NimbusJwtDecoder.withSecretKey(secretKey).build();
    }

    public Mono<String> createAccessToken(Long userId) {
        return Mono.fromSupplier(() -> {
            Instant now = Instant.now();
            JwtClaimsSet claims = JwtClaimsSet.builder()
                    .subject(String.valueOf(userId))
                    .issuedAt(now)
                    .expiresAt(now.plus(Duration.ofMinutes(jwtProperties.getAccessTtlMinutes())))
                    .build();
            JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
            return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        });
    }

    public Mono<Long> parseUserId(String token) {
        return Mono.fromSupplier(() -> Long.valueOf(jwtDecoder.decode(token).getSubject()));
    }

    private static byte[] hashSecret(String secret) {
        try {
            return MessageDigest.getInstance("SHA-256")
                    .digest(secret.getBytes(StandardCharsets.UTF_8));
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to hash JWT secret", ex);
        }
    }
}
