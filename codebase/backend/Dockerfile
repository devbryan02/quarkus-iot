# syntax=docker/dockerfile:1
FROM eclipse-temurin:25-jdk-noble AS build
RUN apt-get update \
  && apt-get install -y --no-install-recommends unzip \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw
COPY src/ src/
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -ntp package -DskipTests

FROM eclipse-temurin:25-jre-noble AS runtime
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --gid 10001 kivo \
  && useradd --uid 10001 --gid kivo --no-create-home kivo
WORKDIR /app
COPY --from=build --chown=10001:10001 /workspace/target/quarkus-app/ ./
ENV QUARKUS_HTTP_HOST=0.0.0.0
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
  CMD curl --fail --silent http://127.0.0.1:8080/q/health/ready || exit 1
ENTRYPOINT ["java", "-jar", "quarkus-run.jar"]
