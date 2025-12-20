# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Run a playbook (vault password file is set in ansible.cfg at ~/.ansible-vault-pass.sh)
ansible-playbook -i inventory playbooks/<playbook>.yml -K

# Deploy everything using the master playbook
ansible-playbook -i inventory playbooks/deploy.yml -K

# Deploy specific components using tags
ansible-playbook -i inventory playbooks/deploy.yml --tags applications -K
ansible-playbook -i inventory playbooks/deploy.yml --tags jellyfin -K

# Test a single role with Molecule
cd roles/<role_name>
molecule test

# Run Molecule converge (apply without teardown, useful for iterating)
cd roles/<role_name>
molecule converge

# Encrypt secrets with Kubeseal
kubeseal --format yaml < my-secrets.yaml > sealedsecrets.yaml
```

## Architecture Overview

### Playbooks
Playbooks are organized by category in `playbooks/`:
- `deploy.yml` - Master orchestration playbook (imports all others)
- `applications.yml` - User apps (jellyfin, media, paperless, immich, agate, personal_site)
- `core.yml` - Core K8s components (cert-manager, traefik, longhorn)
- `dashboards.yml` - Dashboard UIs (homepage, headlamp, kubernetes-dashboard)
- `infrastructure.yml` - Infrastructure setup (rpi_setup, NFS)
- `k3s.yml` - K3s cluster agent configuration
- `observability.yml` - Monitoring stack (grafana, victoria-metrics, node-exporter)
- `update.yml` - System updates
- `static_ip.yml` - Static IP configuration for cluster nodes

Use tags to deploy specific roles:
```bash
# Deploy only media stack
ansible-playbook -i inventory playbooks/applications.yml --tags media

# Deploy only jellyfin
ansible-playbook -i inventory playbooks/applications.yml --tags jellyfin
```

### Role Naming Conventions
Roles follow a prefix scheme indicating their purpose:
- `infra_*` - Infrastructure setup (rpi_setup, k3s_agent, static_ip, system_update)
- `core_*` - Core K8s components (cert_manager, traefik, longhorn)
- `app_*` - Applications (jellyfin, media, paperless, immich, personal_site, uptime_kuma)
- `dashboard_*` - Dashboard UIs (kubernetes, headlamp, homepage)
- `observability_*` - Monitoring (grafana, victoria_metrics, node_exporter)
- `util_*` - Utilities (reboot, ntfy_notify, cloudflare_tunnel)
- `common_*` - Library roles (common_k8s)

### common_k8s Library Role
The `common_k8s` role is a library that provides reusable task files for Kubernetes resources. **Always use it for new K8s apps** instead of duplicating templates:

```yaml
# Usage pattern - include specific task files
- include_role:
    name: common_k8s
    tasks_from: namespace  # or certificate, ingress, ingressroute, cloudflare, storage
  vars:
    k8s_namespace: my-app
    # ... other required vars
```

Available task files: `namespace`, `certificate`, `ingress`, `ingressroute`, `cloudflare`, `storage`

See `roles/common_k8s/README.md` for full variable documentation and validation rules.

### Kubernetes Resource Patterns
- TLS certificates: cert-manager with `letsencrypt-prod` ClusterIssuer
- Ingress: Traefik ingress controller (use `ingressroute` for HTTPS backends)
- Storage: Longhorn for persistent storage, NFS for shared media
- External access: Cloudflare tunnels for public-facing apps
- Secrets: SealedSecrets (kubeseal) - never commit plaintext secrets

### Inventory Structure
```
inventory/
├── hosts.yml           # Host definitions
└── group_vars/         # Group-specific variables
    ├── all_raspberry_pi.yml
    ├── pi_k3s_agents.yml
    ├── rhel_k3s_agents.yml
    ├── k3s_control_plane.yml
    └── vps_servers.yml
```

## Testing

Each role can have Molecule tests in `roles/<role>/molecule/default/`:
- `molecule.yml` - Configuration (platforms, test sequence)
- `converge.yml` - Playbook that runs the role
- `verify.yml` - Verification tests

## Key Domain Notes
- Target infrastructure: Raspberry Pi and RHEL nodes running K3s
- Domain pattern: Internal (`*.corp.mulliken.net`), external (`*.mulliken.net`)
- Notifications: ntfy service for alerts
- Vault secrets: Encrypted var files in `vars/` directory (e.g., `vars/immich_secrets.yml`)
