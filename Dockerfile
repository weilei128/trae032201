FROM openjdk:8-jre-alpine

WORKDIR /app

COPY dogFooding.jar /app/dogFooding.jar

EXPOSE 10011

ENV JVM_OPTS="-Xms256m -Xmx512m"

ENTRYPOINT ["sh", "-c", "java $JVM_OPTS -jar dogFooding.jar"]