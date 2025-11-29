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

get_docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        print_error "Docker Compose is not available"
        exit 1
    fi
}

check_env_file() {
    local env_required=$1
    if [ "$env_required" = "true" ] && [ ! -f .env ]; then
        print_warning ".env file not found"
        print_info "For production use, copy .env.example to .env and configure it:"
        print_info "  cp .env.example .env"
        print_info "  # Edit .env and set RCON_PASSWORD"
        echo ""
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

start_server() {
    local compose_cmd=$(get_docker_compose_cmd)
    check_env_file "false"
    print_info "Starting Minecraft server..."
    $compose_cmd up -d
    print_success "Server started! Use './manage.sh logs' to view logs"
}

stop_server() {
    local compose_cmd=$(get_docker_compose_cmd)
    print_info "Stopping Minecraft server..."
    $compose_cmd down
    print_success "Server stopped"
}

restart_server() {
    local compose_cmd=$(get_docker_compose_cmd)
    print_info "Restarting Minecraft server..."
    $compose_cmd restart
    print_success "Server restarted"
}

view_logs() {
    local compose_cmd=$(get_docker_compose_cmd)
    print_info "Viewing server logs (Ctrl+C to exit)..."
    $compose_cmd logs -f minecraft
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
    
    BACKUP_DIR="backups"
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$BACKUP_NAME" data/ 2>/dev/null || {
        print_error "Backup failed"
        exit 1
    }
    
    print_success "Backup created: $BACKUP_NAME"
}

restore_server() {
    local compose_cmd=$(get_docker_compose_cmd)
    print_info "Available backups:"
    echo ""
    
    if [ ! -d "backups" ] || [ -z "$(ls -A backups/*.tar.gz 2>/dev/null)" ]; then
        print_error "No backups found in backups/ directory"
        exit 1
    fi
    
    ls -lh backups/*.tar.gz | awk '{print $9, "(" $5 ")"}'
    echo ""
    
    read -p "Enter the backup filename to restore (or 'cancel'): " backup_file
    
    if [ "$backup_file" = "cancel" ]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will replace the current server data!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    # Stop the server
    print_info "Stopping server..."
    $compose_cmd down
    
    # Backup current data before restore
    if [ -d "data" ]; then
        print_info "Backing up current data..."
        mv data "data.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Restore the backup
    print_info "Restoring backup..."
    tar -xzf "$backup_file" || {
        print_error "Restore failed"
        exit 1
    }
    
    print_success "Backup restored successfully"
    print_info "Starting server..."
    $compose_cmd up -d
    print_success "Server started with restored data"
}

console_access() {
    print_info "Connecting to server console..."
    print_info "Type 'quit' to exit RCON console"
    docker exec -i "$CONTAINER_NAME" rcon-cli
}

update_server() {
    local compose_cmd=$(get_docker_compose_cmd)
    print_info "Updating server..."
    $compose_cmd down
    $compose_cmd pull
    $compose_cmd up -d
    print_success "Server updated and restarted"
}

build_image() {
    local compose_cmd=$(get_docker_compose_cmd)
    print_info "Building Docker image..."
    $compose_cmd build
    print_success "Image built successfully"
}

generate_configs() {
    print_info "Generating configurations..."
    
    if [ ! -f "./generate-configs.sh" ]; then
        print_error "generate-configs.sh not found!"
        exit 1
    fi
    
    # Determine environment
    local env="dev"
    read -p "Generate for which environment? (dev/prod) [dev]: " env_input
    if [ -n "$env_input" ]; then
        env="$env_input"
    fi
    
    # Run the generator
    ./generate-configs.sh "$env"
}

show_usage() {
    cat << EOF
Minecraft Server Management Script

Usage: ./manage.sh [command]

Commands:
    start           Start the server
    stop            Stop the server
    restart         Restart the server
    status          Show server status
    logs            View server logs (real-time)
    console         Access server console (RCON)
    backup          Create a backup of the server data
    restore         Restore from a backup
    update          Update and restart the server
    build           Build the Docker image
    generate-configs Generate configuration files from templates
    help            Show this help message

Examples:
    ./manage.sh start
    ./manage.sh logs
    ./manage.sh backup
    ./manage.sh restore
    ./manage.sh generate-configs

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
    restore)
        restore_server
        ;;
    update)
        update_server
        ;;
    build)
        build_image
        ;;
    generate-configs)
        generate_configs
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
