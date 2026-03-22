#!/bin/bash

# SpringBoot Application Docker Automated Deployment Script

# Server Configuration
SERVER_IP="49.235.161.106"
SSH_PORT="22"
USERNAME="root"
TARGET_DIR="/opt/apps/memo-app"
SERVICE_PORT="10011"
APP_NAME="memo-app"
VERSION="1.0.0"

# Local File Paths
LOCAL_JAR_PATH="target/dogFooding.jar"
LOCAL_DOCKERFILE_PATH="Dockerfile"

echo "======================================"
echo "Starting deployment of $APP_NAME to server $SERVER_IP"
echo "======================================"

# Check if local files exist
if [ ! -f "$LOCAL_JAR_PATH" ]; then
    echo "ERROR: Jar file not found - $LOCAL_JAR_PATH"
    exit 1
fi

if [ ! -f "$LOCAL_DOCKERFILE_PATH" ]; then
    echo "ERROR: Dockerfile not found - $LOCAL_DOCKERFILE_PATH"
    exit 1
fi

echo "[OK] Local files check passed"

# Create remote directory
echo ""
echo "=== Creating remote directory ==="
ssh -p $SSH_PORT ${USERNAME}@${SERVER_IP} "mkdir -p $TARGET_DIR"
echo "[OK] Remote directory created: $TARGET_DIR"

# Upload files
echo ""
echo "=== Uploading files to server ==="
scp -P $SSH_PORT $LOCAL_JAR_PATH ${USERNAME}@${SERVER_IP}:${TARGET_DIR}/
scp -P $SSH_PORT $LOCAL_DOCKERFILE_PATH ${USERNAME}@${SERVER_IP}:${TARGET_DIR}/
echo "[OK] Files uploaded successfully"

# Remote execution
echo ""
echo "=== Executing remote Docker deployment ==="

ssh -p $SSH_PORT ${USERNAME}@${SERVER_IP} << 'EOF'
cd /opt/apps/memo-app

# Check port occupation
PORT_CONTAINER=$(docker ps -q --filter "publish=10011/tcp")
if [ -n "$PORT_CONTAINER" ]; then
    echo "Port 10011 is occupied, stopping container $PORT_CONTAINER"
    docker stop $PORT_CONTAINER
    docker rm $PORT_CONTAINER
fi

# Check existing container
EXISTING_CONTAINER=$(docker ps -aq --filter "name=memo-app")
if [ -n "$EXISTING_CONTAINER" ]; then
    echo "Found existing container, removing: $EXISTING_CONTAINER"
    docker stop $EXISTING_CONTAINER 2>/dev/null
    docker rm $EXISTING_CONTAINER
fi

# Build image
echo "Building Docker image: memo-app:1.0.0"
docker build -t memo-app:1.0.0 .

# Run container
echo "Starting Docker container..."
docker run -d \
    --name memo-app \
    -p 10011:10011 \
    -e JVM_OPTS="-Xms256m -Xmx512m" \
    --restart always \
    memo-app:1.0.0

echo "Waiting for container to start..."
sleep 10

# Check container status
CONTAINER_STATUS=$(docker inspect -f '{{.State.Running}}' memo-app 2>/dev/null)
if [ "$CONTAINER_STATUS" = "true" ]; then
    echo "[OK] Container started successfully"
else
    echo "[ERROR] Container failed to start"
    docker logs memo-app
    exit 1
fi
EOF

echo ""
echo "=== Verifying service status ==="
sleep 15

# Verify service
if curl -s --connect-timeout 10 "http://${SERVER_IP}:${SERVICE_PORT}" > /dev/null; then
    echo ""
    echo "======================================"
    echo "[OK] Service deployed successfully!"
    echo "======================================"
    echo "Application: $APP_NAME"
    echo "Version: $VERSION"
    echo "Access URL: http://${SERVER_IP}:${SERVICE_PORT}"
    echo "======================================"
else
    echo ""
    echo "[ERROR] Failed to connect to service"
    exit 1
fi
