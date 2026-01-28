# Quick Reference Guide

## 🚀 Most Common Commands

```bash
# View project structure and files
make help              # Shows all available commands
make info              # Project configuration details
make ls                # List all project files

# Build and run everything
make build             # Build Docker image
make run               # Start container locally
make test              # Test API endpoints
make stop              # Stop container

# Deploy with Terraform (when ready)
make plan              # Preview infrastructure changes
make apply             # Deploy infrastructure
make destroy           # Remove infrastructure

# Clean up
make clean             # Remove build artifacts
make clean-docker      # Stop all containers

# All-in-one deployment
make full-deploy       # Build, deploy, and test everything
```

---

## 📁 Finding Files

**Backend API Code**: `app/app.py`
```bash
# Edit Flask API endpoints
nano app/app.py
```

**Frontend HTML**: `web/html/index.html`
```bash
# Edit web interface
nano web/html/index.html
```

**Nginx Configuration**: `config/nginx.conf`
```bash
# Update web server settings
nano config/nginx.conf
```

**Python Dependencies**: `app/requirements.txt`
```bash
# Add/remove Python packages
nano app/requirements.txt
```

**Docker Image**: `docker/Dockerfile`
```bash
# Update container definition
nano docker/Dockerfile
```

**Terraform Code**: `main.tf`, `variable.tf`, `output.tf`
```bash
# Manage infrastructure as code
nano main.tf
nano variable.tf
nano output.tf
```

---

## 🔄 Typical Workflows

### Update Code and Redeploy
```bash
# 1. Edit your code (e.g., app/app.py)
nano app/app.py

# 2. Rebuild image with changes
make rebuild

# 3. Restart container
make restart

# 4. Test changes
make test
```

### Add Python Package
```bash
# 1. Add to requirements.txt
echo "requests==2.28.0" >> app/requirements.txt

# 2. Rebuild and deploy
make full-deploy
```

### Scale Up Infrastructure
```bash
# 1. Update variable.tf (e.g., container_count)
nano variable.tf

# 2. Plan changes
make plan

# 3. Apply changes
make apply
```

### Troubleshoot Issues
```bash
# Check logs
make logs

# Check container status
make status

# Test endpoints manually
make test

# Enter container shell
docker exec -it app-container-1 /bin/sh
```

---

## 📊 Service Endpoints

When running locally:

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | http://localhost:9090 | Web interface |
| API Health | http://localhost:9090/api/health | Service status |
| API Messages | http://localhost:9090/api/messages | Message CRUD |
| API Stats | http://localhost:9090/api/stats | Statistics |
| API About | http://localhost:9090/api/about | API info |

---

## 🛠️ File Organization Summary

```
Docker/
├── app/                    # Application logic
│   ├── app.py             # Main API
│   ├── requirements.txt    # Dependencies
│   └── start.sh           # Startup script
│
├── config/                # Configuration
│   └── nginx.conf         # Web server config
│
├── docker/                # Container definition
│   └── Dockerfile         # Image recipe
│
├── web/                   # Frontend
│   └── html/index.html    # Web interface
│
├── terraform/             # Infrastructure (in modules/)
│   ├── main.tf           # Core infrastructure
│   ├── variable.tf       # Input variables
│   ├── output.tf         # Outputs
│   └── modules/          # Reusable components
│
├── main.tf ────────────→ (linked to terraform/)
├── variable.tf ────────→ (linked to terraform/)
├── output.tf ──────────→ (linked to terraform/)
├── modules/ ───────────→ (linked to terraform/modules/)
│
├── Makefile              # Command shortcuts
├── STRUCTURE.md          # Detailed guide
├── QUICKREF.md           # This file
├── .gitignore            # Git exclusions
└── README.md             # Project overview
```

---

## ✨ Pro Tips

1. **Use Make**: All commands available via `make <command>`
   ```bash
   make help  # See all options
   ```

2. **Check Logs**: Always check logs when debugging
   ```bash
   make logs
   docker logs app-container-1
   ```

3. **Edit Config Files**: Terraform file triggers auto-detect changes
   - Changes to `app.py`, `nginx.conf`, `Dockerfile`, `index.html` trigger rebuild

4. **Backup State**: Keep `terraform.tfstate` safe for production
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

5. **Use Terraform Plan**: Always review before applying
   ```bash
   make plan
   # Review output, then:
   make apply
   ```

---

## 🆘 Emergency Commands

```bash
# Stop everything
docker stop $(docker ps -q)
docker rm $(docker ps -aq)

# Clean all Docker
docker system prune -a

# Check what's running
docker ps -a

# View container details
docker inspect app-container-1

# Restart specific service
docker restart app-container-1
```

---

**Last Updated**: 2026-01-23
**Project**: Docker Terraform Full-Stack Application
