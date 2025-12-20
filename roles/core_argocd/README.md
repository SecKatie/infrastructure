# core_argocd

Deploys ArgoCD for GitOps-based continuous delivery to your K3s cluster.

## Overview

This role installs ArgoCD via Helm and configures it with:
- TLS ingress at `argocd.corp.mulliken.net`
- Resource limits suitable for Raspberry Pi nodes
- Optional App of Apps pattern for managing all applications

## Requirements

- K3s cluster with Traefik ingress
- `cert-manager` installed (for TLS certificates)
- `common_k8s` role available

## Usage

```bash
# Deploy ArgoCD
ansible-playbook -i inventory playbooks/core.yml --tags argocd -K

# Or deploy all core components
ansible-playbook -i inventory playbooks/core.yml -K
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `argocd_namespace` | `argocd` | Kubernetes namespace |
| `argocd_helm_version` | `7.7.22` | Helm chart version |
| `argocd_ingress_enabled` | `true` | Create ingress for UI |
| `argocd_ingress_host` | `argocd.corp.mulliken.net` | Ingress hostname |
| `argocd_repo_url` | `""` | Git repository URL for apps |
| `argocd_repo_path` | `k8s-apps` | Path to manifests in repo |
| `argocd_app_of_apps_enabled` | `false` | Deploy App of Apps |

## Post-Installation

1. **Get the admin password:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

2. **Access the UI:**
   - URL: https://argocd.corp.mulliken.net
   - Username: `admin`

3. **Install the CLI (optional):**
   ```bash
   brew install argocd
   argocd login argocd.corp.mulliken.net --username admin
   ```

## Migration Path

Once ArgoCD is running, migrate apps from Ansible:

1. Create `k8s-apps/` directory in this repo
2. Convert an app's templates to plain YAML (see example below)
3. Create an ArgoCD Application pointing to it
4. Remove the app from Ansible playbooks

### Example: Migrating an App

**Before (Ansible template):**
```yaml
# roles/app_homepage/templates/deployment.yaml.j2
image: "{{ homepage_image }}"
```

**After (plain YAML for ArgoCD):**
```yaml
# k8s-apps/homepage/deployment.yaml
image: ghcr.io/gethomepage/homepage:v0.8.0
```

**ArgoCD Application:**
```yaml
# k8s-apps/homepage/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: homepage
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-user/ansible-playbooks
    path: k8s-apps/homepage
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: homepage
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## App of Apps Pattern

Once you have multiple apps in `k8s-apps/`, enable the App of Apps:

1. Set `argocd_repo_url` to your Git repo
2. Set `argocd_app_of_apps_enabled: true`
3. Re-run the playbook

This creates a parent Application that automatically discovers and deploys
all applications in `k8s-apps/`.
