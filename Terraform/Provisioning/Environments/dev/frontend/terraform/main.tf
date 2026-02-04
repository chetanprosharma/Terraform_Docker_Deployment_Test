terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

resource "docker_image" "custom_frontend_image" {
  name         = "${var.frontend_image_name}:${var.frontend_image_tag}"
  build {
    context    = "${path.module}/.."
    dockerfile = "${path.module}/../docker/Dockerfile"
  }

  triggers = {
    image_tag      = var.frontend_image_tag
    dockerfile_md5 = filemd5("${path.module}/../docker/Dockerfile")
    app_html_md5   = filemd5("${path.module}/../web/html/index.html")
    # nginx_conf_md5 = filemd5("${path.module}/../config/nginx.conf")
  }
}

resource "docker_container" "frontend" {
  count = var.frontend_container_count
  name  = "${var.container_name}-${count.index + 1}"
  image = docker_image.custom_frontend_image.name

  networks_advanced {
    name = var.network_name_frontend
  }

  ports {
    internal = var.frontend_port_internal
    external = var.frontend_port_external
  }

  memory = var.frontend_memory
  cpu_shares = var.frontend_cpu
  restart = "unless-stopped"
}
