#!/bin/bash
# Update ArgoCD Applications
# This script updates the application list in ArgoCD without redeploying the VM

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
INVENTORY_FILE="${PROJECT_ROOT}/inventory/hosts.yml"
PLAYBOOK_FILE="${PROJECT_ROOT}/ansible/playbook.yml"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Main execution
main() {
    print_header "Update ArgoCD Applications"
    echo ""
    
    print_info "This will update applications based on config/applications.yml"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Continue? [y/N]: ${NC})" -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Update cancelled."
        exit 0
    fi
    
    print_info "Running application bootstrap..."
    echo ""
    
    if ansible-playbook \
        -i "${INVENTORY_FILE}" \
        "${PLAYBOOK_FILE}" \
        --tags bootstrap \
        -v; then
        
        echo ""
        print_success "Applications updated successfully!"
        
    else
        echo ""
        print_error "Application update failed."
        exit 1
    fi
}

# Run main function
main "$@"
