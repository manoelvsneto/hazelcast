# Build stage - ARM64 compatible
FROM --platform=linux/arm64 maven:3.9.6-eclipse-temurin-11 AS build

WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage - ARM64 compatible with Ubuntu base for better security
FROM --platform=linux/arm64 eclipse-temurin:11-jre

WORKDIR /app

# Create logs directory
RUN mkdir -p /app/logs

# Copy the built JAR
COPY --from=build /app/target/hazelcast-project-1.0.0.jar /app/hazelcast-project.jar

# Copy resources
COPY --from=build /app/target/classes/logback.xml /app/

# Expose port for potential web interface
EXPOSE 8080

# Set JVM options for container
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD pgrep java || exit 1

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -cp /app/hazelcast-project.jar com.hazelcast.example.HazelcastClientExample"]
