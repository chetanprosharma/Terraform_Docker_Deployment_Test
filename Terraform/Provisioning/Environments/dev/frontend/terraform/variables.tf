variable "environment" {}

variable "network_name_frontend" {
  description = "Docker network name for frontend"
  type        = string
}

variable "frontend_container_name" {
  default = "frontend_app"
}

variable "frontend_image_name" {
  default = "frontend_image"
}

variable "frontend_image_tag" {
  default = "latest"
}

variable "frontend_port_internal" {
  default = 3000
}

variable "frontend_port_external" {
  default = 3000
}


variable "frontend_cpu" {
  default = "1"
}

variable "frontend_memory" {
  default = "256"
}

variable "container_name" {
  description = "Base name for frontend containers"
  type        = string
  default     = "frontend_app"
}

variable "frontend_container_count" {
  description = "Number of frontend containers to deploy"
  type        = number
  default     = 1
}
