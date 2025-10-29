FROM openjdk:17-jdk-alpine AS build

WORKDIR /main
COPY --from=build /build/libs/*.jar /main/main.jar
RUN apk upgrade --no-cache && apk add --no-cache curl
EXPOSE 8080

CMD ["java", "-jar", "/main/main.jar"]