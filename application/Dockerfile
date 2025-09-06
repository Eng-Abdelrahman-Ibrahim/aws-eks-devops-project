# ----------- Runtime Stage Only -----------

FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Take prebuilt JAR from Jenkins build
# Pass JAR_FILE as a build argument
ARG JAR_FILE=target/app.jar
COPY ${JAR_FILE} app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
