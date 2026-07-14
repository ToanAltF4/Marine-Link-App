# ---- Build stage: biên dịch JAR bằng Maven + JDK 21 ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
# Cache dependencies trước để build lại nhanh hơn
COPY pom.xml .
RUN mvn -q -B -ntp dependency:go-offline
COPY src ./src
RUN mvn -q -B -ntp clean package -DskipTests

# ---- Run stage: chạy JAR bằng JRE 21 gọn nhẹ ----
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
# Giới hạn heap theo RAM container (Render free = 512MB) để tránh OOM.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC"
# Render sẽ inject biến PORT; app đọc qua application.yml.
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
