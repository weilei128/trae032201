FROM openjdk:8-jre-slim

WORKDIR /app

ENV JVM_OPTS="-Xms256m -Xmx512m"
ENV SERVER_PORT=10013

EXPOSE 10013

COPY kimi.jar /app/kimi.jar

ENTRYPOINT ["sh", "-c", "java ${JVM_OPTS} -jar /app/kimi.jar"]
