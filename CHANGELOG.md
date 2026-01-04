# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-01-04

### Added
- **Dynamic IP detection** - Automatic VM IP discovery and tracking
  - VM IP automatically detected after deployment using `virsh domifaddr`
  - IP saved to `.vm_ip` file for easy reference
  - New `scripts/get-vm-ip.sh` helper script for quick IP lookup
  - Deployment output now shows complete access information with actual IP
- **Improved deployment resilience**
  - Cloud-init ISO regenerated on each deployment (removed caching)
  - VM persistence with `--wait=0` flag (no longer auto-undefined)
  - Multiple fallback sources for IP detection (agent, lease, default)

### Changed
- **Network configuration switched to DHCP** (from static IP)
  - More reliable across different network configurations
  - Eliminates interface naming issues (enp1s0 vs ens3 vs eth0)
  - No manual DHCP reservation required
- **Updated ArgoCD WebUI port** from 8080 to 30080 (valid Kubernetes NodePort range)
- **Flexible SSH key injection** - Uses all `.pub` keys from `~/.ssh/` directory
- **Network bridge configuration** - Updated from virbr0 to br0 for homelab compatibility
- Updated `status.sh` script to use dynamic IP detection
- All documentation updated to reflect DHCP and dynamic IP approach

### Fixed
- VM deployment stability - VM no longer disappears after creation
- SSH key authentication - Works with ed25519, rsa, and other key types
- NodePort configuration - Now uses valid Kubernetes port range (30000-32767)
- Cloud-init ISO regeneration - Ensures fresh configuration on each deployment
- Network bridge compatibility - Automatically uses available bridge
- Download timeout handling - Cloud image downloads won't hang indefinitely

### Documentation
- Updated `README.md` with dynamic IP access instructions
- Updated `QUICKSTART.md` with `get-vm-ip.sh` usage
- Added comprehensive troubleshooting section in `docs/TROUBLESHOOTING.md`
  - Network bridge configuration issues
  - NodePort range errors
  - DHCP vs static IP setup
  - VM IP discovery methods

### Testing
- ✅ Full deployment tested and verified on Debian-based homelab
- ✅ ArgoCD v2.9.5 installation confirmed working
- ✅ Helm chart deployment tested (nginx-ingress v4.8.3)
- ✅ Git manifest deployment tested (argocd-example-apps)
- ✅ Auto-sync and self-healing policies verified
- ✅ Dynamic IP detection validated across redeployments

## [0.1.0] - 2026-01-04

### Added
- Initial release of ArgoCD Deployer
- Complete Ansible automation for ArgoCD VM deployment
- K3s lightweight Kubernetes installation
- ArgoCD v2.9.5 automated setup
- Cloud-init based VM provisioning
- Application bootstrap from configuration files
- Support for Helm charts and Git-based manifests
- Comprehensive documentation and quick start guide
- Deployment, status, and application management scripts
- Example application configurations

### Features
- Automated VM creation and configuration on libvirt/KVM hosts
- Ubuntu 22.04 cloud image based deployment
- Configurable VM resources (CPU, memory, disk)
- ArgoCD admin password management with bcrypt hashing
- Automated application deployment from `config/applications.yml`
- RBAC policy configuration support
- Network policy management

[0.3.0]: https://github.com/tzervas/argo-deployer/compare/v0.1.0...v0.3.0
[0.1.0]: https://github.com/tzervas/argo-deployer/releases/tag/v0.1.0
