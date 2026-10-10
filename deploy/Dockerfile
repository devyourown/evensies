# 빌드: docker compose build (context는 저장소 루트, deploy/docker-compose.yml 참고)
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY server/ ./server/
COPY shared/ ./shared/
WORKDIR /src/server
RUN chmod +x gradlew && ./gradlew --no-daemon bootJar -x test

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /src/server/build/libs/*.jar app.jar
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75"
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
