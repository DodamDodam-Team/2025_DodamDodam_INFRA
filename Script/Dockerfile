FROM amazoncorretto:17-alpine
WORKDIR /app
COPY build/libs/*.jar ./app.jar
RUN apk add --no-cache curl
EXPOSE 8080
CMD ["java", "-jar", "/app/app.jar"]