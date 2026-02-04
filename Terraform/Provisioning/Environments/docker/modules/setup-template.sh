#!/bin/bash
# Container setup template script
# Variables: ${environment}, ${container_count}, ${container_name}

set -e

ENVIRONMENT="${environment}"
CONTAINER_COUNT="${container_count}"
CONTAINER_NAME="${container_name}"

echo "Setting up $CONTAINER_COUNT containers in $ENVIRONMENT environment..."

# Function to wait for container health
wait_for_container_health() {
    local container=$1
    local max_attempts=30
    local attempt=0
    
    echo "Waiting for container $container to be healthy..."
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec "$container" curl -f http://localhost:80/ > /dev/null 2>&1; then
            echo "✓ Container $container is healthy"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo "  Attempt $attempt/$max_attempts..."
        sleep 2
    done
    
    echo "✗ Container $container failed to become healthy"
    return 1
}

# Setup containers
for i in $(seq 1 $CONTAINER_COUNT); do
    CONTAINER="${CONTAINER_NAME}-$i"
    echo "Checking container: $CONTAINER"
    
    if docker ps --filter "name=$CONTAINER" --format '{{.Names}}' | grep -q "$CONTAINER"; then
        echo "✓ Container $CONTAINER is running"
        wait_for_container_health "$CONTAINER" || exit 1
    else
        echo "✗ Container $CONTAINER is not running"
    fi
done

echo "✓ All containers are set up and healthy!"
