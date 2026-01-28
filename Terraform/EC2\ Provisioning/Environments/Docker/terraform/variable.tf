variable "docker_host" {
  description = "Docker daemon socket to connect to"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "docker_cert_path" {
  description = "Path to Docker certificates (if using remote host)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "docker"
}

variable "network_name" {
  description = "Docker network name"
  type        = string
  default     = "terraform-app-network"
}

variable "network_driver" {
  description = "Docker network driver"
  type        = string
  default     = "bridge"
}

variable "volume_names" {
  description = "List of Docker volumes to create"
  type        = list(string)
  default     = ["app-data", "app-logs"]
}

variable "container_name" {
  description = "Base name for Docker containers"
  type        = string
  default     = "webapp"
}

variable "container_count" {
  description = "Number of Docker containers to create"
  type        = number
  default     = 1
  validation {
    condition     = var.container_count > 0 && var.container_count <= 5
    error_message = "Container count must be between 1 and 5."
  }
}

variable "container_image" {
  description = "Docker image to use"
  type        = string
  default     = "terraform-webapp:latest"
}

variable "container_cpu_shares" {
  description = "CPU shares for containers"
  type        = number
  default     = 1024
}

variable "container_memory" {
  description = "Memory allocation for containers (in MB)"
  type        = number
  default     = 512
}

variable "container_ports" {
  description = "Port mappings for containers"
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = [
    {
      internal = 8080
      external = 8888
      protocol = "tcp"
    }
  ]
}

variable "container_env" {
  description = "Environment variables for containers"
  type        = list(string)
  default = [
    "NODE_ENV=development",
    "LOG_LEVEL=debug",
    "TIMEZONE=UTC"
  ]
}

variable "container_volumes" {
  description = "Volume mounts for containers"
  type = list(object({
    container_path = string
    host_path      = string
    volume_name    = string
    read_only      = bool
  }))
  default = [
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
}

variable "log_driver" {
  description = "Docker log driver"
  type        = string
  default     = "json-file"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    "Environment" = "docker"
    "Project"     = "terraform-webapp"
    "ManagedBy"   = "terraform"
    "CreatedAt"   = "2024-01-23"
  }
}
