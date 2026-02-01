


**技术栈要求：**
```
- Spring Boot 4.x
- Spring WebFlux（响应式 Web）
- Spring Data R2DBC（响应式数据库访问）
- Reactor Core（响应式编程核心）
- JUnit 5 + Reactor Test（测试框架）+ testcontainers（负责拉起和初始化测试pg和redis）
- 测试用例必须从AbstractIntegrationTest继承
```

**编码顺序规则：**

1. **第一步：编写集成测试**
   - 测试完整的 HTTP 请求/响应流程
   - 包含数据库操作的端到端验证
   - 示例模板：
   ```java
   class UserApiIntegrationTest extends AbstractIntegrationTest{
       @Test
       void shouldCreateUser_whenValidRequest() {
           // Given: 准备测试数据
           // When: 发送 HTTP 请求
           // Then: 验证响应和数据库状态
       }
   }
   ```

2. **第二步：编写 Controller 层（由外向内）**
   - 先定义 API 接口（路由、参数、响应）
   - 返回 `Mono<T>` 或 `Flux<T>`
   - 只做请求/响应映射，不含业务逻辑

3. **第三步：编写 Service 层测试**
   - 使用 `StepVerifier` 验证响应式流
   - Mock 所有依赖（Repository、外部服务）
   - 测试业务逻辑的各种分支

4. **第四步：实现 Service 层**
   - 使用 Reactor 操作符（map、flatMap、filter 等）
   - 保持方法的纯函数特性（可测试性）
   - 错误处理使用 `onErrorResume`、`onErrorMap`

5. **第五步：编写 Repository 层测试**
   - 使用 `@DataR2dbcTest`
   - 测试数据库查询的正确性
   - 使用测试容器（Testcontainers）模拟真实数据库

6. **第六步：实现 Repository 层**
   - 继承 `ReactiveCrudRepository` 或 `R2dbcRepository`
   - 自定义查询使用 `@Query` 注解

**任务拆分示例：**
```
❌ 错误：实现用户管理模块
✅ 正确拆分：
  Task 1: 编写"创建用户"集成测试
  Task 2: 实现 POST /users 端点通过测试
  Task 3: 编写"查询用户列表"集成测试
  Task 4: 实现 GET /users 端点通过测试
  Task 5: 编写"更新用户"集成测试
  ...
```
