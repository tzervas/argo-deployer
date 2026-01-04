# Application Management Guide

This guide explains how to manage applications in your ArgoCD deployment.

## Overview

Applications are defined in `config/applications.yml`. This file tells ArgoCD which Helm charts, Kubernetes manifests, or Kustomize applications to deploy and manage.

## Application Structure

Each application in the YAML file has the following structure:

```yaml
- name: my-app                    # Unique application name
  enabled: true                   # Enable/disable the application
  type: helm                      # Type: helm, git, or kustomize
  description: "My Application"   # Description (optional)
  namespace: my-namespace         # Target Kubernetes namespace
  create_namespace: true          # Create namespace if it doesn't exist
  repo_url: https://...           # Repository URL
  chart: my-chart                 # Chart name (for Helm)
  # OR
  path: my-path                   # Path in repo (for Git/Kustomize)
  target_revision: "1.0.0"        # Version/branch/tag
  sync_policy:
    automated:
      prune: true                 # Remove resources not in Git
      self_heal: true             # Auto-sync on changes
  values: |                       # Helm values (optional)
    key: value
```

## Application Types

### Helm Charts

Helm charts from public or private repositories:

```yaml
- name: nginx-ingress
  enabled: true
  type: helm
  namespace: ingress-nginx
  create_namespace: true
  repo_url: https://kubernetes.github.io/ingress-nginx
  chart: ingress-nginx
  target_revision: "4.8.3"
  sync_policy:
    automated:
      prune: true
      self_heal: true
  values: |
    controller:
      service:
        type: LoadBalancer
```

### Git Repositories (Raw Manifests)

Kubernetes YAML manifests from a Git repository:

```yaml
- name: my-app
  enabled: true
  type: git
  namespace: default
  create_namespace: false
  repo_url: https://github.com/myorg/myapp
  path: k8s/manifests
  target_revision: main
  sync_policy:
    automated:
      prune: true
      self_heal: true
```

### Kustomize Applications

Applications using Kustomize for customization:

```yaml
- name: my-kustomize-app
  enabled: true
  type: kustomize
  namespace: default
  repo_url: https://github.com/myorg/myapp
  path: k8s/overlays/production
  target_revision: main
  sync_policy:
    automated:
      prune: false
      self_heal: false
```

## Sync Policies

Sync policies control how ArgoCD manages your applications:

### Automated Sync

ArgoCD automatically syncs changes from Git:

```yaml
sync_policy:
  automated:
    prune: true      # Delete resources not in Git
    self_heal: true  # Revert manual changes
```

### Manual Sync

Require manual approval for syncs:

```yaml
sync_policy:
  automated: {}  # Empty or omit this section
```

## Managing Applications

### Adding a New Application

1. Edit `config/applications.yml`
2. Add your application configuration
3. Run the update script:

```bash
./scripts/update-apps.sh
```

### Disabling an Application

Set `enabled: false`:

```yaml
- name: my-app
  enabled: false
  # ... rest of config
```

Then run `./scripts/update-apps.sh`.

### Updating an Application

1. Modify the application configuration in `config/applications.yml`
2. Run `./scripts/update-apps.sh`

ArgoCD will automatically sync the changes.

## Private Repositories

### Git Repositories

For private Git repositories, add credentials in `config/applications.yml`:

```yaml
repositories:
  - url: https://github.com/myorg/private-repo
    username: myuser
    password: "{{ lookup('env', 'GITHUB_TOKEN') }}"
    type: git
```

Set the environment variable before deployment:

```bash
export GITHUB_TOKEN="your-token-here"
```

### Private Helm Repositories

```yaml
repositories:
  - url: https://charts.private.com
    username: myuser
    password: "{{ lookup('env', 'HELM_REPO_PASSWORD') }}"
    type: helm
```

## Projects

ArgoCD projects provide logical grouping and RBAC:

```yaml
projects:
  - name: production
    description: "Production applications"
    source_repos:
      - https://github.com/myorg/*
    destinations:
      - namespace: 'prod-*'
        server: https://kubernetes.default.svc
    cluster_resource_whitelist:
      - group: 'apps'
        kind: 'Deployment'
```

## Best Practices

### 1. Use Version Pinning

Always specify exact versions for Helm charts:

```yaml
target_revision: "1.2.3"  # Good
target_revision: "latest" # Avoid
```

### 2. Enable Self-Heal for Stable Apps

For production applications, enable self-healing:

```yaml
sync_policy:
  automated:
    self_heal: true
```

### 3. Disable Prune for Critical Apps

For critical applications, review before deletion:

```yaml
sync_policy:
  automated:
    prune: false
```

### 4. Use Namespaces

Organize applications by namespace:

```yaml
namespace: production-apps
create_namespace: true
```

### 5. Document Your Applications

Add descriptions:

```yaml
description: "Production NGINX Ingress Controller - handles all external traffic"
```

## Common Patterns

### Multi-Environment Setup

Use different applications for different environments:

```yaml
- name: myapp-dev
  namespace: dev
  repo_url: https://github.com/myorg/myapp
  target_revision: develop

- name: myapp-prod
  namespace: production
  repo_url: https://github.com/myorg/myapp
  target_revision: main
```

### Dependency Management

For applications with dependencies, manage sync order manually or use sync waves (advanced).

### Helm Value Overrides

Override default Helm values:

```yaml
values: |
  replicaCount: 3
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
```

## Troubleshooting

### Application Won't Sync

1. Check ArgoCD UI for sync errors
2. Verify repository access
3. Check namespace permissions
4. Review application logs in ArgoCD

### Application Shows as Degraded

1. Check pod status in Kubernetes
2. Review application logs
3. Verify resource requests/limits
4. Check health check configuration

### Manual Intervention Needed

To manually sync an application:

```bash
# SSH to ArgoCD VM
ssh ubuntu@192.168.1.180

# Sync application
argocd app sync my-app --insecure
```

## Advanced Features

### Sync Waves

Control sync order with annotations:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

### Resource Hooks

Use hooks for pre/post-sync operations:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
```

### Selective Sync

Sync only specific resources:

```bash
argocd app sync my-app --resource apps:Deployment:my-deployment
```

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Charts](https://helm.sh/)
- [Kustomize](https://kustomize.io/)
- [GitOps Principles](https://www.gitops.tech/)
