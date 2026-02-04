# Configure the Docker provider
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Docker provider settings
provider "docker" {
  host      = var.docker_host
  cert_path = var.docker_cert_path != "" ? var.docker_cert_path : null
}
