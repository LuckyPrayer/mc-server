#!/bin/bash

# Minecraft Server Management Script
# Helper script for common server operations

set -e

COMPOSE_FILE="docker-compose.yml"
CONTAINER_NAME="minecraft-server"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
}

start_server() {
    print_info "Starting Minecraft server..."
    docker-compose up -d
    print_success "Server started! Use './manage.sh logs' to view logs"
}

stop_server() {
    print_info "Stopping Minecraft server..."
    docker-compose down
    print_success "Server stopped"
}

restart_server() {
    print_info "Restarting Minecraft server..."
    docker-compose restart
    print_success "Server restarted"
}

view_logs() {
    print_info "Viewing server logs (Ctrl+C to exit)..."
    docker-compose logs -f minecraft
}

server_status() {
    if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
        print_success "Server is running"
        docker ps --filter "name=$CONTAINER_NAME"
    else
        print_error "Server is not running"
    fi
}

backup_server() {
    print_info "Creating backup..."
    
    # Save the world first
    docker exec -i "$CONTAINER_NAME" rcon-cli save-all 2>/dev/null || true
    sleep 2
    
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$BACKUP_NAME" data/ 2>/dev/null || {
        print_error "Backup failed"
        exit 1
    }
    
    print_success "Backup created: $BACKUP_NAME"
}

console_access() {
    print_info "Connecting to server console..."
    print_info "Type 'quit' to exit RCON console"
    docker exec -i "$CONTAINER_NAME" rcon-cli
}

update_server() {
    print_info "Updating server..."
    docker-compose down
    docker-compose pull
    docker-compose up -d
    print_success "Server updated and restarted"
}

build_image() {
    print_info "Building Docker image..."
    docker-compose build
    print_success "Image built successfully"
}

show_usage() {
    cat << EOF
Minecraft Server Management Script

Usage: ./manage.sh [command]

Commands:
    start       Start the server
    stop        Stop the server
    restart     Restart the server
    status      Show server status
    logs        View server logs (real-time)
    console     Access server console (RCON)
    backup      Create a backup of the server data
    update      Update and restart the server
    build       Build the Docker image
    help        Show this help message

Examples:
    ./manage.sh start
    ./manage.sh logs
    ./manage.sh backup

EOF
}

# Main script
check_docker

case "${1:-}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        server_status
        ;;
    logs)
        view_logs
        ;;
    console)
        console_access
        ;;
    backup)
        backup_server
        ;;
    update)
        update_server
        ;;
    build)
        build_image
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: ${1:-}"
        echo ""
        show_usage
        exit 1
        ;;
esac
