# ===== Stage 1: Build the Spring Boot JAR =====
FROM maven:3.9.6-eclipse-temurin-21 AS build

# Add Maven mirror for stable dependency download
COPY settings.xml /root/.m2/settings.xml

WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src ./src

# Build the application (skipping tests for faster CI build)
RUN mvn -e -DskipTests clean package

# ===== Stage 2: Create a lightweight runtime image =====
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copy only the final JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose application port
EXPOSE 8100

# Start the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]