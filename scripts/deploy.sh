#!/usr/bin/env bash
set -e

APP="devops-web-v2"
BACKUP="${APP}-backup"
URL="http://localhost:8080"
HAS_BACKUP=0

IMAGE_ID=$(docker image inspect devops-lab:test --format '{{.Id}}')

# Do not overwrite a backup from an earlier deployment.
if docker container inspect "$BACKUP" >/dev/null 2>&1; then
    echo "A backup already exists. Check it before deploying."
    exit 1
fi

rollback_on_exit() {
    RESULT=$?

    if [ "$RESULT" -eq 0 ]; then
        return
    fi

    echo "Deployment failed."

    # Show logs before removing the failed container.
    if docker container inspect "$APP" >/dev/null 2>&1; then
        docker logs --tail 30 "$APP" || true
        if ! docker rm -f "$APP"; then
            echo "Could not remove the new container. Manual recovery needed."
            exit 1
        fi
    fi

    if [ "$HAS_BACKUP" -eq 1 ]; then
        echo "Restoring the previous container..."
        if docker rename "$BACKUP" "$APP" && docker start "$APP"; then
            echo "Previous container restarted. Check the website."
        else
            echo "Rollback failed. Manual recovery needed."
        fi
    else
        echo "No previous container is available to restore."
    fi

    exit "$RESULT"
}

# Keep the previous container, including its settings.
if docker container inspect "$APP" >/dev/null 2>&1; then
    docker rename "$APP" "$BACKUP"
    HAS_BACKUP=1
fi

trap rollback_on_exit EXIT

if [ "$HAS_BACKUP" -eq 1 ]; then
    docker stop "$BACKUP"
fi

echo "Starting the new version..."
docker run -d \
    --name "$APP" \
    -p 127.0.0.1:8080:8000 \
    "$IMAGE_ID"

echo "Checking the deployed website..."
curl --fail --silent --show-error \
    --retry 10 --retry-all-errors --retry-delay 1 \
    --connect-timeout 2 --max-time 3 \
    --output /dev/null \
    "$URL"

BASE_URL="$URL" python3 tests/test_website.py

# The new version passed verification.
trap - EXIT

if [ "$HAS_BACKUP" -eq 1 ]; then
    docker rm "$BACKUP"
fi

echo "Deployment passed!"
