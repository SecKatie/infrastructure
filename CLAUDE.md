# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ansible-based infrastructure automation for a K3s cluster running on Raspberry Pi and RHEL nodes. Manages cluster provisioning, application deployments (via ArgoCD GitOps), secrets (SealedSecrets), and TLS (cert-manager).

## Common Commands

```bash
# Ansible playbooks (vault password auto-loaded from ~/.ansible-vault-pass.sh)
# Note: -K (become password) is NOT needed
ansible-playbook -i inventory playbooks/<playbook>.yml
ansible-playbook -i inventory playbooks/deploy.yml                    # Deploy everything
ansible-playbook -i inventory playbooks/deploy.yml --tags core        # Deploy by tag
ansible-playbook -i inventory playbooks/deploy.yml --skip-tags ipv6   # Skip specific tags

# Molecule testing (run from role directory)
cd roles/<role_name>
molecule test      # Full test cycle
molecule converge  # Apply without teardown (for iterating)
molecule verify    # Run verification only

# Secrets
kubeseal --format yaml < my-secrets.yaml > sealedsecrets.yaml

# OpenTofu (DNS management)
just tf-plan   # Preview changes
just tf-apply  # Apply changes

# Utilities
just dashboard-token  # Copy K8s dashboard token to clipboard
```

## Architecture

### Directory Layout

| Directory | Purpose |
|-----------|---------|
| `playbooks/` | Ansible playbooks for infrastructure provisioning |
| `roles/` | Ansible roles (prefixed: `infra_*`, `core_*`, `app_*`, `util_*`, `common_*`) |
| `k8s-apps/` | **ArgoCD-managed** K8s manifests (media/, monitoring/, utilities/) |
| `k8s-manifests/` | Bootstrap manifests (ArgoCD projects, ApplicationSets) |
| `opentofu/` | DNS infrastructure as code |
| `inventory/` | Ansible inventory and group variables |
| `playbooks/vars/` | Encrypted ansible-vault secrets |

### Key Playbooks

| Playbook | Tags | Purpose |
|----------|------|---------|
| `deploy.yml` | all | Master orchestration |
| `infrastructure.yml` | `infrastructure`, `rpi`, `nfs` | Pi setup, NFS, static IP |
| `core.yml` | `core`, `storage`, `networking`, `gitops` | Longhorn, cert-manager, Traefik, ArgoCD |
| `k3s.yml` | `k3s`, `k3s_agents` | K3s cluster agent configuration |

## Role Naming Conventions

| Prefix | Purpose |
|--------|---------|
| `infra_*` | Infrastructure setup (Pi config, K3s agents, static IP, Cloudflare) |
| `core_*` | Core K8s components (cert-manager, Traefik, Longhorn, ArgoCD) |
| `app_*` | Applications deployed via Ansible (not ArgoCD) |
| `util_*` | Utilities (reboot, ntfy notifications, Cloudflare tunnel) |
| `common_*` | Library roles (`common_k8s` for reusable K8s resources) |

**Note:** Most applications are managed by ArgoCD via `k8s-apps/`, not Ansible roles.

## common_k8s Library Role

Reusable task files for K8s resources. **Always use for new K8s apps**:

```yaml
- include_role:
    name: common_k8s
    tasks_from: namespace  # or: certificate, ingress, ingressroute, cloudflare, storage
  vars:
    k8s_namespace: my-app
```

Available: `namespace`, `certificate`, `ingress`, `ingressroute`, `cloudflare`, `storage`. See `roles/common_k8s/README.md` for variables.

## Kubernetes Patterns

| Resource | Solution |
|----------|----------|
| TLS | cert-manager with `letsencrypt-prod` ClusterIssuer |
| Ingress | Traefik (use `ingressroute` for HTTPS backends) |
| Storage | Longhorn (default), NFS for shared media |
| External Access | Cloudflare tunnels |
| Secrets | SealedSecrets (`kubeseal`) |
| GitOps | ArgoCD with ApplicationSets |

## ArgoCD GitOps

- **App manifests**: `k8s-apps/<domain>/<app>/` (e.g., `k8s-apps/media/jellyfin/`)
- **ApplicationSets**: `k8s-manifests/argocd/applicationsets/`
- Changes pushed to `k8s-apps/` auto-sync via ArgoCD

## Network

- Ansible connects via **Tailscale** (100.x.x.x)
- Cluster uses **static IPs** on 172.16.10.x subnet
- **Internal domain**: `*.corp.mulliken.net`
- **External domain**: `*.mulliken.net` (via Cloudflare)

## Host Groups

| Group | Nodes |
|-------|-------|
| `k3s_control_plane` | K3s master (super6c_node_1) |
| `pi_k3s_agents` | Raspberry Pi workers |
| `rhel_k3s_agents` | RHEL workers |

## Creating New Applications

**For ArgoCD-managed apps** (preferred):
1. Create `k8s-apps/<domain>/<app>/` directory
2. Add K8s manifests + `kustomization.yaml`
3. Commit and push - ArgoCD syncs automatically

**For Ansible-deployed apps**:
1. Create role: `roles/<prefix>_<name>/`
2. Use `common_k8s` for standard resources
3. Add Molecule tests in `molecule/default/`
4. Add role to playbook with tags
