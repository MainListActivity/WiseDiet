2. 关键功能模块的 Java 实现方案

2.1 AI 大脑层：Spring AI + Prompt Template

• 需求： 处理用户画像、职业标签、7天历史记录，并生成符合 JSON Schema 的食谱。

• Spring 实现：

◦ 使用 spring-ai-openai-spring-boot-starter。

◦ Prompt 管理： 利用 Spring 的 PromptTemplate 功能，将提示词模板化。您可以创建一个 diet_recommendation.st 文件，动态填入 {user_profile}, {history_7_days} 等变量。

◦ 结构化输出 (JSON)： Spring AI 提供了 Output Parser（输出解析器），可以将大模型返回的 JSON 字符串自动映射为 Java 的 POJO 对象（如 DailyMealPlan 类），直接解决 BRD 中对数据格式的严格要求。

2.2 数据持久化：Spring Data JPA + Hibernate Types

• 需求： 存储用户复杂的饮食档案，以及包含大量嵌套信息的每日食谱（食材、步骤、营养标签）。

• Spring 实现：

◦ 数据库： PostgreSQL。

◦ JSONB 支持： 引入 hypersistence-utils-hibernate-63 库。这允许您在 Entity 实体类中直接定义 Map 或自定义 POJO，并用 @Type(JsonType.class) 注解，Spring 会自动将其序列化为 Postgres 的 JSONB 格式存入数据库。

◦ 查询优势： 利用 Spring Data JPA 的 @Query，您可以直接编写 SQL 查询 JSONB 内部的字段，例如查询“近7天牛肉摄入量”。

2.3 动态修正与重算：Spring Events (观察者模式)

• 需求： 用户修改历史记录（如牛肉换猪肉）后，系统需实时重算当日营养，并更新上下文。

• Spring 实现：

◦ 解耦逻辑： 不要把“修改记录”和“重算逻辑”写在一起。

◦ 发布事件： 当 HistoryService 完成 updateMeal() 操作后，发布一个自定义事件 DietaryCorrectionEvent。

◦ 监听事件： 创建一个 NutritionCalculatorListener 使用 @EventListener 监听该事件。一旦触发，独立执行复杂的营养重算逻辑，并更新 Redis 缓存中的“7天摘要”。

2.4 早高峰推送：Spring Task / @Async

• 需求： 每日 7:00 AM 推送洪峰。

• Spring 实现：

◦ 轻量级方案： 使用 Spring 自带的 @Scheduled(cron = "0 0 4 * * ?") 在凌晨 4 点触发预计算任务。

◦ 异步执行： 配合 @Async 和自定义的 ThreadPoolTaskExecutor（线程池），并发调用 AI 生成服务，将结果存入 Redis。

◦ 消息队列（进阶）： 如果用户量大，集成 spring-boot-starter-amqp (RabbitMQ) 或 Kafka，将生成任务分发给多个消费者实例。

4. 架构图 (Spring版)

```mermaid
graph TD

Client[Flutter App] -->|HTTPS| Controller[Spring RestController]

subgraph "Spring Boot Application"

Controller --> Service[DietService]

%% 核心逻辑

Service -->|发布事件| Event[ApplicationEventPublisher]

Event -->|监听| Listener[NutritionListener (@EventListener)]

%% AI 集成

Service -->|Prompt/Chat| SpringAI[Spring AI (ChatClient)]

SpringAI -->|HTTP| OpenAI[LLM Model]

%% 数据层

Service -->|ORM| JPA[Spring Data JPA]

JPA -->|JSONB| DB[(PostgreSQL)]

%% 缓存与队列

Service -->|Cache| RedisT[Spring Data Redis]

%% 定时任务

Scheduler[@Scheduled] -->|触发| Service

end
```