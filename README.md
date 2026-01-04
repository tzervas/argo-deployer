# ArgoCD Deployer

Automated ArgoCD VM deployment solution for bootstrapping a Kubernetes/Helm management infrastructure on homelab servers.

## Overview

This project provides a preconfigured, automated solution to deploy an ArgoCD VM (qcow2 format) on your homelab server. It handles the complete setup including:

- ArgoCD VM deployment and configuration
- Network setup for LAN-accessible WebUI
- Pre-configured admin credentials
- Automated application deployment from manifest lists
- Support for Helm charts and Kubernetes manifests

## Features

- **Automated VM Deployment**: Uses Ansible to deploy ArgoCD as a qcow2 VM on your target host
- **Pre-configured Access**: ArgoCD WebUI accessible from your LAN with default credentials
- **Application Bootstrap**: Load and deploy applications from a manifest list
- **Passwordless SSH**: Leverages existing SSH key authentication
- **Idempotent**: Safe to re-run for updates or recovery

## Requirements

- Target server with libvirt/KVM support
- SSH access configured with passwordless authentication
- Ansible installed on control machine
- Python 3.x
- Sufficient storage and resources on target host

## Quick Start

### 1. Configure Your Environment

Edit `inventory/hosts.yml` to set your target host details (already configured for homelab at 192.168.1.170).

### 2. Customize Application List (Optional)

Edit `config/applications.yml` to define the Helm charts and Kubernetes manifests you want ArgoCD to manage.

### 3. Deploy ArgoCD

Run the deployment script:

```bash
./scripts/deploy.sh
```

This will:
- Download the ArgoCD VM image (if not cached)
- Deploy the VM to your homelab server
- Configure networking and access
- Set up the initial admin password
- Bootstrap your applications from the manifest list

### 4. Access ArgoCD

The deployment automatically detects and saves the VM's DHCP-assigned IP address. After deployment completes, the IP will be displayed in the output and saved to `.vm_ip` file.

**To get the VM IP:**

```bash
# Quick lookup (uses saved IP and verifies connectivity)
./scripts/get-vm-ip.sh

# Or check the saved file
cat .vm_ip
```

Access the ArgoCD WebUI at:
```
http://<VM_IP>:30080
```

**Why DHCP?** Dynamic IP detection is more resilient than static IP configuration, which can fail due to:
- Different network interface naming (enp1s0 vs ens3 vs eth0)
- Network configuration variations across systems
- Bridge setup differences

The deployment automatically queries the VM's actual IP and saves it for easy access.

**Default Credentials:**
- Username: `admin`
- Password: `changemedummy123`

⚠️ **Important**: Change the default password after first login!

## Project Structure

```
argo-deployer/
├── ansible/                    # Ansible playbooks and roles
│   ├── playbook.yml           # Main deployment playbook
│   ├── roles/                 # Ansible roles
│   └── templates/             # Configuration templates
├── config/                    # Configuration files
│   ├── applications.yml       # List of apps to deploy
│   └── argocd-config.yml      # ArgoCD configuration
├── inventory/                 # Ansible inventory
│   └── hosts.yml              # Target hosts definition
├── scripts/                   # Automation scripts
│   ├── deploy.sh              # Main deployment script
│   └── update-apps.sh         # Update application list
└── docs/                      # Additional documentation
    ├── APPLICATIONS.md        # Application management guide
    └── TROUBLESHOOTING.md     # Common issues and solutions
```

## Configuration

### Target Host

The target host is configured in `inventory/hosts.yml`. Default configuration:
- Host: homelab
- IP: 192.168.1.170
- SSH: Uses existing SSH profile with key-based auth

### ArgoCD Settings

ArgoCD configuration is in `config/argocd-config.yml`:
- Default admin password
- Repository credentials
- UI settings
- RBAC policies

### Applications

Define your applications in `config/applications.yml`. Supports:
- Helm charts (from repositories)
- Raw Kubernetes manifests
- Kustomize applications
- Git repositories

Example format:
```yaml
applications:
  - name: my-app
    type: helm
    repo: https://charts.example.com
    chart: my-chart
    version: "1.0.0"
    namespace: default
```

## Advanced Usage

### Manual Deployment Steps

If you prefer to run steps individually:

```bash
# 1. Prepare the VM image
ansible-playbook ansible/playbook.yml --tags prepare

# 2. Deploy the VM
ansible-playbook ansible/playbook.yml --tags deploy

# 3. Configure ArgoCD
ansible-playbook ansible/playbook.yml --tags configure

# 4. Bootstrap applications
ansible-playbook ansible/playbook.yml --tags bootstrap
```

### Updating Applications

To update the application list without redeploying:

```bash
./scripts/update-apps.sh
```

### Backup and Recovery

```bash
# Backup ArgoCD configuration
ansible-playbook ansible/playbook.yml --tags backup

# Restore from backup
ansible-playbook ansible/playbook.yml --tags restore
```

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

### Quick Checks

```bash
# Check VM status
ssh homelab "virsh list --all"

# Check ArgoCD service
ssh homelab "systemctl status argocd"

# View ArgoCD logs
ssh homelab "journalctl -u argocd -f"
```

## Security Considerations

1. **Change Default Password**: The default password `changemedummy123` should be changed immediately after deployment
2. **SSH Keys**: Ensure SSH keys are properly secured
3. **Network Access**: Consider implementing firewall rules if ArgoCD should not be accessible from entire LAN
4. **TLS/SSL**: For production use, configure HTTPS access

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [ArgoCD](https://argo-cd.readthedocs.io/) - Declarative GitOps CD for Kubernetes
- [Ansible](https://www.ansible.com/) - Automation platform
- [libvirt](https://libvirt.org/) - Virtualization API

## Support

For issues and questions, please use the GitHub issue tracker.
