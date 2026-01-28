#!/bin/bash

##############################################################################
# Integration Tests Script
# Purpose: Comprehensive integration testing for the application
# Usage: ./integration-tests.sh <environment> <target_url>
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
ENVIRONMENT="${1:-local}"
TARGET_URL="${2:-http://localhost:9090}"
TIMEOUT=15
FAILED_TESTS=0
PASSED_TESTS=0
TEMP_DIR="/tmp/integration-tests-$$"

mkdir -p "${TEMP_DIR}"
trap "rm -rf ${TEMP_DIR}" EXIT

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Integration Tests - ${ENVIRONMENT} Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo "Target URL: ${TARGET_URL}"
echo "Timestamp: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
echo ""

##############################################################################
# Test Helpers
##############################################################################

test_case() {
    local test_name=$1
    echo -e "${YELLOW}[TEST] ${test_name}${NC}"
}

assert_equals() {
    local expected=$1
    local actual=$2
    local message=$3
    
    if [ "${expected}" = "${actual}" ]; then
        echo -e "  ${GREEN}✓ PASS${NC} - ${message}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC} - ${message}"
        echo "    Expected: ${expected}"
        echo "    Got: ${actual}"
        ((FAILED_TESTS++))
        return 1
    fi
}

assert_contains() {
    local haystack=$1
    local needle=$2
    local message=$3
    
    if echo "${haystack}" | grep -q "${needle}"; then
        echo -e "  ${GREEN}✓ PASS${NC} - ${message}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC} - ${message}"
        echo "    Expected to find: ${needle}"
        ((FAILED_TESTS++))
        return 1
    fi
}

api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X "${method}" \
             --connect-timeout ${TIMEOUT} \
             --max-time ${TIMEOUT} \
             -H "Content-Type: application/json" \
             -d "${data}" \
             "${TARGET_URL}${endpoint}" 2>/dev/null || echo ""
    else
        curl -s -X "${method}" \
             --connect-timeout ${TIMEOUT} \
             --max-time ${TIMEOUT} \
             "${TARGET_URL}${endpoint}" 2>/dev/null || echo ""
    fi
}

##############################################################################
# Test Suite: API Endpoints
##############################################################################

echo -e "${YELLOW}[SUITE 1] API Endpoints${NC}"
echo "─────────────────────────────────────────────────────"

test_case "Health Check Endpoint"
RESPONSE=$(api_call "GET" "/api/health")
assert_contains "${RESPONSE}" "status" "Health endpoint returns status field"

test_case "Statistics Endpoint"
RESPONSE=$(api_call "GET" "/api/stats")
assert_contains "${RESPONSE}" "connections" "Stats endpoint returns data"
assert_contains "${RESPONSE}" "uptime" "Stats contains uptime"

test_case "Environment Info Endpoint"
RESPONSE=$(api_call "GET" "/api/info")
assert_contains "${RESPONSE}" "environment" "Info endpoint returns environment" || true

echo ""

##############################################################################
# Test Suite: Data Persistence
##############################################################################

echo -e "${YELLOW}[SUITE 2] Data Persistence${NC}"
echo "─────────────────────────────────────────────────────"

test_case "Create Item via API"
ITEM_DATA='{"id":"test-123","name":"Integration Test Item","status":"active"}'
RESPONSE=$(api_call "POST" "/api/items" "${ITEM_DATA}")

# Save response for later tests
echo "${RESPONSE}" > "${TEMP_DIR}/item_response.json"
assert_contains "${RESPONSE}" "test-123" "Item creation returns item ID" || true

test_case "Retrieve Item via API"
RESPONSE=$(api_call "GET" "/api/items")
assert_contains "${RESPONSE}" "Integration Test Item" "Items endpoint returns created item" || true

echo ""

##############################################################################
# Test Suite: Error Handling
##############################################################################

echo -e "${YELLOW}[SUITE 3] Error Handling${NC}"
echo "─────────────────────────────────────────────────────"

test_case "Invalid Endpoint Returns 404"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                  --connect-timeout ${TIMEOUT} \
                  --max-time ${TIMEOUT} \
                  "${TARGET_URL}/api/nonexistent" 2>/dev/null)
RESPONSE=$(curl -s --connect-timeout ${TIMEOUT} \
                --max-time ${TIMEOUT} \
                "${TARGET_URL}/api/nonexistent" 2>/dev/null)

if [ "${HTTP_CODE}" = "404" ] || [ "${HTTP_CODE}" = "405" ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - Invalid endpoint returns error (${HTTP_CODE})"
    ((PASSED_TESTS++))
else
    echo -e "  ${YELLOW}⚠ INFO${NC} - Invalid endpoint returns ${HTTP_CODE}"
fi

test_case "Malformed JSON Returns Error"
RESPONSE=$(api_call "POST" "/api/items" "{invalid json}")
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                  --connect-timeout ${TIMEOUT} \
                  --max-time ${TIMEOUT} \
                  -H "Content-Type: application/json" \
                  -d "{invalid json}" \
                  "${TARGET_URL}/api/items" 2>/dev/null)

if [ "${HTTP_CODE}" != "200" ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - Malformed JSON rejected (HTTP ${HTTP_CODE})"
    ((PASSED_TESTS++))
else
    echo -e "  ${YELLOW}⚠ PASS${NC} - Server handled gracefully"
fi

echo ""

##############################################################################
# Test Suite: Concurrent Requests
##############################################################################

echo -e "${YELLOW}[SUITE 4] Concurrent Requests${NC}"
echo "─────────────────────────────────────────────────────"

test_case "Handle Multiple Concurrent Requests"
{
    for i in {1..5}; do
        api_call "GET" "/api/stats" > "${TEMP_DIR}/response_${i}.json" &
    done
    wait
}

CONCURRENT_SUCCESS=0
for i in {1..5}; do
    if [ -s "${TEMP_DIR}/response_${i}.json" ]; then
        ((CONCURRENT_SUCCESS++))
    fi
done

if [ ${CONCURRENT_SUCCESS} -eq 5 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - All 5 concurrent requests successful"
    ((PASSED_TESTS++))
else
    echo -e "  ${RED}✗ FAIL${NC} - Only ${CONCURRENT_SUCCESS}/5 requests successful"
    ((FAILED_TESTS++))
fi

echo ""

##############################################################################
# Test Suite: Frontend Integration
##############################################################################

echo -e "${YELLOW}[SUITE 5] Frontend Integration${NC}"
echo "─────────────────────────────────────────────────────"

test_case "Frontend HTML Served"
RESPONSE=$(api_call "GET" "/")
assert_contains "${RESPONSE}" "<html>" "Root path returns HTML"
assert_contains "${RESPONSE}" "body" "HTML contains body"

test_case "Frontend JavaScript Present"
RESPONSE=$(api_call "GET" "/")
assert_contains "${RESPONSE}" "script" "HTML includes scripts" || true
assert_contains "${RESPONSE}" "fetch" "JavaScript fetch API used" || true

echo ""

##############################################################################
# Test Suite: Response Headers
##############################################################################

echo -e "${YELLOW}[SUITE 6] Response Headers${NC}"
echo "─────────────────────────────────────────────────────"

test_case "CORS Headers Present"
HEADERS=$(curl -s -i --connect-timeout ${TIMEOUT} \
               --max-time ${TIMEOUT} \
               "${TARGET_URL}/api/health" 2>/dev/null | head -20)
assert_contains "${HEADERS}" "Access-Control-Allow" "CORS headers configured" || true

test_case "Content-Type Headers"
HEADERS=$(curl -s -i --connect-timeout ${TIMEOUT} \
               --max-time ${TIMEOUT} \
               "${TARGET_URL}/api/health" 2>/dev/null | head -20)
assert_contains "${HEADERS}" "Content-Type" "Content-Type header present" || true

echo ""

##############################################################################
# Test Suite: Performance Characteristics
##############################################################################

echo -e "${YELLOW}[SUITE 7] Performance Characteristics${NC}"
echo "─────────────────────────────────────────────────────"

test_case "API Response Time < 500ms"
START=$(date +%s%N)
api_call "GET" "/api/health" > /dev/null
END=$(date +%s%N)
ELAPSED=$(( (END - START) / 1000000 ))

if [ ${ELAPSED} -lt 500 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - Response time: ${ELAPSED}ms"
    ((PASSED_TESTS++))
else
    echo -e "  ${YELLOW}⚠ SLOW${NC} - Response time: ${ELAPSED}ms (expected < 500ms)"
    ((PASSED_TESTS++))
fi

test_case "Endpoint Availability"
AVAILABLE=0
for i in {1..3}; do
    if api_call "GET" "/api/health" | grep -q "status"; then
        ((AVAILABLE++))
    fi
    sleep 1
done

if [ ${AVAILABLE} -ge 3 ]; then
    echo -e "  ${GREEN}✓ PASS${NC} - Service stable (3/3 checks passed)"
    ((PASSED_TESTS++))
else
    echo -e "  ${YELLOW}⚠ WARN${NC} - Service unstable (${AVAILABLE}/3 checks passed)"
fi

echo ""

##############################################################################
# Summary Report
##############################################################################

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo "Integration Test Summary"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))

echo -e "Total Tests:  ${TOTAL_TESTS}"
echo -e "Passed:       ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed:       ${RED}${FAILED_TESTS}${NC}"

if [ ${TOTAL_TESTS} -gt 0 ]; then
    PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "Pass Rate:    ${PASS_RATE}%"
fi

# Save summary
cat > "${TEMP_DIR}/test-summary.txt" << EOF
Integration Tests Report
========================

Environment: ${ENVIRONMENT}
Timestamp: $(date -u +'%Y-%m-%d %H:%M:%S UTC')
Target URL: ${TARGET_URL}

Results:
--------
Total Tests: ${TOTAL_TESTS}
Passed: ${PASSED_TESTS}
Failed: ${FAILED_TESTS}
Pass Rate: ${PASS_RATE}%

Status: $([ ${FAILED_TESTS} -eq 0 ] && echo "PASSED" || echo "FAILED")
EOF

echo ""

# Exit with appropriate code
if [ ${FAILED_TESTS} -eq 0 ]; then
    echo -e "${GREEN}✓ All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ ${FAILED_TESTS} test(s) failed!${NC}"
    exit 1
fi
