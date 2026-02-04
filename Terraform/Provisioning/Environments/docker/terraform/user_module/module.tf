# Docker Module Invocation
module "docker_configuration" {
  source = "../../terraform"

  # Docker Provider Configuration
  docker_host           = "unix:///var/run/docker.sock"
#   docker_cert_path      = 
  
  # Environment Configuration
  environment           = "docker"
  
  # Network Configuration
  network_name          = "terraform-app-network"
  network_driver        = "bridge"
  
  # Volume Configuration
  volume_names          = ["app-data", "app-logs"]
  
  # Container Configuration
  container_name        = "webapp"
  container_count       = 1
  container_image       = "terraform-webapp:latest"
  container_cpu_shares  = 1024
  container_memory      = 512
  container_ports       = [
    {
      internal = 8080
      external = 8888
      protocol = "tcp"
    }
  ]
  container_env         = [
    "NODE_ENV=development",
    "LOG_LEVEL=debug",
    "TIMEZONE=UTC"
  ]
  container_volumes     = [
    {
      container_path = "/app/data"
      host_path      = "/var/lib/docker/volumes/app-data"
      volume_name    = "app-data"
      read_only      = false
    },
    {
      container_path = "/app/logs"
      host_path      = "/var/lib/docker/volumes/app-logs"
      volume_name    = "app-logs"
      read_only      = false
    }
  ]
  
  # Logging Configuration
  log_driver            = "json-file"
  
  # Tags
  tags                  = {
    "Environment" = "docker"
    "Project"     = "terraform-webapp"
    "ManagedBy"   = "terraform"
    "CreatedAt"   = "2024-01-23"
  }
}