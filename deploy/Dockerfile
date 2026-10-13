# Build: docker compose build (the context is the repo root, see deploy/docker-compose.yml)
# 1) Web app (Phase 9): served at /app/ on the same origin. Keep the version the same as CI's subosito/flutter-action.
FROM ghcr.io/cirruslabs/flutter:3.41.4 AS web
WORKDIR /src/app
COPY app/pubspec.yaml app/pubspec.lock app/l10n.yaml app/analysis_options.yaml ./
COPY app/lib ./lib
COPY app/web ./web
COPY app/assets ./assets
RUN flutter build web --release --base-href /app/ --no-web-resources-cdn --csp

# 2) Server: puts the web build in static/app/ (git-ignored) and builds one jar.
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY server/ ./server/
COPY shared/ ./shared/
COPY --from=web /src/app/build/web/ ./server/src/main/resources/static/app/
WORKDIR /src/server
RUN chmod +x gradlew && ./gradlew --no-daemon bootJar -x test

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /src/server/build/libs/*.jar app.jar
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75"
# Uploaded files (profile photos); docker-compose.yml mounts ./data here. Back it up with the DB dumps.
ENV EVENSIES_STORAGE_DIR=/data
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
