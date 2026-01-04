#!/bin/bash
# Get ArgoCD VM IP Address
# Retrieves the IP from saved file or queries the homelab server

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IP_FILE="${PROJECT_ROOT}/.vm_ip"
INVENTORY_FILE="${PROJECT_ROOT}/inventory/hosts.yml"

# Extract homelab host from inventory
HOMELAB_HOST=$(grep -A5 "homelab:" "$INVENTORY_FILE" | grep "ansible_host:" | awk '{print $2}')

echo -e "${BLUE}ArgoCD VM IP Lookup${NC}"
echo ""

# Try to get IP from saved file first
if [ -f "$IP_FILE" ]; then
    SAVED_IP=$(cat "$IP_FILE")
    echo -e "${GREEN}IP from last deployment: ${SAVED_IP}${NC}"
    
    # Verify it's still reachable
    if ping -c 1 -W 1 "$SAVED_IP" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ VM is reachable at ${SAVED_IP}${NC}"
        echo ""
        echo "ArgoCD WebUI: http://${SAVED_IP}:30080"
        echo "SSH Access: ssh ubuntu@${SAVED_IP}"
        exit 0
    else
        echo "⚠ Saved IP is not reachable, querying server..."
        echo ""
    fi
fi

# Query the homelab server
echo "Querying homelab server at ${HOMELAB_HOST}..."
CURRENT_IP=$(ssh "$HOMELAB_HOST" "sudo virsh domifaddr argocd-server --source agent 2>/dev/null || sudo virsh domifaddr argocd-server --source lease 2>/dev/null || sudo virsh domifaddr argocd-server 2>/dev/null" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

if [ -n "$CURRENT_IP" ]; then
    echo -e "${GREEN}✓ Current VM IP: ${CURRENT_IP}${NC}"
    
    # Save to file
    echo "$CURRENT_IP" > "$IP_FILE"
    echo "Saved to $IP_FILE"
    echo ""
    echo "ArgoCD WebUI: http://${CURRENT_IP}:30080"
    echo "SSH Access: ssh ubuntu@${CURRENT_IP}"
else
    echo "✗ Could not detect VM IP address"
    echo ""
    echo "VM might be starting up or not running."
    echo "Check status with: ssh $HOMELAB_HOST \"sudo virsh list --all\""
    exit 1
fi
