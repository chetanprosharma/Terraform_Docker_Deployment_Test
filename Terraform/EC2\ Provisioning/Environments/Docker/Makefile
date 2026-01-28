.PHONY: help build run stop rm logs clean plan apply destroy \
        init-docker down up status test validate format

DOCKER_IMAGE := terraform-webapp:latest
DOCKER_PORT := 9090
CONTAINER_NAME := app-container-1

# Default target
help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║     Docker Terraform Project - Available Commands          ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "📦 Docker Commands:"
	@echo "  make build              Build Docker image"
	@echo "  make run                Run container"
	@echo "  make stop               Stop running container"
	@echo "  make rm                 Remove container"
	@echo "  make logs               View container logs"
	@echo "  make status             Check container status"
	@echo "  make test               Test API endpoints"
	@echo ""
	@echo "🏗️  Terraform Commands:"
	@echo "  make plan               Show terraform plan"
	@echo "  make apply              Apply infrastructure"
	@echo "  make destroy            Destroy infrastructure"
	@echo "  make validate           Validate terraform files"
	@echo "  make format             Format terraform files"
	@echo ""
	@echo "🧹 Cleanup Commands:"
	@echo "  make clean              Clean local files (not terraform)"
	@echo "  make clean-docker       Remove all Docker containers/images"
	@echo "  make down               Stop all services"
	@echo ""
	@echo "📋 Info Commands:"
	@echo "  make info               Show project info"
	@echo "  make structure          Show directory structure"
	@echo "  make ls                 List all project files"
	@echo ""

# ============================================================================
# DOCKER COMMANDS
# ============================================================================

build:
	@echo "🔨 Building Docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) -f docker/Dockerfile .
	@echo "✅ Build complete!"

run: build
	@echo "🚀 Starting container..."
	docker run -d --name $(CONTAINER_NAME) -p $(DOCKER_PORT):80 $(DOCKER_IMAGE)
	@echo "✅ Container running on http://localhost:$(DOCKER_PORT)"
	@sleep 3
	@echo "📊 Container status:"
	@docker ps | grep $(CONTAINER_NAME)

stop:
	@echo "⏹️  Stopping container..."
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@echo "✅ Container stopped"

rm: stop
	@echo "🗑️  Removing container..."
	docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@echo "✅ Container removed"

logs:
	@echo "📜 Container logs:"
	docker logs $(CONTAINER_NAME) 2>/dev/null || echo "Container not running"

status:
	@echo "📊 Docker status:"
	@docker ps | head -2
	@docker ps -a | grep $(CONTAINER_NAME) || echo "Container not found"

test:
	@echo "🧪 Testing API endpoints..."
	@echo ""
	@echo "1️⃣  Health Check:"
	@curl -s http://localhost:$(DOCKER_PORT)/api/health | python3 -m json.tool 2>/dev/null || echo "Service unavailable"
	@echo ""
	@echo "2️⃣  Statistics:"
	@curl -s http://localhost:$(DOCKER_PORT)/api/stats | python3 -m json.tool 2>/dev/null || echo "Service unavailable"
	@echo ""
	@echo "3️⃣  Messages:"
	@curl -s http://localhost:$(DOCKER_PORT)/api/messages | python3 -m json.tool 2>/dev/null || echo "Service unavailable"

# ============================================================================
# TERRAFORM COMMANDS
# ============================================================================

plan:
	@echo "📋 Terraform Plan:"
	terraform plan -out=tfplan

apply: plan
	@echo "🚀 Applying Terraform..."
	terraform apply tfplan
	@echo "✅ Infrastructure deployed!"

destroy:
	@echo "⚠️  Destroying infrastructure..."
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform destroy --auto-approve; \
		echo "✅ Infrastructure destroyed"; \
	else \
		echo "❌ Destroy cancelled"; \
	fi

validate:
	@echo "✔️  Validating Terraform files..."
	terraform validate
	@echo "✅ Validation passed!"

format:
	@echo "📐 Formatting Terraform files..."
	terraform fmt -recursive
	@echo "✅ Files formatted!"

state-show:
	@echo "📊 Terraform State:"
	terraform show -json | python3 -m json.tool | head -100

# ============================================================================
# CLEANUP COMMANDS
# ============================================================================

clean:
	@echo "🧹 Cleaning local files..."
	rm -f tfplan terraform.tfstate.backup
	@echo "✅ Cleanup complete!"

clean-docker:
	@echo "🧹 Cleaning Docker..."
	docker stop $$(docker ps -q) 2>/dev/null || true
	docker rm -f $$(docker ps -aq) 2>/dev/null || true
	docker rmi -f $(DOCKER_IMAGE) 2>/dev/null || true
	@echo "✅ Docker cleanup complete!"

down: stop
	@echo "🛑 Services stopped"

# ============================================================================
# INFO COMMANDS
# ============================================================================

info:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║           Project Configuration                            ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo "Image Name:       $(DOCKER_IMAGE)"
	@echo "Container Name:   $(CONTAINER_NAME)"
	@echo "External Port:    $(DOCKER_PORT)"
	@echo "Internal Port:    80 (Nginx), 5000 (Flask)"
	@echo ""
	@echo "Project Location:"
	@pwd
	@echo ""
	@echo "Files Summary:"
	@find . -type f \( -name "*.py" -o -name "*.tf" -o -name "*.conf" -o -name "*.html" \) \
		-not -path './.*' | wc -l | xargs echo "Total files:"
	@echo ""

structure:
	@echo "📁 Project Structure:"
	@echo ""
	@find . -type d -not -path './.*' -not -path '*/.terraform*' | sort | sed 's|^\./||' | awk '{print "  " $$0}'
	@echo ""

ls:
	@echo "📋 Project Files:"
	@echo ""
	@echo "App Files (app/):"
	@ls -1 app/ 2>/dev/null | awk '{print "  ├─ " $$0}'
	@echo ""
	@echo "Config Files (config/):"
	@ls -1 config/*.conf config/*.json 2>/dev/null | xargs -I {} basename {} | awk '{print "  ├─ " $$0}'
	@echo ""
	@echo "Docker Files (docker/):"
	@ls -1 docker/ 2>/dev/null | awk '{print "  ├─ " $$0}'
	@echo ""
	@echo "Web Files (web/html/):"
	@ls -1 web/html/ 2>/dev/null | awk '{print "  ├─ " $$0}'
	@echo ""
	@echo "Terraform Files:"
	@ls -1 *.tf 2>/dev/null | awk '{print "  ├─ " $$0}'
	@echo ""

# ============================================================================
# COMPOSITE COMMANDS
# ============================================================================

full-deploy: clean-docker build apply test
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║           ✅ Full Deployment Complete!                     ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Access the application at: http://localhost:$(DOCKER_PORT)"
	@echo ""

rebuild: clean-docker build
	@echo "✅ Rebuild complete!"

restart: stop rm run
	@echo "✅ Services restarted!"

# Default when no target specified
.DEFAULT_GOAL := help
