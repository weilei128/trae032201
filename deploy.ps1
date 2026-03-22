# SpringBoot Application Docker Automated Deployment Script

# Server Configuration
$SERVER_IP = "49.235.161.106"
$SSH_PORT = "22"
$USERNAME = "root"
$TARGET_DIR = "/opt/apps/memo-app"
$SERVICE_PORT = "10011"
$APP_NAME = "memo-app"
$VERSION = "1.0.0"

# Local File Paths
$LOCAL_JAR_PATH = "target\dogFooding.jar"
$LOCAL_DOCKERFILE_PATH = "Dockerfile"

Write-Host "======================================"
Write-Host "Starting deployment of $APP_NAME to server $SERVER_IP"
Write-Host "======================================"

# Check if local files exist
if (-not (Test-Path $LOCAL_JAR_PATH)) {
    Write-Host "ERROR: Jar file not found - $LOCAL_JAR_PATH"
    exit 1
}

if (-not (Test-Path $LOCAL_DOCKERFILE_PATH)) {
    Write-Host "ERROR: Dockerfile not found - $LOCAL_DOCKERFILE_PATH"
    exit 1
}

Write-Host "[OK] Local files check passed"

# Create remote directory
Write-Host "`n=== Creating remote directory ==="
ssh -p $SSH_PORT ${USERNAME}@${SERVER_IP} "mkdir -p $TARGET_DIR"
Write-Host "[OK] Remote directory created: $TARGET_DIR"

# Upload files
Write-Host "`n=== Uploading files to server ==="
scp -P $SSH_PORT $LOCAL_JAR_PATH ${USERNAME}@${SERVER_IP}:${TARGET_DIR}/
scp -P $SSH_PORT $LOCAL_DOCKERFILE_PATH ${USERNAME}@${SERVER_IP}:${TARGET_DIR}/
Write-Host "[OK] Files uploaded successfully"

# Create remote deployment script
Write-Host "`n=== Creating remote deployment script ==="
$remoteScriptFile = "remote_deploy.sh"

@"
#!/bin/bash
cd $TARGET_DIR

# Check port occupation
PORT_CONTAINER=\$(docker ps -q --filter "publish=$SERVICE_PORT/tcp")
if [ -n "\$PORT_CONTAINER" ]; then
    echo "Port $SERVICE_PORT is occupied, stopping container \$PORT_CONTAINER"
    docker stop \$PORT_CONTAINER
    docker rm \$PORT_CONTAINER
fi

# Check existing container
EXISTING_CONTAINER=\$(docker ps -aq --filter "name=$APP_NAME")
if [ -n "\$EXISTING_CONTAINER" ]; then
    echo "Found existing container, removing: \$EXISTING_CONTAINER"
    docker stop \$EXISTING_CONTAINER 2>/dev/null
    docker rm \$EXISTING_CONTAINER
fi

# Build image
echo "Building Docker image: ${APP_NAME}:${VERSION}"
docker build -t ${APP_NAME}:${VERSION} .

# Run container
echo "Starting Docker container..."
docker run -d \
    --name $APP_NAME \
    -p ${SERVICE_PORT}:${SERVICE_PORT} \
    -e JVM_OPTS="-Xms256m -Xmx512m" \
    --restart always \
    ${APP_NAME}:${VERSION}

echo "Waiting for container to start..."
sleep 10

# Check container status
CONTAINER_STATUS=\$(docker inspect -f '{{.State.Running}}' $APP_NAME 2>/dev/null)
if [ "\$CONTAINER_STATUS" = "true" ]; then
    echo "[OK] Container started successfully"
else
    echo "[ERROR] Container failed to start"
    docker logs $APP_NAME
    exit 1
fi
"@ | Out-File -FilePath $remoteScriptFile -Encoding utf8

# Upload and execute remote script
scp -P $SSH_PORT $remoteScriptFile ${USERNAME}@${SERVER_IP}:${TARGET_DIR}/
ssh -p $SSH_PORT ${USERNAME}@${SERVER_IP} "chmod +x ${TARGET_DIR}/${remoteScriptFile} && bash ${TARGET_DIR}/${remoteScriptFile}"

# Cleanup local script file
Remove-Item $remoteScriptFile

Write-Host "`n=== Verifying service status ==="
Start-Sleep -Seconds 15

try {
    $RESPONSE = Invoke-WebRequest -Uri "http://${SERVER_IP}:${SERVICE_PORT}" -UseBasicParsing -TimeoutSec 10
    if ($RESPONSE.StatusCode -eq 200) {
        Write-Host "`n======================================"
        Write-Host "[OK] Service deployed successfully!"
        Write-Host "======================================"
        Write-Host "Application: $APP_NAME"
        Write-Host "Version: $VERSION"
        Write-Host "Access URL: http://${SERVER_IP}:${SERVICE_PORT}"
        Write-Host "======================================"
    }
    else {
        Write-Host "`n[ERROR] Service verification failed, HTTP status: $($RESPONSE.StatusCode)"
        exit 1
    }
}
catch {
    Write-Host "`n[ERROR] Failed to connect to service: $_"
    exit 1
}
