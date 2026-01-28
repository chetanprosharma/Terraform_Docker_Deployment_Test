terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host      = var.docker_host
  cert_path = var.docker_cert_path != "" ? var.docker_cert_path : null
}

# Build custom Docker image from Dockerfile
resource "docker_image" "custom_image" {
  name = "terraform-webapp:latest"

  build {
    context    = "${path.module}/.."
    dockerfile = "docker/Dockerfile"
  }

  triggers = {
    dockerfile_md5 = filemd5("${path.module}/../docker/Dockerfile")
    html_md5       = filemd5("${path.module}/../web/html/index.html")
    nginx_md5      = filemd5("${path.module}/../config/nginx.conf")
    app_py_md5     = filemd5("${path.module}/../app/app.py")
  }
}

# Docker Network
resource "docker_network" "app_network" {
  name   = var.network_name
  driver = var.network_driver
}

# Docker Volumes
resource "docker_volume" "app_volumes" {
  for_each = toset(var.volume_names)

  name   = each.value
  driver = "local"
}

# Docker Containers - Localhost Network
resource "docker_container" "app" {
  count = var.container_count

  name  = "${var.container_name}-${count.index + 1}"
  image = docker_image.custom_image.image_id

  # CPU and Memory
  cpu_shares = var.container_cpu_shares
  memory     = var.container_memory

  # Network - Use bridge network for localhost
  networks_advanced {
    name = docker_network.app_network.name
  }

  # Port Mappings - Simple localhost port binding
  dynamic "ports" {
    for_each = var.container_ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = ports.value.protocol
    }
  }

  # Environment Variables
  env = concat(
    var.container_env,
    [
      "CONTAINER_NAME=${var.container_name}-${count.index + 1}",
      "ENVIRONMENT=${var.environment}",
      "LOCAL_TEST=true"
    ]
  )

  # Volume Mounts
  dynamic "volumes" {
    for_each = var.container_volumes
    content {
      container_path = volumes.value.container_path
      host_path      = volumes.value.host_path
      volume_name    = volumes.value.volume_name
      read_only      = volumes.value.read_only
    }
  }

  # Logging
  log_driver = var.log_driver
  log_opts = {
    "max-size" = "10m"
    "max-file" = "3"
  }

  # Restart Policy
  must_run = true

  # Labels
  labels {
    label = "environment"
    value = var.tags["Environment"]
  }

  labels {
    label = "test"
    value = "localhost"
  }

  depends_on = [
    docker_network.app_network,
    docker_image.custom_image
  ]
}

# Configuration for user-defined environment variables
locals {
  user_env_vars = [
    "APP_ENV=${var.environment}",
    "LOG_LEVEL=info",
    "TIMEZONE=UTC"
  ]
}

# Docker Compose equivalent configuration (informational)
resource "local_file" "docker_compose" {
  filename = "${path.module}/../scripts/docker-compose.yml"
  content = yamlencode({
    version = "3.8"
    services = {
      for i in range(var.container_count) : "${var.container_name}-${i + 1}" => {
        image          = var.container_image
        container_name = "${var.container_name}-${i + 1}"
        environment    = local.user_env_vars
        networks       = ["app-network"]
        restart_policy = {
          condition = "unless-stopped"
        }
        labels = var.tags
      }
    }
    networks = {
      "app-network" = {
        driver = "bridge"
      }
    }
  })

  depends_on = []
}

# Script to build or configure containers
resource "local_file" "container_setup_script" {
  filename = "${path.module}/../scripts/setup-containers.sh"
  content  = <<-EOT
#!/bin/bash
# Container setup template script
# Variables: environment, container_count, container_name

set -e

ENVIRONMENT="${var.environment}"
CONTAINER_COUNT="${var.container_count}"
CONTAINER_NAME="${var.container_name}"

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
    CONTAINER="$CONTAINER_NAME-$i"
    echo "Checking container: $CONTAINER"
    
    if docker ps --filter "name=$CONTAINER" --format '{{.Names}}' | grep -q "$CONTAINER"; then
        echo "✓ Container $CONTAINER is running"
        wait_for_container_health "$CONTAINER" || exit 1
    else
        echo "✗ Container $CONTAINER is not running"
    fi
done

echo "✓ All containers are set up and healthy!"
EOT

  lifecycle {
    ignore_changes = [content]
  }
}

# Local file to store Docker configuration
resource "local_file" "docker_config" {
  filename = "${path.module}/../config/docker-config.json"
  content = jsonencode({
    environment = var.environment
    created_at  = timestamp()
    labels      = var.tags
  })
}

# Local file for environment variables
resource "local_file" "docker_env_file" {
  filename = "${path.module}/../config/.docker.env"
  content = join("\n", [
    "# Docker Environment Configuration",
    "DOCKER_ENVIRONMENT=${var.environment}",
    "DOCKER_CREATED_AT=${timestamp()}",
    "DOCKER_LABELS=${jsonencode(var.tags)}"
  ])
}
