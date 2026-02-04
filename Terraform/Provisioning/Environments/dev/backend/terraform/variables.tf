variable "environment" {}

variable "network_name_backend" {
  description = "Docker network name for backend"
  type        = string
}

variable "backend_container_name" {
  description = "Docker container name for backend"
  type        = string
  default     = "backend_app"
}

variable "backend_image_name" {
  description = "Docker image name for backend"
  type        = string
  default     = "backend_image"
}

variable "backend_image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "backend_port_internal" {
  default = 5000
}

variable "backend_port_external" {
  default = 5000
}

variable "backend_cpu" {
  default = "1"
}

variable "backend_memory" {
  default = "512"
}

variable "network_driver" {
  default = "bridge"
}

variable "IPAM_subnet" {
  default = "172.20.0.0/16"
}

variable "IPAM_gateway" {
  default = "172.20.0.1"
}

variable "ip_range" {
  default = "172.20.0.0/24"
}

variable "terraform_webapp_name" {
  default = "terraform_webapp"
}

variable "terraform_webapp_tag" {
  default = "v1.0.0"
}

variable "backend_container_count" {
  default = 1
}