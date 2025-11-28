#!/bin/bash

# Docker Image Build and Push Script
# Helps build and publish the Minecraft server container

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
IMAGE_NAME="minecraft-server"
VERSION="latest"
REGISTRY=""
USERNAME=""
MULTIPLATFORM=false
PUSH=false
ENVIRONMENT="dev"
HARBOR_DEV_URL="harbor.dev.thebozic.com"
HARBOR_PROD_URL="harbor.prod.thebozic.com"
HARBOR_PROJECT="mc-server"

# Functions
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

show_usage() {
    cat << EOF
${BLUE}Docker Build and Push Script${NC}

Usage: ./build.sh [OPTIONS]

Options:
    --env <environment>     Environment: dev or prod (default: dev)
    --push <registry>       Push to registry (dockerhub, ghcr, harbor)
    --username <username>   Docker Hub username or GitHub username
    --project <project>     Harbor project name (default: minecraft)
    --version <version>     Image version tag (default: latest)
    --multiplatform        Build for multiple platforms (amd64, arm64)
    --help                 Show this help message

Examples:
    # Build development image locally
    ./build.sh --env dev

    # Build production image locally
    ./build.sh --env prod

    # Build and push to Harbor dev registry
    ./build.sh --env dev --push harbor

    # Build and push to Harbor prod registry
    ./build.sh --env prod --push harbor --version 1.0.0

    # Build multi-platform production image and push
    ./build.sh --env prod --push harbor --multiplatform --version 1.0.0

    # Build and push to Docker Hub (still supported)
    ./build.sh --push dockerhub --username myusername

    # Build and push to GitHub Container Registry (still supported)
    ./build.sh --push ghcr --username myusername

EOF
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
}

check_login() {
    local registry=$1
    local harbor_url=$2
    
    if [ "$registry" = "dockerhub" ]; then
        if ! docker info 2>&1 | grep -q "Username:"; then
            print_warning "Not logged in to Docker Hub"
            print_info "Please run: docker login"
            exit 1
        fi
    elif [ "$registry" = "ghcr" ]; then
        if ! grep -q "ghcr.io" ~/.docker/config.json 2>/dev/null; then
            print_warning "Not logged in to GitHub Container Registry"
            print_info "Please run: echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin"
            exit 1
        fi
    elif [ "$registry" = "harbor" ]; then
        if ! grep -q "$harbor_url" ~/.docker/config.json 2>/dev/null; then
            print_warning "Not logged in to Harbor registry at $harbor_url"
            print_info "Please run: docker login $harbor_url"
            exit 1
        fi
    fi
}

setup_buildx() {
    print_info "Setting up Docker Buildx for multi-platform builds..."
    
    if ! docker buildx inspect multiplatform &>/dev/null; then
        docker buildx create --name multiplatform --use
        print_success "Created buildx builder 'multiplatform'"
    else
        docker buildx use multiplatform
        print_success "Using existing buildx builder 'multiplatform'"
    fi
    
    docker buildx inspect --bootstrap
}

build_local() {
    local tag=$1
    local dockerfile=$2
    
    print_info "Building Docker image: $tag"
    print_info "Using Dockerfile: $dockerfile"
    docker build -f "$dockerfile" -t "$tag" .
    print_success "Image built successfully: $tag"
}

build_multiplatform() {
    local tag=$1
    local dockerfile=$2
    
    print_info "Building multi-platform image: $tag"
    print_info "Using Dockerfile: $dockerfile"
    print_info "Platforms: linux/amd64, linux/arm64"
    
    if [ "$PUSH" = true ]; then
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -f "$dockerfile" \
            -t "$tag" \
            --push \
            .
        print_success "Multi-platform image built and pushed: $tag"
    else
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -f "$dockerfile" \
            -t "$tag" \
            --load \
            .
        print_success "Multi-platform image built: $tag"
    fi
}

push_image() {
    local tag=$1
    
    print_info "Pushing image: $tag"
    docker push "$tag"
    print_success "Image pushed successfully: $tag"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            REGISTRY="$2"
            shift 2
            ;;
        --username)
            USERNAME="$2"
            shift 2
            ;;
        --project)
            HARBOR_PROJECT="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --multiplatform)
            MULTIPLATFORM=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main script
check_docker

# Validate environment
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    print_error "Invalid environment. Use 'dev' or 'prod'"
    exit 1
fi

# Set Dockerfile based on environment
if [ "$ENVIRONMENT" = "dev" ]; then
    DOCKERFILE="Dockerfile.dev"
    HARBOR_URL="$HARBOR_DEV_URL"
elif [ "$ENVIRONMENT" = "prod" ]; then
    DOCKERFILE="Dockerfile.prod"
    HARBOR_URL="$HARBOR_PROD_URL"
fi

# Validate registry if pushing
if [ "$PUSH" = true ]; then
    if [ -z "$REGISTRY" ]; then
        print_error "Registry not specified. Use --push <harbor|dockerhub|ghcr>"
        exit 1
    fi
    
    if [ "$REGISTRY" = "harbor" ]; then
        check_login "$REGISTRY" "$HARBOR_URL"
    elif [ "$REGISTRY" = "dockerhub" ] || [ "$REGISTRY" = "ghcr" ]; then
        if [ -z "$USERNAME" ]; then
            print_error "Username not specified. Use --username <your-username>"
            exit 1
        fi
        check_login "$REGISTRY"
    else
        print_error "Invalid registry. Use 'harbor', 'dockerhub', or 'ghcr'"
        exit 1
    fi
fi

# Build image tag
if [ "$REGISTRY" = "harbor" ]; then
    IMAGE_TAG="${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${ENVIRONMENT}-${VERSION}"
elif [ "$REGISTRY" = "ghcr" ]; then
    IMAGE_TAG="ghcr.io/${USERNAME}/${IMAGE_NAME}:${ENVIRONMENT}-${VERSION}"
elif [ "$REGISTRY" = "dockerhub" ]; then
    IMAGE_TAG="${USERNAME}/${IMAGE_NAME}:${ENVIRONMENT}-${VERSION}"
else
    IMAGE_TAG="${IMAGE_NAME}:${ENVIRONMENT}-${VERSION}"
fi

print_info "Configuration:"
echo "  Environment: $ENVIRONMENT"
echo "  Dockerfile: $DOCKERFILE"
echo "  Image: $IMAGE_TAG"
echo "  Multi-platform: $MULTIPLATFORM"
echo "  Push: $PUSH"
if [ "$REGISTRY" = "harbor" ]; then
    echo "  Harbor URL: $HARBOR_URL"
    echo "  Harbor Project: $HARBOR_PROJECT"
fi
echo ""

# Build
if [ "$MULTIPLATFORM" = true ]; then
    setup_buildx
    build_multiplatform "$IMAGE_TAG" "$DOCKERFILE"
else
    build_local "$IMAGE_TAG" "$DOCKERFILE"
    
    # Push if requested
    if [ "$PUSH" = true ]; then
        push_image "$IMAGE_TAG"
    fi
fi

# Show next steps
echo ""
print_success "Build complete!"
echo ""

if [ "$PUSH" = true ]; then
    print_info "Your image is now available at: $IMAGE_TAG"
    echo ""
    if [ "$ENVIRONMENT" = "dev" ]; then
        echo "To use it in development:"
        echo "  Update docker-compose.dev.yml:"
        echo "    services:"
        echo "      minecraft-dev:"
        echo "        image: $IMAGE_TAG"
        echo ""
        echo "Or run with docker-compose:"
        echo "  docker-compose -f docker-compose.dev.yml up -d"
    else
        echo "To use it in production:"
        echo "  Update docker-compose.prod.yml:"
        echo "    services:"
        echo "      minecraft-prod:"
        echo "        image: $IMAGE_TAG"
        echo ""
        echo "Or run with docker-compose:"
        echo "  docker-compose -f docker-compose.prod.yml up -d"
    fi
else
    print_info "Image built locally: $IMAGE_TAG"
    echo ""
    echo "To test it:"
    echo "  docker run -p 25565:25565 -e EULA=TRUE $IMAGE_TAG"
    echo ""
    echo "To use with docker-compose:"
    if [ "$ENVIRONMENT" = "dev" ]; then
        echo "  docker-compose -f docker-compose.dev.yml up -d"
    else
        echo "  docker-compose -f docker-compose.prod.yml up -d"
    fi
    echo ""
    echo "To push to Harbor:"
    echo "  ./build.sh --env $ENVIRONMENT --push harbor --version <version>"
fi
