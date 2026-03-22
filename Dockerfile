FROM openjdk:8-jre-slim

WORKDIR /app

ENV JVM_OPTS="-Xms256m -Xmx512m"
ENV APP_PORT=10012

EXPOSE ${APP_PORT}

COPY GLM.jar /app/GLM.jar

ENTRYPOINT ["sh", "-c", "java ${JVM_OPTS} -jar /app/GLM.jar"]
