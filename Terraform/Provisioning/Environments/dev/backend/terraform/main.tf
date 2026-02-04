terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

resource "docker_image" "custom_backend_image" {
  name = "${var.terraform_webapp_name}:${var.terraform_webapp_tag}"

  build {
    context    = "${path.module}/.."
    dockerfile = "${path.module}/../docker/Dockerfile"
  }

  triggers = {
    dockerfile_md5 = filemd5("${path.module}/../docker/Dockerfile")
    app_py_md5     = filemd5("${path.module}/../app/app.py")
    nginx_conf_md5 = filemd5("${path.module}/../config/nginx.conf")
  }
}

# Backend Docker container
resource "docker_container" "backend" {
  count = var.backend_container_count
  name  = "${var.backend_container_name}-${count.index + 1}"
  image = docker_image.custom_backend_image.name

  networks_advanced {
    name = var.network_name_backend
    aliases = ["backend"]
  }

  ports {
    internal = var.backend_port_internal
    external = var.backend_port_external
  }

  memory = var.backend_memory
  cpu_shares = var.backend_cpu

  depends_on = [
    # docker_network.app_network,
    docker_image.custom_backend_image
  ]
}
