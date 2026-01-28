#!/bin/bash

##############################################################################
# Health Check Script
# Purpose: Validate that all infrastructure components are running
# Usage: ./health-checks.sh <environment> <config_file>
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
ENVIRONMENT="${1:-local}"
CONFIG_FILE="${2:-.}"
TIMEOUT=5
CHECKS_PASSED=0
CHECKS_FAILED=0

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Health Check - ${ENVIRONMENT} Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

##############################################################################
# Check Functions
##############################################################################

check_command() {
    local cmd=$1
    local description=$2
    
    echo -ne "Checking: ${description}... "
    
    if command -v "${cmd}" &> /dev/null; then
        VERSION=$("${cmd}" --version 2>/dev/null | head -1 || echo "installed")
        echo -e "${GREEN}✓ OK${NC} (${VERSION})"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ MISSING${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

check_port() {
    local host=$1
    local port=$2
    local description=$3
    
    echo -ne "Checking: ${description}... "
    
    if timeout ${TIMEOUT} bash -c "cat </dev/null >(nc -l 127.0.0.1 ${port}) 2>/dev/null" >/dev/null 2>&1 || \
       timeout ${TIMEOUT} bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null; then
        echo -e "${GREEN}✓ OPEN${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ CLOSED${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

check_url() {
    local url=$1
    local description=$2
    local expected_code=${3:-200}
    
    echo -ne "Checking: ${description}... "
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                     --connect-timeout ${TIMEOUT} \
                     --max-time ${TIMEOUT} \
                     "${url}" 2>/dev/null || echo "000")
    
    if [ "${HTTP_CODE}" = "${expected_code}" ]; then
        echo -e "${GREEN}✓ HEALTHY${NC} (${HTTP_CODE})"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ UNHEALTHY${NC} (got ${HTTP_CODE}, expected ${expected_code})"
        ((CHECKS_FAILED++))
        return 1
    fi
}

check_file() {
    local file=$1
    local description=$2
    
    echo -ne "Checking: ${description}... "
    
    if [ -f "${file}" ]; then
        SIZE=$(stat --printf='%s' "${file}" 2>/dev/null || stat -f%z "${file}" 2>/dev/null || echo "?")
        echo -e "${GREEN}✓ EXISTS${NC} (${SIZE} bytes)"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ MISSING${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

check_dir() {
    local dir=$1
    local description=$2
    
    echo -ne "Checking: ${description}... "
    
    if [ -d "${dir}" ]; then
        COUNT=$(find "${dir}" -type f 2>/dev/null | wc -l)
        echo -e "${GREEN}✓ EXISTS${NC} (${COUNT} files)"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ MISSING${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

check_env_var() {
    local var=$1
    local description=$2
    
    echo -ne "Checking: ${description}... "
    
    if [ -n "${!var}" ]; then
        echo -e "${GREEN}✓ SET${NC} (${!var:0:20}...)"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ NOT SET${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

##############################################################################
# Required Tools
##############################################################################

echo -e "${YELLOW}[1] Required Tools${NC}"
echo "─────────────────────────────────────────────────────"

check_command "terraform" "Terraform CLI"
check_command "docker" "Docker Engine"
check_command "curl" "curl utility"
check_command "git" "Git"
check_command "jq" "jq JSON processor" || true

echo ""

##############################################################################
# Terraform State
##############################################################################

echo -e "${YELLOW}[2] Terraform State${NC}"
echo "─────────────────────────────────────────────────────"

# Navigate to appropriate environment directory
case "${ENVIRONMENT}" in
    dev)
        TF_DIR="/home/chetan/Desktop/DevOps/Terraform/EC2 Provisioning/Environments/Dev"
        ;;
    test)
        TF_DIR="/home/chetan/Desktop/DevOps/Terraform/EC2 Provisioning/Environments/Test"
        ;;
    prod)
        TF_DIR="/home/chetan/Desktop/DevOps/Terraform/EC2 Provisioning/Environments/Prod"
        ;;
    docker)
        TF_DIR="/home/chetan/Desktop/DevOps/Terraform/EC2 Provisioning/Environments/Docker"
        ;;
    local)
        TF_DIR="/home/chetan/Desktop/DevOps/Terraform/EC2 Provisioning/Environments/Local"
        ;;
    *)
        TF_DIR="."
        ;;
esac

if [ -d "${TF_DIR}" ]; then
    check_file "${TF_DIR}/main.tf" "Terraform main configuration"
    check_dir "${TF_DIR}/.terraform" "Terraform module cache" || echo -e "  ${YELLOW}⚠ Not initialized${NC}"
    
    if [ -f "${TF_DIR}/terraform.tfstate" ]; then
        check_file "${TF_DIR}/terraform.tfstate" "Terraform state file"
    fi
else
    echo -e "Terraform directory not found: ${TF_DIR}"
fi

echo ""

##############################################################################
# Docker Services
##############################################################################

echo -e "${YELLOW}[3] Docker Services${NC}"
echo "─────────────────────────────────────────────────────"

echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Docker daemon not running"

echo ""
echo -ne "Checking: Docker daemon... "
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✓ RUNNING${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}✗ NOT RUNNING${NC}"
    ((CHECKS_FAILED++))
fi

echo ""

##############################################################################
# Network Connectivity
##############################################################################

echo -e "${YELLOW}[4] Network Connectivity${NC}"
echo "─────────────────────────────────────────────────────"

check_url "http://localhost:9090/api/health" "Application health endpoint" || true
check_url "http://localhost:9091/api/health" "Backup application endpoint" || true
check_url "http://localhost:80" "HTTP port" || true
check_url "https://api.github.com/zen" "Internet connectivity" || true

echo ""

##############################################################################
# Project Files
##############################################################################

echo -e "${YELLOW}[5] Project Files${NC}"
echo "─────────────────────────────────────────────────────"

PROJECT_ROOT="/home/chetan/Desktop/DevOps"

check_dir "${PROJECT_ROOT}/Terraform" "Terraform directory"
check_dir "${PROJECT_ROOT}/tests" "Test scripts directory"
check_file "${PROJECT_ROOT}/Makefile" "Makefile" || true
check_file "${PROJECT_ROOT}/Terraform/EC2 Provisioning/Jenkinsfile" "Main Jenkinsfile"

echo ""

##############################################################################
# Environment Variables
##############################################################################

echo -e "${YELLOW}[6] Environment Variables${NC}"
echo "─────────────────────────────────────────────────────"

echo -ne "Checking: Jenkins availability... "
if [ -n "${JENKINS_HOME}" ]; then
    echo -e "${GREEN}✓ JENKINS_HOME set${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠ JENKINS_HOME not set${NC}"
fi

echo -ne "Checking: Git configuration... "
if git config --global user.name > /dev/null 2>&1; then
    GIT_USER=$(git config --global user.name)
    echo -e "${GREEN}✓ Configured${NC} (${GIT_USER})"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠ Not configured${NC}"
fi

echo ""

##############################################################################
# Summary
##############################################################################

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo "Health Check Summary"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED))

echo "Checks Performed: ${TOTAL_CHECKS}"
echo -e "Passed: ${GREEN}${CHECKS_PASSED}${NC}"
echo -e "Failed: ${RED}${CHECKS_FAILED}${NC}"

if [ ${TOTAL_CHECKS} -gt 0 ]; then
    PASS_RATE=$((CHECKS_PASSED * 100 / TOTAL_CHECKS))
    echo "Health Score: ${PASS_RATE}%"
fi

echo ""
echo "Timestamp: $(date)"

if [ ${CHECKS_FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All health checks passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ ${CHECKS_FAILED} check(s) need attention${NC}"
    exit 0  # Don't fail, just warn
fi
