#!/bin/bash

# Troubleshooting Script for Harbor Push Issues
# This script helps diagnose and fix common Docker push problems

set +e  # Don't exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Get Harbor URLs from environment or use defaults
HARBOR_DEV_URL="${HARBOR_DEV_URL:-harbor.dev.thebozic.com}"
HARBOR_PROD_URL="${HARBOR_PROD_URL:-harbor.prod.thebozic.com}"

print_header "Docker Harbor Push Troubleshooting"

# Check 1: Docker is running
print_info "Checking if Docker is running..."
if docker info > /dev/null 2>&1; then
    print_success "Docker is running"
else
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check 2: Harbor login status
print_header "Checking Harbor Authentication"

check_harbor_login() {
    local harbor_url=$1
    local env_name=$2
    
    print_info "Checking login to $harbor_url ($env_name)..."
    
    if grep -q "$harbor_url" ~/.docker/config.json 2>/dev/null; then
        print_success "Logged in to $harbor_url"
        
        # Try to test the connection
        print_info "Testing authentication..."
        if docker login "$harbor_url" --username dummy --password dummy > /dev/null 2>&1; then
            print_warning "Authentication test suggests credentials might be invalid"
        fi
    else
        print_error "NOT logged in to $harbor_url"
        echo "  Run: docker login $harbor_url"
    fi
}

check_harbor_login "$HARBOR_DEV_URL" "Development"
check_harbor_login "$HARBOR_PROD_URL" "Production"

# Check 3: Network connectivity
print_header "Checking Network Connectivity"

check_connectivity() {
    local harbor_url=$1
    local env_name=$2
    
    print_info "Checking connectivity to $harbor_url ($env_name)..."
    
    if ping -c 1 "$harbor_url" > /dev/null 2>&1; then
        print_success "Can reach $harbor_url"
    else
        print_warning "Cannot ping $harbor_url (this may be normal if ICMP is blocked)"
    fi
    
    # Test HTTPS connectivity
    if curl -s -o /dev/null -w "%{http_code}" "https://$harbor_url" | grep -q "200\|401\|404"; then
        print_success "HTTPS connectivity to $harbor_url works"
    else
        print_error "Cannot connect to https://$harbor_url"
    fi
}

check_connectivity "$HARBOR_DEV_URL" "Development"
check_connectivity "$HARBOR_PROD_URL" "Production"

# Check 4: Docker daemon configuration
print_header "Checking Docker Configuration"

print_info "Checking Docker insecure registries..."
if docker info 2>/dev/null | grep -q "Insecure Registries:"; then
    docker info 2>/dev/null | grep -A 5 "Insecure Registries:"
else
    print_info "No insecure registries configured"
fi

# Check 5: Image size and layers
print_header "Checking Local Images"

print_info "Checking for built images..."
echo ""
docker images | grep -E "harbor\.(dev|prod)\.thebozic\.com|minecraft-server" || print_warning "No Harbor images found locally"

# Check 6: Disk space
print_header "Checking Disk Space"

print_info "Docker disk usage:"
docker system df

# Check 7: Docker daemon logs (recent errors)
print_header "Checking Recent Docker Daemon Logs"

print_info "Recent Docker errors (if any):"
if [ -f /var/log/docker.log ]; then
    tail -20 /var/log/docker.log | grep -i error || print_success "No recent errors in Docker logs"
elif command -v journalctl > /dev/null; then
    journalctl -u docker -n 20 --no-pager | grep -i error || print_success "No recent errors in Docker logs"
else
    print_warning "Cannot access Docker logs"
fi

# Recommendations
print_header "Recommendations"

echo ""
echo "If you're experiencing push failures, try these solutions:"
echo ""
echo "1. ${YELLOW}Increase Docker timeout:${NC}"
echo "   Edit /etc/docker/daemon.json or ~/.docker/config.json and add:"
echo '   {"max-concurrent-uploads": 1, "max-concurrent-downloads": 1}'
echo ""
echo "2. ${YELLOW}Re-login to Harbor:${NC}"
echo "   docker logout $HARBOR_DEV_URL"
echo "   docker login $HARBOR_DEV_URL"
echo ""
echo "3. ${YELLOW}Try pushing with --disable-content-trust:${NC}"
echo "   DOCKER_CONTENT_TRUST=0 docker push <image>"
echo ""
echo "4. ${YELLOW}Reduce image size by using multi-stage builds${NC}"
echo ""
echo "5. ${YELLOW}Check Harbor project permissions:${NC}"
echo "   - Ensure the 'mc-server' project exists in Harbor"
echo "   - Verify you have push permissions"
echo "   - Check Harbor UI for any quota limits"
echo ""
echo "6. ${YELLOW}Try pushing in chunks with compression:${NC}"
echo "   export DOCKER_BUILDKIT=1"
echo "   docker push <image>"
echo ""
echo "7. ${YELLOW}For large images, increase client timeout:${NC}"
echo "   Add to ~/.docker/config.json:"
echo '   {"HttpHeaders": {"User-Agent": "Docker-Client/19.03.12 (linux)"}, "psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Command}}\\t{{.CreatedAt}}"}'
echo ""

print_header "Testing Push to Harbor (Dev)"

read -p "Would you like to test pushing a small test image? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Creating and pushing a test image..."
    
    # Create a minimal test image
    echo "FROM alpine:latest" > /tmp/Dockerfile.test
    echo "RUN echo 'test' > /test.txt" >> /tmp/Dockerfile.test
    
    TEST_IMAGE="$HARBOR_DEV_URL/mc-server/test:latest"
    
    if docker build -f /tmp/Dockerfile.test -t "$TEST_IMAGE" /tmp/; then
        print_success "Test image built"
        
        if docker push "$TEST_IMAGE"; then
            print_success "Test push successful! Your Harbor connection is working."
            docker rmi "$TEST_IMAGE" 2>/dev/null
        else
            print_error "Test push failed. Check the error above."
        fi
    fi
    
    rm /tmp/Dockerfile.test
fi

echo ""
print_info "Troubleshooting complete!"
