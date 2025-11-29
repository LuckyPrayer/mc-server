#!/bin/bash

# Configuration Template Processor
# Processes template files and replaces variables with environment-specific values
#
# NOTE: This script is primarily for LOCAL TESTING and PREVIEW purposes.
# In production, configurations are generated automatically at container runtime
# by scripts/entrypoint.sh. The plugin configs generated here are for preview only
# as the actual plugin configs are created inside the container at /data/plugins/.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
${BLUE}Configuration Template Processor${NC}

Usage: ./generate-configs.sh [ENVIRONMENT] [OPTIONS]

ENVIRONMENT:
    dev         Generate development configurations
    prod        Generate production configurations

OPTIONS:
    --plugin PLUGIN     Only generate configs for specific plugin
                       (BlueMap, DiscordSRV, Geyser, Floodgate)
    --server-only      Only generate server configs
    --plugins-only     Only generate plugin configs
    --force           Overwrite existing configs without prompting
    --dry-run         Show what would be generated without creating files
    --help, -h        Show this help message

EXAMPLES:
    # Generate all development configs
    ./generate-configs.sh dev

    # Generate production configs with confirmation
    ./generate-configs.sh prod

    # Generate only BlueMap config for production
    ./generate-configs.sh prod --plugin BlueMap

    # Dry run to see what would be generated
    ./generate-configs.sh dev --dry-run

    # Force overwrite all production configs
    ./generate-configs.sh prod --force

EOF
}

# Parse arguments
ENVIRONMENT=""
PLUGIN_FILTER=""
SERVER_ONLY=false
PLUGINS_ONLY=false
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        --plugin)
            PLUGIN_FILTER="$2"
            shift 2
            ;;
        --server-only)
            SERVER_ONLY=true
            shift
            ;;
        --plugins-only)
            PLUGINS_ONLY=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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

# Validate environment
if [ -z "$ENVIRONMENT" ]; then
    print_error "Environment not specified. Use 'dev' or 'prod'"
    show_usage
    exit 1
fi

if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    print_error "Invalid environment: $ENVIRONMENT. Use 'dev' or 'prod'"
    exit 1
fi

# Check for templates directory
if [ ! -d "templates" ]; then
    print_error "Templates directory not found!"
    print_info "Run this script from the project root directory"
    exit 1
fi

# Load environment variables
print_info "Loading environment variables for: $ENVIRONMENT"

# Load base .env if it exists
if [ -f ".env" ]; then
    print_info "Loading .env file"
    export $(grep -v '^#' .env | xargs)
fi

# Load environment-specific .env file
ENV_FILE=".env.$ENVIRONMENT"
if [ -f "$ENV_FILE" ]; then
    print_info "Loading $ENV_FILE file"
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    print_warning "$ENV_FILE not found, using defaults"
fi

# Set ENVIRONMENT variable for templates
export ENVIRONMENT="$ENVIRONMENT"

# Function to process a single template file
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would generate: $output_file"
        return 0
    fi
    
    # Check if output exists and we're not forcing
    if [ -f "$output_file" ] && [ "$FORCE" = false ]; then
        read -p "$(echo -e ${YELLOW})File $output_file exists. Overwrite? (y/n): $(echo -e ${NC})" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipped: $output_file"
            return 0
        fi
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"
    
    # Process template using envsubst
    if command -v envsubst &> /dev/null; then
        envsubst < "$template_file" > "$output_file"
    else
        # Fallback: manual variable substitution using sed
        print_warning "envsubst not found, using sed (less reliable)"
        sed -e "s/\${ENVIRONMENT}/$ENVIRONMENT/g" \
            -e "s/\${SERVER_NAME}/${SERVER_NAME:-Minecraft Server}/g" \
            -e "s/\${MAX_PLAYERS}/${MAX_PLAYERS:-20}/g" \
            "$template_file" > "$output_file"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Generated: $output_file"
    else
        print_error "Failed to generate: $output_file"
        return 1
    fi
}

# Function to process all templates in a directory
process_directory() {
    local template_dir="$1"
    local output_dir="$2"
    local name="$3"
    
    if [ ! -d "$template_dir" ]; then
        print_warning "Template directory not found: $template_dir"
        return 0
    fi
    
    print_info "Processing $name templates..."
    
    local count=0
    while IFS= read -r -d '' template_file; do
        # Get relative path and remove .template extension
        local rel_path="${template_file#$template_dir/}"
        local output_file="$output_dir/${rel_path%.template}"
        
        process_template "$template_file" "$output_file"
        ((count++))
    done < <(find "$template_dir" -name "*.template" -type f -print0)
    
    if [ $count -eq 0 ]; then
        print_warning "No templates found in $template_dir"
    else
        print_success "Processed $count $name template(s)"
    fi
}

# Main processing
echo ""
print_info "========================================="
print_info "Configuration Generator"
print_info "Environment: $ENVIRONMENT"
print_info "========================================="
echo ""

# Determine output directory based on environment
if [ "$ENVIRONMENT" = "dev" ]; then
    CONFIG_OUTPUT_DIR="config"
    DATA_DIR="data-dev"
else
    CONFIG_OUTPUT_DIR="config"
    DATA_DIR="data-prod"
fi

# Process server configurations
if [ "$PLUGINS_ONLY" = false ]; then
    print_info "Generating server configurations..."
    process_directory "templates/server" "$CONFIG_OUTPUT_DIR" "server"
    echo ""
fi

# Process plugin configurations
if [ "$SERVER_ONLY" = false ]; then
    if [ -z "$PLUGIN_FILTER" ]; then
        # Process all plugins
        print_info "Generating plugin configurations..."
        for plugin_dir in templates/plugins/*; do
            if [ -d "$plugin_dir" ]; then
                plugin_name=$(basename "$plugin_dir")
                process_directory "$plugin_dir" "plugin-configs/$plugin_name" "$plugin_name"
            fi
        done
    else
        # Process specific plugin
        plugin_dir="templates/plugins/$PLUGIN_FILTER"
        if [ ! -d "$plugin_dir" ]; then
            print_error "Plugin template not found: $PLUGIN_FILTER"
            print_info "Available plugins:"
            ls -1 templates/plugins/
            exit 1
        fi
        process_directory "$plugin_dir" "plugin-configs/$PLUGIN_FILTER" "$PLUGIN_FILTER"
    fi
    echo ""
fi

# Summary
echo ""
print_info "========================================="
if [ "$DRY_RUN" = true ]; then
    print_success "Dry run complete!"
    print_info "No files were actually created"
else
    print_success "Configuration generation complete!"
    print_info "Generated configurations for: $ENVIRONMENT"
    if [ "$ENVIRONMENT" = "prod" ]; then
        print_warning "Don't forget to review sensitive values (passwords, tokens, etc.)"
    fi
fi
print_info "========================================="
echo ""

# Show next steps
if [ "$DRY_RUN" = false ]; then
    print_info "Next steps:"
    echo "  1. Review generated configurations in:"
    if [ "$SERVER_ONLY" = false ]; then
        echo "     - plugin-configs/ (LOCAL PREVIEW ONLY)"
    fi
    if [ "$PLUGINS_ONLY" = false ]; then
        echo "     - $CONFIG_OUTPUT_DIR/ (for local testing)"
    fi
    print_warning "Note: In containers, configs are generated at runtime to /data/"
    echo "  2. Set any missing environment variables in .env.$ENVIRONMENT"
    echo "  3. Test with: ./manage.sh start"
    echo ""
fi
