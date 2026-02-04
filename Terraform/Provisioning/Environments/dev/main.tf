# Create a shared Docker network for frontend & backend
resource "docker_network" "shared_network" {
  name   = "${var.environment}_shared_network"
  driver = "bridge"
}

module "backend" {
  source               = "./backend/terraform"
  environment          = var.environment
  network_name_backend = docker_network.shared_network.name
}

# Call frontend module
module "frontend" {
  source                = "./frontend/terraform"
  environment           = var.environment
  network_name_frontend = docker_network.shared_network.name
}

# resource "docker_network" "app_network" {
#   name = "app-network-${terraform.workspace}"
# }