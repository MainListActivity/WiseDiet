# --- 第一阶段：编译构建 (Build Stage) ---
# 使用包含 JDK 的基础镜像进行编译
FROM maven:3.9.6-eclipse-temurin-21-alpine AS builder

# 设置工作目录
WORKDIR /build

# 1. 巧妙利用 Docker 缓存：先只复制 pom.xml 以下载依赖
# 这样只要 pom.xml 没变，依赖层就不会重新下载
COPY pom.xml .
RUN mvn dependency:go-offline

# 2. 复制源码并进行打包
COPY src ./src
RUN mvn clean package -DskipTests

# --- 第二阶段：运行环境 (Runtime Stage) ---
# 使用更轻量级的 JRE 镜像，减少攻击面和镜像体积
FROM eclipse-temurin:21-jre-alpine

# 创建一个非 root 用户运行程序，提升安全性
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

WORKDIR /app

# 从 builder 阶段将生成的 jar 包拷贝过来
# 假设生成的 jar 名为 app.jar
COPY --from=builder /build/target/*.jar app.jar

# 暴露端口（根据你的 application.properties 修改）
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", "-jar", "app.jar"]
