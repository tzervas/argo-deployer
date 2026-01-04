#!/bin/bash
# ArgoCD Deployer - Main Deployment Script
# This script orchestrates the complete deployment of ArgoCD on your homelab server

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
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_requirements() {
    print_header "Checking Requirements"
    
    local missing_requirements=0
    
    # Check for Ansible
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed"
        missing_requirements=1
    else
        print_success "Ansible found: $(ansible --version | head -n1)"
    fi
    
    # Check for Python3
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed"
        missing_requirements=1
    else
        print_success "Python3 found: $(python3 --version)"
    fi
    
    # Check for SSH
    if ! command -v ssh &> /dev/null; then
        print_error "SSH is not installed"
        missing_requirements=1
    else
        print_success "SSH found"
    fi
    
    # Check Python bcrypt module
    if ! python3 -c "import bcrypt" &> /dev/null; then
        print_warning "Python bcrypt module not found. Installing..."
        pip3 install bcrypt --user || {
            print_error "Failed to install bcrypt"
            missing_requirements=1
        }
    else
        print_success "Python bcrypt module found"
    fi
    
    if [ $missing_requirements -eq 1 ]; then
        print_error "Missing requirements. Please install them and try again."
        exit 1
    fi
    
    echo ""
}

check_connectivity() {
    print_header "Checking Host Connectivity"
    
    local target_host=$(grep -A5 "homelab:" "${INVENTORY_FILE}" | grep "ansible_host:" | awk '{print $2}')
    
    print_info "Testing SSH connection to ${target_host}..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "${target_host}" "echo 'Connection successful'" &> /dev/null; then
        print_success "SSH connection to ${target_host} successful"
    else
        print_error "Cannot connect to ${target_host} via SSH"
        print_info "Please ensure:"
        print_info "  1. The host is online and reachable"
        print_info "  2. SSH key authentication is configured"
        print_info "  3. Your SSH config has the 'homelab' profile set up"
        exit 1
    fi
    
    echo ""
}

create_log_dir() {
    mkdir -p "${LOG_DIR}"
}

run_deployment() {
    print_header "Starting ArgoCD Deployment"
    
    print_info "Deployment will proceed with the following steps:"
    print_info "  1. Prepare host system (install packages, download images)"
    print_info "  2. Deploy ArgoCD VM"
    print_info "  3. Configure ArgoCD"
    print_info "  4. Bootstrap applications"
    echo ""
    
    print_info "This process may take 15-30 minutes..."
    print_info "Logs will be saved to: ${LOG_FILE}"
    echo ""
    
    # Run the Ansible playbook
    if ansible-playbook \
        -i "${INVENTORY_FILE}" \
        "${PLAYBOOK_FILE}" \
        -v 2>&1 | tee "${LOG_FILE}"; then
        
        echo ""
        print_success "Deployment completed successfully!"
        echo ""
        show_access_info
        
    else
        echo ""
        print_error "Deployment failed. Check the logs at ${LOG_FILE}"
        exit 1
    fi
}

show_access_info() {
    print_header "ArgoCD Access Information"
    
    local argocd_ip=$(grep -A10 "homelab:" "${INVENTORY_FILE}" | grep "argocd_ip:" | awk '{print $2}')
    local argocd_port=$(grep -A10 "homelab:" "${INVENTORY_FILE}" | grep "argocd_webui_port:" | awk '{print $2}')
    local admin_password=$(grep -A5 "admin:" "${PROJECT_ROOT}/config/argocd-config.yml" | grep "password:" | awk '{print $2}' | tr -d '"')
    
    echo ""
    echo -e "${GREEN}ArgoCD WebUI:${NC} http://${argocd_ip}:${argocd_port}"
    echo -e "${GREEN}Username:${NC}     admin"
    echo -e "${GREEN}Password:${NC}     ${admin_password}"
    echo ""
    print_warning "IMPORTANT: Change the default password after first login!"
    echo ""
    
    print_info "To manage applications, edit: ${PROJECT_ROOT}/config/applications.yml"
    print_info "Then run: ${SCRIPT_DIR}/update-apps.sh"
    echo ""
}

# Main execution
main() {
    clear
    print_header "ArgoCD Deployer"
    echo ""
    
    create_log_dir
    check_requirements
    check_connectivity
    
    # Confirm deployment
    read -p "$(echo -e ${YELLOW}Ready to deploy ArgoCD to homelab. Continue? [y/N]: ${NC})" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_deployment
    else
        print_info "Deployment cancelled."
        exit 0
    fi
}

# Run main function
main "$@"
