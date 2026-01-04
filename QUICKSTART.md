# Quick Start Guide

Get ArgoCD running on your homelab in under 30 minutes!

## Prerequisites Check

Before starting, ensure you have:

- [ ] SSH access to homelab (192.168.1.170)
- [ ] Homelab server has KVM/libvirt support
- [ ] At least 8GB RAM available on homelab
- [ ] At least 50GB free disk space
- [ ] Ansible installed on your machine (`ansible --version`)
- [ ] Python3 with bcrypt module (`python3 -c "import bcrypt"`)

## Step 1: Test SSH Connection

```bash
ssh homelab echo "Connected!"
```

If this works, you're ready to proceed.

## Step 2: Review Configuration (Optional)

The default configuration is ready to use, but you can customize:

### Target Host Settings
Edit [inventory/hosts.yml](inventory/hosts.yml):
- VM resources (memory, CPUs)
- Network settings
- ArgoCD version

### Applications to Deploy
Edit [config/applications.yml](config/applications.yml):
- Enable/disable example applications
- Add your own Helm charts
- Configure sync policies

### ArgoCD Settings
Edit [config/argocd-config.yml](config/argocd-config.yml):
- Admin password (default: changemedummy123)
- RBAC policies
- Server settings

## Step 3: Run Deployment

```bash
./scripts/deploy.sh
```

This will:
1. ✓ Check requirements
2. ✓ Test homelab connectivity
3. ✓ Install packages on homelab
4. ✓ Download Ubuntu cloud image
5. ✓ Create and configure ArgoCD VM
6. ✓ Install K3s and ArgoCD
7. ✓ Set up admin password
8. ✓ Bootstrap applications

**Estimated time:** 15-30 minutes (mostly waiting for downloads and VM setup)

## Step 4: Access ArgoCD

Once deployment completes, the VM's IP address is automatically detected and saved.

1. **Get your VM's IP address:**
   ```bash
   # Use the helper script (recommended)
   ./scripts/get-vm-ip.sh
   
   # Or read the saved IP file
   cat .vm_ip
   ```

2. Open your browser to: **http://<VM_IP>:30080**
   
   Example: http://192.168.1.100:30080

3. Login with:
   - **Username:** admin
   - **Password:** changemedummy123

4. **IMPORTANT:** Change your password!
   - Click "User Info" in the top right
   - Click "Update Password"
   - Enter a new secure password

**Note:** Consider setting a DHCP reservation on your router for the VM's MAC address to keep a consistent IP.

## Step 5: Add Your Applications

### Method 1: Edit Config File

1. Edit `config/applications.yml`
2. Add your Helm charts or Git repositories
3. Run: `./scripts/update-apps.sh`

Example:
```yaml
- name: my-app
  enabled: true
  type: helm
  namespace: my-namespace
  create_namespace: true
  repo_url: https://charts.example.com
  chart: my-chart
  target_revision: "1.0.0"
  sync_policy:
    automated:
      prune: true
      self_heal: true
```

### Method 2: Use ArgoCD UI

1. Click "NEW APP" in the UI
2. Fill in application details
3. Click "CREATE"

## What's Next?

### Learn More

- [Full Documentation](README.md)
- [Application Management Guide](docs/APPLICATIONS.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

### Common Tasks

**Check Status:**
```bash
./scripts/status.sh
```

**Update Applications:**
```bash
./scripts/update-apps.sh
```

**View Logs:**
```bash
tail -f logs/deploy-*.log
```

**SSH to ArgoCD VM:**
```bash
ssh ubuntu@192.168.1.180
```

**View ArgoCD Apps:**
```bash
ssh ubuntu@192.168.1.180 "argocd app list --insecure"
```

### Backup Your Configuration

```bash
ansible-playbook -i inventory/hosts.yml ansible/playbook.yml --tags backup
```

Backups are saved to `/var/backups/argocd/` on your homelab server.

## Troubleshooting

### Deployment Fails

1. Check logs: `tail -100 logs/deploy-*.log`
2. Verify SSH: `ssh homelab "echo test"`
3. Check resources: `ssh homelab "free -h && df -h"`

### Can't Access WebUI

1. Check VM: `./scripts/status.sh`
2. Wait 5 minutes (cloud-init may still be running)
3. Check logs: `ssh ubuntu@192.168.1.180 "tail -100 /var/log/cloud-init-output.log"`

### Applications Won't Sync

1. Check repository access
2. Verify credentials for private repos
3. Check application logs in ArgoCD UI

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more help.

## Pro Tips

1. **Pin Versions:** Always specify exact versions for Helm charts
2. **Use Namespaces:** Organize apps by namespace
3. **Enable Auto-Sync:** For stable apps, use automated sync policies
4. **Test First:** Test configuration changes on non-critical apps
5. **Regular Backups:** Run backups before major changes

## Getting Help

- Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Review [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- Open an issue on GitHub

## Success! 🎉

Your ArgoCD deployment is ready! You now have:

✓ GitOps-based Kubernetes management  
✓ Automated application deployment  
✓ Visual application monitoring  
✓ Declarative infrastructure  

Start adding your applications and enjoy the power of GitOps!
