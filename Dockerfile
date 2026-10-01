#FROM maven:3.9-eclipse-temurin-21 AS build
#WORKDIR /app
#COPY pom.xml .
#RUN mvn -B dependency:go-offline -Pproduction || true
#COPY src ./src
#RUN mvn -B clean package -Pproduction -DskipTests
#
#FROM eclipse-temurin:21-jre-jammy
#WORKDIR /app
#COPY --from=build /app/target/*.jar app.jar
#EXPOSE 8080
#ENTRYPOINT ["java", "-jar", "app.jar"]


FROM ghcr.io/jqlang/jq:latest AS jq-stage

FROM eclipse-temurin:21-jre-jammy AS build
#FROM eclipse-temurin:25-jdk AS build
COPY --from=jq-stage /jq /usr/bin/jq
# Test that jq works after copying
RUN jq --version

ENV HOME=/app
RUN mkdir -p $HOME
WORKDIR $HOME
COPY . $HOME

# If you have a Vaadin Pro key, pass it as a secret with id "proKey":
#
#   $ docker build --secret id=proKey,src=$HOME/.vaadin/proKey .
#
# If you have a Vaadin Offline key, pass it as a secret with id "offlineKey":
#
#   $ docker build --secret id=offlineKey,src=$HOME/.vaadin/offlineKey .

RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw clean package -DskipTests
#RUN mvn -B clean package -Pproduction -DskipTests

FROM eclipse-temurin:21-jre-jammy
#FROM eclipse-temurin:25-jre-alpine
COPY --from=build /app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar", "--spring.profiles.active=prod"]
