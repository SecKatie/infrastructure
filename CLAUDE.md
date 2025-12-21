# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an Ansible-based infrastructure automation repository for managing a Kubernetes (K3s) cluster running on Raspberry Pi and RHEL nodes. It handles:
- Cluster provisioning and configuration
- Application deployments to Kubernetes
- Secret management with SealedSecrets
- TLS certificates via cert-manager
- GitOps with ArgoCD

## Common Commands

```bash
# Run a playbook (vault password file is set in ansible.cfg at ~/.ansible-vault-pass.sh)
# Note: -K (become password) is NOT needed - do not include it
ansible-playbook -i inventory playbooks/<playbook>.yml

# Deploy everything using the master playbook
ansible-playbook -i inventory playbooks/deploy.yml

# Deploy specific components using tags
ansible-playbook -i inventory playbooks/deploy.yml --tags applications
ansible-playbook -i inventory playbooks/deploy.yml --tags jellyfin
ansible-playbook -i inventory playbooks/deploy.yml --tags "infrastructure,core"

# Test a single role with Molecule
cd roles/<role_name>
molecule test

# Run Molecule converge (apply without teardown, useful for iterating)
cd roles/<role_name>
molecule converge

# Encrypt secrets with Kubeseal
kubeseal --format yaml < my-secrets.yaml > sealedsecrets.yaml

# Get Kubernetes Dashboard token (requires just command runner)
just dashboard-token
```

## Project Structure

```
infrastructure/
├── ansible.cfg              # Ansible configuration (vault password, paths)
├── CLAUDE.md                # This file - AI assistant guidance
├── AGENTS.md                # Lola skills reference
├── MOLECULE_TESTING.md      # Molecule testing documentation
├── README.md                # Project overview
├── galaxy.yml               # Ansible Galaxy collection metadata
├── justfile                 # Task runner commands
├── requirements.txt         # Python dependencies
├── requirements.yml         # Ansible collection dependencies
├── .python-version          # Python version specification
│
├── playbooks/               # Ansible playbooks by category
│   ├── deploy.yml           # Master orchestration playbook
│   ├── applications.yml     # User apps deployment
│   ├── core.yml             # Core K8s components
│   ├── dashboards.yml       # Dashboard UIs
│   ├── infrastructure.yml   # Infrastructure setup
│   ├── k3s.yml              # K3s cluster configuration
│   ├── observability.yml    # Monitoring stack
│   ├── static_ip.yml        # Static IP configuration
│   ├── update.yml           # System updates
│   ├── uptime-kuma.yml      # Uptime Kuma deployment
│   ├── vars/                # Encrypted secrets (ansible-vault)
│   ├── utilities/           # Utility playbooks
│   └── archive/             # Deprecated playbooks
│
├── roles/                   # Ansible roles (see Role Naming below)
│
├── k8s-apps/                # ArgoCD-managed K8s manifests
│   ├── applicationset.yaml  # ArgoCD ApplicationSet for GitOps
│   ├── agate/               # Gemini protocol server
│   ├── headlamp/            # Kubernetes web UI
│   ├── homepage/            # Dashboard homepage
│   ├── immich/              # Photo management
│   ├── jackett/             # Indexer proxy
│   ├── jellyfin/            # Media server
│   ├── kubernetes-dashboard/
│   ├── node-exporter/       # Prometheus node exporter
│   ├── paperless/           # Document management
│   ├── personal-site/       # Static landing page
│   ├── qbittorrent/         # BitTorrent client
│   ├── radarr/              # Movie management
│   ├── sabnzbd/             # Usenet downloader
│   ├── sealed-secrets/      # SealedSecrets controller
│   ├── sonarr/              # TV management
│   └── victoria-metrics/    # Metrics storage
│
├── inventory/
│   ├── hosts.yml            # Host definitions
│   └── group_vars/          # Group-specific variables
│       ├── all_raspberry_pi.yml
│       ├── k3s_control_plane.yml
│       ├── pi_k3s_agents.yml
│       ├── rhel_k3s_agents.yml
│       ├── super6c_standalone.yml
│       └── vps_servers.yml
│
├── collections/             # Ansible collections (community.general)
└── scripts/                 # Utility scripts
    ├── configure_openbao.sh
    ├── homepage-add-icon.sh
    ├── sonarr-proxies.sh
    └── start-dashboard.sh
```

## Playbooks

### Master Deployment

| Playbook | Description |
|----------|-------------|
| `deploy.yml` | Imports all other playbooks, orchestrates full deployment |

### Component Playbooks

| Playbook | Description | Key Tags |
|----------|-------------|----------|
| `infrastructure.yml` | Pi setup, NFS support, static IP | `infrastructure`, `rpi`, `nfs` |
| `k3s.yml` | K3s cluster agent configuration | `k3s`, `k3s_agents` |
| `core.yml` | Longhorn, cert-manager, Traefik, ArgoCD | `core`, `storage`, `security`, `networking`, `gitops` |
| `observability.yml` | Victoria Metrics, Node Exporter | `observability`, `metrics` |
| `dashboards.yml` | K8s Dashboard, Headlamp, Homepage | `dashboards` |
| `applications.yml` | Jellyfin, Media stack, Paperless, Immich, Agate | `applications`, `jellyfin`, `media`, `paperless` |
| `update.yml` | System package updates | `update` |
| `static_ip.yml` | Static IP configuration for nodes | `static_ip` |

### Usage Examples

```bash
# Deploy only core infrastructure
ansible-playbook -i inventory playbooks/core.yml

# Deploy only Jellyfin
ansible-playbook -i inventory playbooks/applications.yml --tags jellyfin

# Deploy multiple specific components
ansible-playbook -i inventory playbooks/deploy.yml --tags "core,applications"

# Skip IPv6 disabling
ansible-playbook -i inventory playbooks/deploy.yml --skip-tags ipv6
```

## Role Naming Conventions

Roles follow a prefix scheme indicating their purpose:

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `infra_*` | Infrastructure setup | `infra_rpi_setup`, `infra_k3s_agent`, `infra_static_ip`, `infra_cloudflared`, `infra_cloudflare_ddns`, `infra_squid` |
| `core_*` | Core K8s components | `core_cert_manager`, `core_traefik`, `core_longhorn`, `core_argocd` |
| `app_*` | Applications | `app_jellyfin`, `app_media`, `app_paperless`, `app_immich`, `app_personal_site`, `app_uptime_kuma` |
| `dashboard_*` | Dashboard UIs | `dashboard_kubernetes`, `dashboard_headlamp`, `dashboard_homepage` |
| `observability_*` | Monitoring | `observability_victoria_metrics`, `observability_node_exporter`, `observability_grafana` |
| `util_*` | Utilities | `util_reboot`, `util_ntfy_notify`, `util_cloudflare_tunnel` |
| `common_*` | Library roles | `common_k8s` |
| `install_*` | Single-purpose installers | `install_agate` |

## common_k8s Library Role

The `common_k8s` role provides reusable task files for Kubernetes resources. **Always use it for new K8s apps** instead of duplicating templates:

```yaml
# Usage pattern - include specific task files
- include_role:
    name: common_k8s
    tasks_from: namespace  # or certificate, ingress, ingressroute, cloudflare, storage
  vars:
    k8s_namespace: my-app
    # ... other required vars
```

### Available Task Files

| Task File | Purpose | Key Variables |
|-----------|---------|---------------|
| `namespace` | Create namespace | `k8s_namespace`, `k8s_labels` |
| `certificate` | cert-manager Certificate | `k8s_cert_name`, `k8s_cert_secret_name`, `k8s_cert_dns_names` |
| `ingress` | Standard K8s Ingress | `k8s_ingress_name`, `k8s_ingress_host`, `k8s_ingress_service_name` |
| `ingressroute` | Traefik IngressRoute (HTTPS backends) | `k8s_ingressroute_name`, `k8s_ingressroute_host`, `k8s_ingressroute_service_name` |
| `cloudflare` | Cloudflare tunnel deployment | `k8s_cloudflare_tunnel_name`, `k8s_cloudflare_external_hostname`, `k8s_cloudflare_internal_service` |
| `storage` | PersistentVolumeClaim | `k8s_pvc_name`, `k8s_pvc_size` |

See `roles/common_k8s/README.md` for full variable documentation and validation rules.

## Kubernetes Resource Patterns

| Resource Type | Solution | Notes |
|---------------|----------|-------|
| TLS Certificates | cert-manager with `letsencrypt-prod` ClusterIssuer | Auto-renewal via ACME |
| Ingress | Traefik ingress controller | Use `ingressroute` for HTTPS backends |
| Storage | Longhorn (distributed), NFS (shared media) | Longhorn is default StorageClass |
| External Access | Cloudflare tunnels | For public-facing apps |
| Secrets | SealedSecrets (kubeseal) | Never commit plaintext secrets |
| GitOps | ArgoCD with ApplicationSet | Manifests in `k8s-apps/` directory |

## ArgoCD / GitOps

The `k8s-apps/` directory contains Kubernetes manifests managed by ArgoCD:

- Each subdirectory is an application (e.g., `k8s-apps/jellyfin/`)
- `applicationset.yaml` defines the ArgoCD ApplicationSet that watches this directory
- Changes to manifests in `k8s-apps/` are automatically synced by ArgoCD

## Inventory Structure

### Host Groups

| Group | Description |
|-------|-------------|
| `k3s_control_plane` | K3s master node (super6c_node_1) |
| `pi_k3s_agents` | Raspberry Pi worker nodes |
| `rhel_k3s_agents` | RHEL worker nodes |
| `vps_servers` | Cloud/VPS servers |
| `super6c_standalone` | Super6C nodes not in cluster |
| `all_raspberry_pi` | All Raspberry Pi devices |
| `all_rhel` | All RHEL devices |

### Network Configuration

- Ansible connects via Tailscale IPs (100.x.x.x)
- Static IPs are configured on 172.16.10.x subnet for cluster communication
- Each host has `infra_static_ip_address` variable for static IP assignment

## Secrets Management

Secrets are stored as encrypted ansible-vault files in `playbooks/vars/`:

| File | Purpose |
|------|---------|
| `cloudflare_secrets.yml` | Cloudflare API tokens |
| `immich_secrets.yml` | Immich app secrets |
| `media_secrets.yml` | Media stack secrets |
| `paperless_secrets.yml` | Paperless secrets |
| `homepage_secrets.yml` | Homepage dashboard config |
| `grafana_secrets.yml` | Grafana admin credentials |
| `squid_secrets.yml` | Squid proxy config |
| `ngrok_secrets.yml` | ngrok tunnel config |

The vault password file is configured in `ansible.cfg` at `~/.ansible-vault-pass.sh`.

## Testing

Each role can have Molecule tests in `roles/<role>/molecule/default/`:

```bash
# Full test (create, converge, verify, destroy)
cd roles/<role_name>
molecule test

# Apply role without destroy (for iterating)
molecule converge

# Run only verification tests
molecule verify

# Cleanup
molecule destroy
```

See `MOLECULE_TESTING.md` for detailed testing documentation.

## Key Domain Notes

- **Target Infrastructure**: Raspberry Pi (ARM64) and RHEL nodes running K3s
- **Internal Domain**: `*.corp.mulliken.net` (via internal DNS)
- **External Domain**: `*.mulliken.net` (via Cloudflare)
- **Notifications**: ntfy service for alerts
- **License**: GPL-2.0-or-later

## Creating New Roles

1. Create role directory: `roles/<prefix>_<name>/`
2. Add `tasks/main.yml`, `defaults/main.yml`, `templates/` as needed
3. Use `common_k8s` for standard K8s resources
4. Add Molecule tests in `molecule/default/`
5. Add role to appropriate playbook with tags
6. Document in role's `README.md`

## Creating New Applications

For K8s applications:

1. **Option A - Ansible Role**: Create `app_<name>` role using `common_k8s` library
2. **Option B - ArgoCD**: Add manifests to `k8s-apps/<name>/` for GitOps management

Both approaches can be combined - use Ansible for initial setup/secrets, ArgoCD for ongoing management.
