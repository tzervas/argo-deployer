# Requirements

## Control Machine (where you run the deployment from)

- Ansible 2.10+
- Python 3.8+
- Python bcrypt module (`pip3 install bcrypt`)
- SSH client
- Git

## Target Host (homelab server)

- Ubuntu 20.04+ or similar Linux distribution
- libvirt/KVM virtualization support
- Minimum 8GB RAM (4GB for VM + 4GB for host)
- Minimum 50GB free disk space
- CPU with virtualization extensions (Intel VT-x or AMD-V)
- Network connectivity

## Network

- SSH access to target host (passwordless authentication recommended)
- Static IP or DHCP reservation for ArgoCD VM
- Open ports:
  - 22 (SSH) on target host
  - 8080 (ArgoCD WebUI) on ArgoCD VM
  - 6443 (Kubernetes API) on ArgoCD VM (internal)

## Install Dependencies

### On Control Machine (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y ansible python3-pip git
pip3 install bcrypt
```

### On Control Machine (macOS)

```bash
brew install ansible python3 git
pip3 install bcrypt
```

### On Target Host

The Ansible playbook will automatically install required packages:
- qemu-kvm
- libvirt-daemon-system
- libvirt-clients
- bridge-utils
- virtinst
- python3-libvirt
- cloud-utils
- genisoimage
