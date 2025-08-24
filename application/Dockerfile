# ----------- Build Stage -----------
FROM eclipse-temurin:17-jdk-alpine AS build

WORKDIR /app

# Copy Maven wrapper and pom
COPY mvnw pom.xml ./
COPY .mvn/ .mvn/

# Download dependencies (cache)
RUN ./mvnw dependency:go-offline

# Copy source code
COPY src/ src/

# Build the Spring Boot jar
RUN ./mvnw package -DskipTests

# ----------- Run Stage -----------
FROM gcr.io/distroless/java17-debian11

# Set a non-root user
USER nonroot:nonroot

# Copy the jar from build stage
COPY --from=build /app/target/*.jar /app/app.jar

# Run the app
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
