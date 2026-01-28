#!/bin/bash

##############################################################################
# Smoke Tests Script
# Purpose: Quick validation tests for deployed infrastructure
# Usage: ./smoke-tests.sh <environment> <target_url>
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-local}"
TARGET_URL="${2:-http://localhost:9090}"
TIMEOUT=10
FAILED_TESTS=0
PASSED_TESTS=0

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Smoke Tests - ${ENVIRONMENT} Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo "Target URL: ${TARGET_URL}"
echo "Timeout: ${TIMEOUT}s"
echo ""

##############################################################################
# Test Helper Functions
##############################################################################

test_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local description=$3
    
    echo -ne "Testing: ${description}... "
    
    local response=$(curl -s -w "\n%{http_code}" \
                          --connect-timeout ${TIMEOUT} \
                          --max-time ${TIMEOUT} \
                          "${TARGET_URL}${endpoint}" 2>/dev/null || echo "000")
    
    local http_code=$(echo "${response}" | tail -n1)
    
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ FAIL (got ${http_code}, expected ${expected_status})${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

test_endpoint_contains() {
    local endpoint=$1
    local expected_string=$2
    local description=$3
    
    echo -ne "Testing: ${description}... "
    
    local response=$(curl -s --connect-timeout ${TIMEOUT} \
                          --max-time ${TIMEOUT} \
                          "${TARGET_URL}${endpoint}" 2>/dev/null || echo "")
    
    if echo "${response}" | grep -q "${expected_string}"; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Expected to find: ${expected_string}"
        echo "  Got: ${response:0:100}"
        ((FAILED_TESTS++))
        return 1
    fi
}

test_connectivity() {
    local host=$1
    local port=$2
    local description=$3
    
    echo -ne "Testing: ${description}... "
    
    if timeout ${TIMEOUT} bash -c "cat </dev/null >(nc -l 127.0.0.1 ${port}) 2>/dev/null" >/dev/null 2>&1 || \
       timeout ${TIMEOUT} bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

##############################################################################
# API Health Checks
##############################################################################

echo -e "${YELLOW}[1/5] API Health Checks${NC}"
echo "─────────────────────────────────────────────────────"

test_endpoint "/api/health" "200" "Health endpoint"
test_endpoint_contains "/api/health" "status" "Health check returns status"
test_endpoint "/api/stats" "200" "Statistics endpoint"

echo ""

##############################################################################
# Frontend Tests
##############################################################################

echo -e "${YELLOW}[2/5] Frontend Tests${NC}"
echo "─────────────────────────────────────────────────────"

test_endpoint "/" "200" "Root path accessible"
test_endpoint_contains "/" "html" "HTML content returned"
test_endpoint_contains "/" "head" "Valid HTML structure"

echo ""

##############################################################################
# API Response Validation
##############################################################################

echo -e "${YELLOW}[3/5] API Response Validation${NC}"
echo "─────────────────────────────────────────────────────"

test_endpoint_contains "/api/stats" "connections" "Stats contains connections"
test_endpoint_contains "/api/stats" "uptime" "Stats contains uptime"

echo ""

##############################################################################
# Performance Checks
##############################################################################

echo -e "${YELLOW}[4/5] Performance Checks${NC}"
echo "─────────────────────────────────────────────────────"

echo -ne "Testing: Response time < 2s... "
start_time=$(date +%s%N)
curl -s --connect-timeout ${TIMEOUT} \
     --max-time ${TIMEOUT} \
     "${TARGET_URL}/api/health" > /dev/null 2>&1
end_time=$(date +%s%N)

elapsed_ms=$(( (end_time - start_time) / 1000000 ))

if [ ${elapsed_ms} -lt 2000 ]; then
    echo -e "${GREEN}✓ PASS (${elapsed_ms}ms)${NC}"
    ((PASSED_TESTS++))
else
    echo -e "${YELLOW}⚠ SLOW (${elapsed_ms}ms)${NC}"
fi

echo ""

##############################################################################
# Service Availability
##############################################################################

echo -e "${YELLOW}[5/5] Service Availability${NC}"
echo "─────────────────────────────────────────────────────"

# Check if service is running
if curl -s --connect-timeout 2 "${TARGET_URL}" > /dev/null 2>&1; then
    echo -e "Service Status: ${GREEN}RUNNING${NC}"
    ((PASSED_TESTS++))
else
    echo -e "Service Status: ${RED}UNREACHABLE${NC}"
    ((FAILED_TESTS++))
fi

echo ""

##############################################################################
# Summary
##############################################################################

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo "Test Summary"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))

echo -e "Total Tests:  ${TOTAL_TESTS}"
echo -e "Passed:       ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed:       ${RED}${FAILED_TESTS}${NC}"

if [ ${TOTAL_TESTS} -gt 0 ]; then
    PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "Pass Rate:    ${PASS_RATE}%"
fi

echo ""

# Exit with appropriate code
if [ ${FAILED_TESTS} -eq 0 ]; then
    echo -e "${GREEN}✓ All smoke tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ ${FAILED_TESTS} smoke test(s) failed!${NC}"
    exit 1
fi
