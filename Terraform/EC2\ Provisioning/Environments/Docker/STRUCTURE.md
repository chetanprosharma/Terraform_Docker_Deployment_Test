# Docker Terraform Project Structure

## 📁 Directory Organization

```
Docker/
├── app/                      # Application code
│   ├── app.py               # Flask backend API
│   ├── requirements.txt      # Python dependencies
│   └── start.sh             # Container startup script
│
├── config/                  # Configuration files
│   ├── nginx.conf           # Nginx configuration
│   ├── docker-config.json   # Docker config (generated)
│   └── .docker.env          # Environment variables (generated)
│
├── docker/                  # Docker-related files
│   └── Dockerfile           # Container image definition
│
├── web/                     # Web frontend
│   └── html/
│       └── index.html       # Web interface
│
├── terraform/               # Terraform infrastructure code
│   ├── *.tf files          # Configuration files (linked to root)
│   └── modules/            # Terraform modules (linked to root)
│
├── scripts/                # Utility scripts
│   ├── docker-compose.yml  # Docker Compose (generated)
│   └── setup-containers.sh # Setup script (generated)
│
├── modules/                # Root-level modules (copy from terraform/modules)
│   └── *.tf                # Module definitions
│
├── *.tf files              # Terraform files in root
│   ├── main.tf
│   ├── variable.tf
│   └── output.tf
│
└── README.md               # Project documentation
```

## 🚀 Quick Start

### View Project Status
```bash
ls -la                          # List all files
ls -lR                          # Recursive listing
```

### Docker Operations
```bash
# Build image
docker build -t terraform-webapp:latest -f docker/Dockerfile .

# Run container manually
docker run -d -p 9090:80 terraform-webapp:latest

# Check container status
docker ps -a
docker logs <container-id>

# Stop and remove
docker stop <container-id>
docker rm <container-id>
```

### Terraform Operations (Ready to use)
```bash
# View terraform files (already initialized)
cat main.tf
cat variable.tf
cat output.tf

# Plan infrastructure (when ready)
terraform plan

# Apply infrastructure (when ready)
terraform apply --auto-approve

# Destroy infrastructure (when ready)
terraform destroy --auto-approve

# Show state
terraform show
```

## 📝 File Descriptions

### Application Files (`app/`)
- **app.py**: Python Flask backend API with endpoints:
  - `/api/health` - Health check
  - `/api/messages` - Message CRUD operations
  - `/api/stats` - Statistics
  - `/api/about` - API information

- **requirements.txt**: Python package dependencies
  - Flask==2.3.0
  - Werkzeug==2.3.0

- **start.sh**: Shell script to start both services:
  - Launches nginx in background
  - Launches Flask API in background
  - Keeps container alive

### Configuration Files (`config/`)
- **nginx.conf**: Web server configuration
  - Serves static HTML on `/`
  - Proxies `/api/` to Flask backend
  - CORS headers enabled

- **docker-config.json**: Docker environment metadata (auto-generated)
- **.docker.env**: Environment variables (auto-generated)

### Docker Files (`docker/`)
- **Dockerfile**: Multi-stage container definition
  - Base: nginx:alpine
  - Installs Python3, pip, curl
  - Copies app files, web files, configs
  - Exposes ports 80, 5000
  - Health check via API
  - Starts both services

### Web Files (`web/`)
- **html/index.html**: Frontend web interface
  - HTML5 markup with responsive design
  - JavaScript to call backend API
  - Real-time message board
  - Statistics dashboard
  - Auto-refresh health status

### Terraform Files (Root level)
- **main.tf**: Core infrastructure code
  - Docker provider configuration
  - Image build with file triggers
  - Network creation
  - Container deployment
  - Local file management

- **variable.tf**: Input variables
  - Docker host configuration
  - Container settings
  - Network configuration
  - Port mappings
  - Environment variables

- **output.tf**: Output values
  - Container IDs and IPs
  - Access URLs
  - Service information

### Terraform Modules (`terraform/modules/` or `modules/`)
- **user_module.tf**: Custom module definitions
  - User-defined configurations
  - Module templates

## 🔧 Configuration Management

### Adding a New File
1. Create file in appropriate directory
2. If adding to app: update `requirements.txt` if needed
3. If adding config: update `docker/Dockerfile` COPY command
4. If modifying code: Terraform triggers will auto-detect changes

### Updating Configuration
1. Modify files in their respective directories
2. Terraform file triggers monitor: `Dockerfile`, `app.py`, `nginx.conf`, `index.html`
3. Changes trigger automatic image rebuild on next `terraform apply`

### Environment Variables
- Edit `variable.tf` to add new variables
- Set values in `.terraform.tfvars` or via `-var` flag
- Environment values stored in `config/.docker.env`

## 📊 Container Details

**Image Name**: `terraform-webapp:latest`

**Ports**:
- External: `9090` → Internal: `80` (nginx)
- Internal: `5000` (Flask API)

**Services**:
- Nginx: Web server + static file serving + reverse proxy
- Flask: Python API backend
- Both services run in single container

**Health Check**:
- Runs every 10 seconds
- Checks `GET /api/health` endpoint
- 3 retries, 5-second timeout

## 🛠️ Troubleshooting

### Container won't start
```bash
docker logs app-container-1  # Check error messages
docker run -it terraform-webapp:latest /bin/sh  # Debug interactively
```

### Port already in use
```bash
# Change external port in variable.tf
# Or kill existing process
lsof -i :9090
kill -9 <PID>
```

### File not found errors
```bash
# Verify file locations
find . -name "*.py"
find . -name "*.conf"
find . -name "*.html"
```

### Terraform state issues
```bash
# View current state
terraform show

# Check state file
cat terraform.tfstate | python3 -m json.tool
```

## 📚 References

- **Docker**: https://docs.docker.com/
- **Terraform**: https://www.terraform.io/docs
- **Flask**: https://flask.palletsprojects.com/
- **Nginx**: https://nginx.org/en/docs/

---

**Created**: 2026-01-23
**Project**: Terraform Docker Full-Stack Application
**Status**: Ready for deployment
