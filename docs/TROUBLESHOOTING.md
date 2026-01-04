# Troubleshooting Guide

Common issues and solutions for the ArgoCD Deployer.

## Deployment Issues

### Cannot Connect to Host

**Symptom:** SSH connection fails to homelab (192.168.1.170)

**Solutions:**

1. Verify host is online:
   ```bash
   ping 192.168.1.170
   ```

2. Check SSH configuration:
   ```bash
   ssh homelab echo "test"
   ```

3. Verify SSH key authentication:
   ```bash
   ssh-add -l
   cat ~/.ssh/id_rsa.pub
   ```

4. Test direct SSH:
   ```bash
   ssh -v user@192.168.1.170
   ```

### VM Deployment Fails

**Symptom:** VM creation fails or times out

**Solutions:**

1. Check available resources:
   ```bash
   ssh homelab "free -h"
   ssh homelab "df -h"
   ```

2. Verify libvirt is running:
   ```bash
   ssh homelab "systemctl status libvirtd"
   ```

3. Check for existing VM:
   ```bash
   ssh homelab "virsh list --all"
   ```

4. Clean up existing VM:
   ```bash
   ssh homelab "virsh destroy argocd-server; virsh undefine argocd-server --remove-all-storage"
   ```

### Cloud-Init Fails

**Symptom:** VM starts but cloud-init doesn't complete

**Solutions:**

1. Check cloud-init status:
   ```bash
   ssh ubuntu@192.168.1.180 "cloud-init status"
   ```

2. View cloud-init logs:
   ```bash
   ssh ubuntu@192.168.1.180 "cat /var/log/cloud-init.log"
   ssh ubuntu@192.168.1.180 "cat /var/log/cloud-init-output.log"
   ```

3. Wait for completion (can take 10-15 minutes on first boot):
   ```bash
   ssh ubuntu@192.168.1.180 "cloud-init status --wait"
   ```

## ArgoCD Issues

### Cannot Access WebUI

**Symptom:** Cannot reach http://192.168.1.180:8080

**Solutions:**

1. Check VM is running:
   ```bash
   ./scripts/status.sh
   ```

2. Verify port is listening:
   ```bash
   ssh ubuntu@192.168.1.180 "sudo netstat -tulpn | grep 8080"
   ```

3. Check ArgoCD server status:
   ```bash
   ssh ubuntu@192.168.1.180 "kubectl get pods -n argocd"
   ```

4. View ArgoCD server logs:
   ```bash
   ssh ubuntu@192.168.1.180 "kubectl logs -n argocd deployment/argocd-server"
   ```

5. Check firewall rules:
   ```bash
   ssh ubuntu@192.168.1.180 "sudo iptables -L -n"
   ```

### Login Failed

**Symptom:** Cannot login with admin/changemedummy123

**Solutions:**

1. Get the current admin password:
   ```bash
   ssh ubuntu@192.168.1.180 "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
   ```

2. Reset admin password:
   ```bash
   ssh ubuntu@192.168.1.180
   # On the VM:
   kubectl -n argocd delete secret argocd-secret
   kubectl -n argocd rollout restart deployment argocd-server
   ```

3. Wait for server to restart:
   ```bash
   ssh ubuntu@192.168.1.180 "kubectl -n argocd rollout status deployment argocd-server"
   ```

### Applications Not Syncing

**Symptom:** Applications stuck in "OutOfSync" or "Unknown" status

**Solutions:**

1. Check application status:
   ```bash
   ssh ubuntu@192.168.1.180 "argocd app get <app-name> --insecure"
   ```

2. View sync errors:
   ```bash
   ssh ubuntu@192.168.1.180 "argocd app sync <app-name> --insecure"
   ```

3. Check repository access:
   ```bash
   ssh ubuntu@192.168.1.180 "argocd repo list --insecure"
   ```

4. Manually sync:
   ```bash
   ssh ubuntu@192.168.1.180 "argocd app sync <app-name> --force --insecure"
   ```

## Network Issues

### VM Cannot Reach Internet

**Symptom:** VM cannot download packages or reach external services

**Solutions:**

1. Check VM networking:
   ```bash
   ssh ubuntu@192.168.1.180 "ip addr show"
   ssh ubuntu@192.168.1.180 "ip route show"
   ```

2. Test DNS:
   ```bash
   ssh ubuntu@192.168.1.180 "nslookup google.com"
   ```

3. Check gateway:
   ```bash
   ssh ubuntu@192.168.1.180 "ping 192.168.1.1"
   ```

4. Verify libvirt network:
   ```bash
   ssh homelab "virsh net-list --all"
   ssh homelab "virsh net-info default"
   ```

### Cannot Access from Other LAN Devices

**Symptom:** Can access from deployment machine but not from other devices on LAN

**Solutions:**

1. Verify IP is accessible:
   ```bash
   # From another device
   ping 192.168.1.180
   curl http://192.168.1.180:8080
   ```

2. Check host firewall:
   ```bash
   ssh homelab "sudo iptables -L -n -v"
   ```

3. Verify bridge configuration:
   ```bash
   ssh homelab "brctl show"
   ssh homelab "ip addr show virbr0"
   ```

## Performance Issues

### VM Running Slow

**Symptom:** ArgoCD UI is slow or unresponsive

**Solutions:**

1. Check resource usage:
   ```bash
   ssh ubuntu@192.168.1.180 "top -b -n 1 | head -20"
   ssh ubuntu@192.168.1.180 "free -h"
   ssh ubuntu@192.168.1.180 "df -h"
   ```

2. Increase VM resources in `inventory/hosts.yml`:
   ```yaml
   vm_memory: 8192  # Increase to 8GB
   vm_cpus: 4       # Increase to 4 CPUs
   ```

3. Restart VM:
   ```bash
   ssh homelab "virsh shutdown argocd-server"
   # Wait a few seconds
   ssh homelab "virsh start argocd-server"
   ```

### Application Sync is Slow

**Symptom:** Applications take a long time to sync

**Solutions:**

1. Check cluster resources:
   ```bash
   ssh ubuntu@192.168.1.180 "kubectl top nodes"
   ssh ubuntu@192.168.1.180 "kubectl top pods -A"
   ```

2. Review application size:
   - Large Helm charts take longer
   - Many resources = longer sync time

3. Increase ArgoCD resources:
   ```bash
   ssh ubuntu@192.168.1.180
   kubectl -n argocd edit deployment argocd-server
   # Increase resources in spec.template.spec.containers[0].resources
   ```

## Recovery Procedures

### Complete Redeployment

If all else fails, redeploy from scratch:

```bash
# Remove existing VM
ssh homelab "virsh destroy argocd-server; virsh undefine argocd-server --remove-all-storage"

# Run deployment again
./scripts/deploy.sh
```

### Backup and Restore

Before major changes, create a backup:

```bash
ansible-playbook -i inventory/hosts.yml ansible/playbook.yml --tags backup
```

Restore from backup:

```bash
ansible-playbook -i inventory/hosts.yml ansible/playbook.yml --tags restore
```

### Reset ArgoCD Only

Keep the VM but reset ArgoCD:

```bash
ssh ubuntu@192.168.1.180
kubectl delete namespace argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Then run the configure task:

```bash
ansible-playbook -i inventory/hosts.yml ansible/playbook.yml --tags configure
```

## Getting Help

### Collect Diagnostic Information

```bash
# Check deployment status
./scripts/status.sh

# View recent logs
tail -50 logs/deploy-*.log

# Get ArgoCD logs
ssh ubuntu@192.168.1.180 "kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=100"

# Get VM console output
ssh homelab "virsh console argocd-server"  # Press Ctrl+] to exit
```

### Useful Commands

```bash
# Restart ArgoCD components
ssh ubuntu@192.168.1.180 "kubectl -n argocd rollout restart deployment"

# Check certificate validity (if using HTTPS)
ssh ubuntu@192.168.1.180 "kubectl -n argocd get secret argocd-server-tls -o yaml"

# View ArgoCD configuration
ssh ubuntu@192.168.1.180 "kubectl -n argocd get configmap argocd-cm -o yaml"

# Check application health
ssh ubuntu@192.168.1.180 "argocd app list --insecure"
ssh ubuntu@192.168.1.180 "argocd app get <app-name> --insecure"
```

## Common Error Messages

### "network bridge not found" or "virbr0 does not exist"

**Symptom:** VM deployment fails with network bridge error

**Cause:** The default libvirt bridge (virbr0) doesn't exist on the host, and a custom bridge (like br0) is used instead

**Fix:**
1. Check available bridges:
   ```bash
   ssh homelab "ip link show type bridge"
   ```

2. Update `inventory/hosts.yml` to use the correct bridge:
   ```yaml
   vm_network_bridge: br0  # or whatever bridge name you found
   ```

### "provided port is not in the valid range" (NodePort error)

**Symptom:** Cloud-init log shows NodePort error with port 8080

**Cause:** Kubernetes NodePort range is 30000-32767, not lower ports

**Fix:** The deployment now uses port 30080 (already fixed in cloud-init template)

Access ArgoCD at: `http://<VM_IP>:30080`

### VM gets DHCP instead of static IP

**Symptom:** VM doesn't get the configured static IP (192.168.1.180)

**Cause:** Network interface naming varies (enp1s0, ens3, etc.) and static config may not apply

**Current Solution:** The deployment uses DHCP for reliability. The VM will get an IP from your router's DHCP pool.

**To find VM IP:**
```bash
# Method 1: Check virsh
ssh homelab "sudo virsh domifaddr argocd-server"

# Method 2: Check deployment logs
tail logs/deploy*.log | grep "VM IP"

# Method 3: Scan network for VM MAC (52:54:00:xx:xx:xx)
nmap -sn 192.168.1.0/24
```

**Recommendation:** Set a DHCP reservation on your router for the VM's MAC address to maintain a consistent IP.

### "connection refused"

- ArgoCD server not running
- Wrong IP or port
- Firewall blocking connection

**Fix:** Check service status and firewall rules

### "authentication required"

- Wrong username/password
- Session expired
- ArgoCD not fully initialized

**Fix:** Verify credentials and wait for full startup

### "repository not found"

- Repository URL incorrect
- Private repo without credentials
- Network connectivity issue

**Fix:** Verify repository URL and add credentials if private

### "namespace does not exist"

- Target namespace not created
- create_namespace: false in application config

**Fix:** Set `create_namespace: true` or create namespace manually

## Prevention Tips

1. **Regular Backups:** Run backups before major changes
2. **Monitor Resources:** Keep an eye on disk space and memory
3. **Update Regularly:** Keep ArgoCD and applications updated
4. **Test Changes:** Test configuration changes in a dev environment first
5. **Document Custom Changes:** Keep notes of any manual modifications

## Support Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub Issues](https://github.com/argoproj/argo-cd/issues)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [libvirt Documentation](https://libvirt.org/docs.html)

For project-specific issues, open an issue on the GitHub repository.
