package cn.cuckoox.wisediet;

import cn.cuckoox.wisediet.model.OccupationTag;
import cn.cuckoox.wisediet.model.UserProfile;
import cn.cuckoox.wisediet.repository.UserProfileRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Testcontainers;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

@Testcontainers
class OnboardingApiIntegrationTest extends AbstractIntegrationTest {


    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.r2dbc.url", () -> String.format(
                "r2dbc:postgresql://%s:%d/%s",
                postgres.getHost(),
                postgres.getMappedPort(5432),
                postgres.getDatabaseName()
        ));
        registry.add("spring.r2dbc.username", postgres::getUsername);
        registry.add("spring.r2dbc.password", postgres::getPassword);
        registry.add("spring.sql.init.mode", () -> "always");
    }

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Test
    void shouldReturnSeededOccupationTags() {
        // Given: 已加载默认标签数据
        // When: 请求职业标签列表
        Flux<OccupationTag> response = webTestClient.get()
                .uri("/api/tags/occupations")
                .exchange()
                .expectStatus().isOk()
                .returnResult(OccupationTag.class)
                .getResponseBody();

        // Then: 返回职业标签并包含预置数据
        StepVerifier.create(response.filter(tag -> "Programmer (Sedentary)".equals(tag.getLabel())).take(1))
                .expectNextMatches(tag -> "Occupation".equals(tag.getCategory()))
                .verifyComplete();
    }

    @Test
    void shouldPersistProfileFromOnboarding() {
        // Given: 完整的基础信息与职业标签
        UserProfile request = new UserProfile(
                null,
                "Male",
                30,
                180.0,
                70.0,
                "1,2",
                2
        );

        // When: 提交 onboarding 资料
        Flux<UserProfile> response = webTestClient.post()
                .uri("/api/onboarding/profile")
                .bodyValue(request)
                .exchange()
                .expectStatus().isOk()
                .returnResult(UserProfile.class)
                .getResponseBody();

        // Then: 返回持久化数据并写入数据库
        StepVerifier.create(response)
                .expectNextMatches(profile -> profile.getId() != null
                        && "Male".equals(profile.getGender())
                        && Integer.valueOf(2).equals(profile.getFamilyMembers()))
                .verifyComplete();

        StepVerifier.create(userProfileRepository.findAll()
                        .filter(profile -> "Male".equals(profile.getGender()))
                        .take(1))
                .expectNextMatches(profile -> "1,2".equals(profile.getOccupationTagIds()))
                .verifyComplete();
    }
}
