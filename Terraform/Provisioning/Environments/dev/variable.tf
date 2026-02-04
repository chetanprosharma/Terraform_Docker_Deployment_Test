variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# variable "network_name" {
#   description = "Docker network name"
#   type        = string
#   default     = "dev_network"
# }

variable "docker_host" {
  description = "Docker host URL"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "docker_cert_path" {
  description = "Path to Docker TLS certificates"
  type        = string
  default     = ""
}

# variable "bridge" {
#   description = "Docker network driver"
#   type        = string
#   default     = "bridge"
# }