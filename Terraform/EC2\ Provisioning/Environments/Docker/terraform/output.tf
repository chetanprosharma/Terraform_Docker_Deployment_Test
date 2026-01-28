output "docker_image_id" {
  description = "ID of the built Docker image"
  value       = try(docker_image.custom_image.image_id, null)
}

output "docker_network_id" {
  description = "ID of the Docker network"
  value       = try(docker_network.app_network.id, null)
}

output "docker_network_name" {
  description = "Name of the Docker network"
  value       = try(docker_network.app_network.name, null)
}

output "docker_volumes" {
  description = "Map of created Docker volumes"
  value = try({
    for volume in docker_volume.app_volumes : volume.name => {
      id     = volume.id
      name   = volume.name
      driver = volume.driver
    }
  }, {})
}

output "container_ids" {
  description = "List of Docker container IDs"
  value       = try([for container in docker_container.app : container.id], [])
}

output "container_names" {
  description = "List of Docker container names"
  value       = try([for container in docker_container.app : container.name], [])
}

output "container_ips" {
  description = "List of Docker container IP addresses"
  value = try([for container in docker_container.app : {
    name = container.name
    ip   = container.networks_advanced[0].ipv4_address
  }], [])
}

output "container_ports" {
  description = "Port mappings for containers"
  value = try([for container in docker_container.app : {
    name  = container.name
    ports = [for port in container.ports : "${port.external}:${port.internal}/${port.protocol}"]
  }], [])
}

output "docker_compose_file_path" {
  description = "Path to generated docker-compose.yml"
  value       = try(local_file.docker_compose.filename, null)
}

output "setup_script_path" {
  description = "Path to container setup script"
  value       = try(local_file.container_setup_script.filename, null)
}

output "provisioning_summary" {
  description = "Summary of Docker provisioning"
  value = {
    environment     = var.environment
    network_name    = var.network_name
    container_count = var.container_count
    container_name  = var.container_name
    volumes_count   = length(var.volume_names)
    provisioned_at  = timestamp()
    managed_by      = "Terraform"
  }
}
