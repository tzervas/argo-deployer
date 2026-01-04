#!/bin/bash
# Check ArgoCD Status
# This script checks the status of the ArgoCD VM and services

set -e  # Exit on error

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

# Get configuration values
TARGET_HOST=$(grep -A5 "homelab:" "${INVENTORY_FILE}" | grep "ansible_host:" | awk '{print $2}')
VM_NAME=$(grep -A10 "homelab:" "${INVENTORY_FILE}" | grep "vm_name:" | awk '{print $2}')
ARGOCD_IP=$(grep -A10 "homelab:" "${INVENTORY_FILE}" | grep "argocd_ip:" | awk '{print $2}')
ARGOCD_PORT=$(grep -A10 "homelab:" "${INVENTORY_FILE}" | grep "argocd_webui_port:" | awk '{print $2}')

# Main execution
main() {
    print_header "ArgoCD Status Check"
    echo ""
    
    # Check host connectivity
    print_info "Checking connection to homelab host..."
    if ssh -o ConnectTimeout=5 "${TARGET_HOST}" "echo 'Connected'" &> /dev/null; then
        print_success "Host ${TARGET_HOST} is reachable"
    else
        print_error "Cannot connect to ${TARGET_HOST}"
        exit 1
    fi
    echo ""
    
    # Check VM status
    print_info "Checking VM status..."
    VM_STATE=$(ssh "${TARGET_HOST}" "virsh domstate ${VM_NAME}" 2>/dev/null || echo "not found")
    
    if [ "${VM_STATE}" == "running" ]; then
        print_success "VM ${VM_NAME} is running"
    elif [ "${VM_STATE}" == "not found" ]; then
        print_error "VM ${VM_NAME} not found"
        exit 1
    else
        print_error "VM ${VM_NAME} is ${VM_STATE}"
        exit 1
    fi
    echo ""
    
    # Check ArgoCD connectivity
    print_info "Checking ArgoCD service..."
    if curl -s -o /dev/null -w "%{http_code}" "http://${ARGOCD_IP}:${ARGOCD_PORT}" | grep -q "200\|302\|301"; then
        print_success "ArgoCD WebUI is accessible at http://${ARGOCD_IP}:${ARGOCD_PORT}"
    else
        print_error "Cannot reach ArgoCD WebUI"
        print_info "The VM might still be starting up. Wait a few minutes and try again."
    fi
    echo ""
    
    # Show resource usage
    print_info "VM Resource Usage:"
    ssh "${TARGET_HOST}" "virsh dominfo ${VM_NAME}" 2>/dev/null | grep -E "CPU\(s\)|Max memory|Used memory" || true
    echo ""
    
    # Show applications if ArgoCD is accessible
    print_info "Attempting to list ArgoCD applications..."
    if ssh -o ConnectTimeout=5 ubuntu@"${ARGOCD_IP}" "argocd app list 2>/dev/null" &> /dev/null; then
        ssh ubuntu@"${ARGOCD_IP}" "argocd app list" || print_info "Unable to list applications"
    else
        print_info "ArgoCD CLI not accessible from host (this is normal)"
    fi
    
    echo ""
    print_success "Status check complete!"
}

# Run main function
main "$@"
