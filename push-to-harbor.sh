#!/bin/bash

# Harbor Push Script for hephaestus-dev and hephaestus-prod
# This script builds and pushes Minecraft server images to Harbor registries

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
HARBOR_DEV="harbor.dev.thebozic.com"
HARBOR_PROD="harbor.prod.thebozic.com"
HARBOR_PROJECT="mc-server"
IMAGE_NAME="minecraft-server"
VERSION="${VERSION:-$(date +%Y%m%d-%H%M%S)}"
GIT_COMMIT="${GIT_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')}"

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

show_usage() {
    cat << EOF
${BLUE}Harbor Push Script${NC}

Usage: ./push-to-harbor.sh [OPTIONS]

Options:
    --env <env>        Environment: dev or prod (required)
    --version <ver>    Version tag (default: timestamp)
    --latest           Also tag as 'latest'
    --all              Build and push to both dev and prod
    --help             Show this help message

Examples:
    # Push dev image to hephaestus-dev
    ./push-to-harbor.sh --env dev

    # Push prod image with version tag
    ./push-to-harbor.sh --env prod --version 1.0.0 --latest

    # Push to both registries
    ./push-to-harbor.sh --all --version 1.0.0

EOF
    exit 0
}

login_to_registry() {
    local registry=$1
    print_info "Logging in to $registry..."
    
    if docker login "$registry" 2>/dev/null; then
        print_success "Logged in to $registry"
    else
        print_error "Failed to login to $registry. Please check credentials."
    fi
}

build_image() {
    local env=$1
    local dockerfile="Dockerfile.${env}"
    
    print_info "Building ${env} image..."
    
    if [ ! -f "$dockerfile" ]; then
        print_error "Dockerfile not found: $dockerfile"
    fi
    
    docker build \
        --file "$dockerfile" \
        --tag "${IMAGE_NAME}:${env}-latest" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="$VERSION" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        .
    
    print_success "Built ${IMAGE_NAME}:${env}-latest"
}

tag_and_push() {
    local env=$1
    local registry=$2
    local tag_latest=${3:-false}
    
    local base_tag="${registry}/${HARBOR_PROJECT}/${IMAGE_NAME}"
    
    print_info "Tagging images for $registry..."
    
    # Tag with version
    docker tag "${IMAGE_NAME}:${env}-latest" "${base_tag}:${env}-${VERSION}"
    docker tag "${IMAGE_NAME}:${env}-latest" "${base_tag}:${env}-${GIT_COMMIT}"
    
    # Tag as latest if requested
    if [ "$tag_latest" = true ]; then
        docker tag "${IMAGE_NAME}:${env}-latest" "${base_tag}:${env}-latest"
    fi
    
    print_success "Tagged images"
    
    print_info "Pushing to $registry..."
    
    # Push version tag
    docker push "${base_tag}:${env}-${VERSION}"
    print_success "Pushed ${base_tag}:${env}-${VERSION}"
    
    # Push git commit tag
    docker push "${base_tag}:${env}-${GIT_COMMIT}"
    print_success "Pushed ${base_tag}:${env}-${GIT_COMMIT}"
    
    # Push latest if tagged
    if [ "$tag_latest" = true ]; then
        docker push "${base_tag}:${env}-latest"
        print_success "Pushed ${base_tag}:${env}-latest"
    fi
}

process_environment() {
    local env=$1
    local registry=$2
    local tag_latest=$3
    
    echo ""
    print_info "======================================"
    print_info "Processing ${env} environment"
    print_info "Registry: $registry"
    print_info "Version: $VERSION"
    print_info "Git Commit: $GIT_COMMIT"
    print_info "======================================"
    echo ""
    
    # Login
    login_to_registry "$registry"
    
    # Build
    build_image "$env"
    
    # Tag and push
    tag_and_push "$env" "$registry" "$tag_latest"
    
    echo ""
    print_success "✓ Completed ${env} environment push to $registry"
    echo ""
}

# Parse arguments
ENVIRONMENT=""
TAG_LATEST=false
PUSH_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --latest)
            TAG_LATEST=true
            shift
            ;;
        --all)
            PUSH_ALL=true
            shift
            ;;
        --help)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            ;;
    esac
done

# Validate
if [ "$PUSH_ALL" = false ] && [ -z "$ENVIRONMENT" ]; then
    print_error "Please specify --env <dev|prod> or use --all"
fi

if [ -n "$ENVIRONMENT" ] && [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    print_error "Environment must be 'dev' or 'prod'"
fi

# Main execution
echo ""
print_info "========================================"
print_info "Harbor Push Script"
print_info "========================================"
echo ""

if [ "$PUSH_ALL" = true ]; then
    # Push to both registries
    process_environment "dev" "$HARBOR_DEV" "$TAG_LATEST"
    process_environment "prod" "$HARBOR_PROD" "$TAG_LATEST"
    
    echo ""
    print_success "=========================================="
    print_success "✓ All images pushed successfully!"
    print_success "=========================================="
    echo ""
    print_info "Development images:"
    print_info "  - ${HARBOR_DEV}/${HARBOR_PROJECT}/${IMAGE_NAME}:dev-${VERSION}"
    print_info "  - ${HARBOR_DEV}/${HARBOR_PROJECT}/${IMAGE_NAME}:dev-${GIT_COMMIT}"
    [ "$TAG_LATEST" = true ] && print_info "  - ${HARBOR_DEV}/${HARBOR_PROJECT}/${IMAGE_NAME}:dev-latest"
    echo ""
    print_info "Production images:"
    print_info "  - ${HARBOR_PROD}/${HARBOR_PROJECT}/${IMAGE_NAME}:prod-${VERSION}"
    print_info "  - ${HARBOR_PROD}/${HARBOR_PROJECT}/${IMAGE_NAME}:prod-${GIT_COMMIT}"
    [ "$TAG_LATEST" = true ] && print_info "  - ${HARBOR_PROD}/${HARBOR_PROJECT}/${IMAGE_NAME}:prod-latest"
    
elif [ "$ENVIRONMENT" = "dev" ]; then
    process_environment "dev" "$HARBOR_DEV" "$TAG_LATEST"
    
    echo ""
    print_success "=========================================="
    print_success "✓ Development image pushed successfully!"
    print_success "=========================================="
    echo ""
    print_info "Images available at:"
    print_info "  - ${HARBOR_DEV}/${HARBOR_PROJECT}/${IMAGE_NAME}:dev-${VERSION}"
    print_info "  - ${HARBOR_DEV}/${HARBOR_PROJECT}/${IMAGE_NAME}:dev-${GIT_COMMIT}"
    [ "$TAG_LATEST" = true ] && print_info "  - ${HARBOR_DEV}/${HARBOR_PROJECT}/${IMAGE_NAME}:dev-latest"
    
elif [ "$ENVIRONMENT" = "prod" ]; then
    process_environment "prod" "$HARBOR_PROD" "$TAG_LATEST"
    
    echo ""
    print_success "=========================================="
    print_success "✓ Production image pushed successfully!"
    print_success "=========================================="
    echo ""
    print_info "Images available at:"
    print_info "  - ${HARBOR_PROD}/${HARBOR_PROJECT}/${IMAGE_NAME}:prod-${VERSION}"
    print_info "  - ${HARBOR_PROD}/${HARBOR_PROJECT}/${IMAGE_NAME}:prod-${GIT_COMMIT}"
    [ "$TAG_LATEST" = true ] && print_info "  - ${HARBOR_PROD}/${HARBOR_PROJECT}/${IMAGE_NAME}:prod-latest"
fi

echo ""
print_info "To pull these images:"
if [ "$PUSH_ALL" = true ] || [ "$ENVIRONMENT" = "dev" ]; then
    echo ""
    print_info "Development:"
    echo "  docker pull ${HARBOR_DEV}/${HARBOR_PROJECT}/${IMAGE_NAME}:dev-${VERSION}"
fi
if [ "$PUSH_ALL" = true ] || [ "$ENVIRONMENT" = "prod" ]; then
    echo ""
    print_info "Production:"
    echo "  docker pull ${HARBOR_PROD}/${HARBOR_PROJECT}/${IMAGE_NAME}:prod-${VERSION}"
fi
echo ""
