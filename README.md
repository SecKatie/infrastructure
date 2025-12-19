# Raspberry Pi & Kubernetes Infra Automation (Ansible)

Automate the lifecycle of Raspberry Pi clusters and Kubernetes app deployments. Ansible handles provisioning, configuration, application rollout (Docmost, Ghost), and secret management (Kubeseal). The structure is modular and easy to extend.

---

## Project Layout

```text
roles/           # Modular Ansible roles (Pi setup, K8s apps, etc.)
playbooks/       # Main workflows (infrastructure, maintenance, monitoring, testing)
inventory/       # Inventory folder (hosts.yml + group_vars/)
requirements.txt # Python dependencies for Ansible/Molecule
galaxy.yml       # Collection metadata (optional, for Galaxy packaging)
MOLECULE_TESTING.md # Molecule testing documentation
README.md        # You're reading it
```

## Playbook Naming Scheme

All playbooks follow a consistent hierarchical naming scheme for easy identification and organization:

**Format**: `{category}-{action}-{target}.yml`

### Categories:
- **`infrastructure-`** - Deploy, install, and configure system components
- **`maintenance-`** - System maintenance tasks (updates, reboots, backups)
- **`monitoring-`** - System monitoring and health checks
- **`testing-`** - Test functionality and validate configurations

### Examples:
- `infrastructure-deploy-complete.yml` - Complete infrastructure deployment
- `infrastructure-install-k8s-apps.yml` - Install Kubernetes applications
- `maintenance-update-packages.yml` - Update all system packages
- `monitoring-system-health.yml` - Monitor system health with notifications
- `testing-notification-system.yml` - Test notification system functionality

### Benefits:
- **Alphabetical grouping**: Related playbooks are grouped together when listed
- **Clear purpose**: Category and action immediately indicate what the playbook does
- **Consistent format**: All playbooks use hyphens for better readability
- **Scalable**: Easy to add new playbooks following the same pattern

---

## Quick-Start

### 1. Prerequisites

- Ansible (install with `pip install -r requirements.txt`)
- SSH access to your Pis
- A valid kubeconfig with admin rights to your cluster
- Kubeseal installed (for encrypted secrets)
- Cloudflare API token (optional – only if you want DNS automation)

### 2. Inventory Setup

Edit `inventory/hosts.yml` **and** the matching group-vars file `inventory/group_vars/raspberrypi.yml`:

`inventory/hosts.yml`

```yaml
all:
  children:
    raspberrypi:
      hosts:
        pi1:
          ansible_host: 192.168.1.10
        pi2:
          ansible_host: 192.168.1.11
```

`inventory/group_vars/raspberrypi.yml`

```yaml
ansible_user: kglitchy
```

### 3. Configure Variables

- `roles/k8s/defaults/main.yml` – cluster & app parameters
- Secret management: All plaintext secrets must be sealed with Kubeseal before deployment.

### 4. Encrypt & Place Secrets

```sh
kubeseal --format yaml < my-secrets.yaml > sealedsecrets.yaml
```

Place the output in `roles/k8s/files/<app>/sealedsecrets.yaml`.

---

## Usage

### Deploy Everything

```sh
ansible-playbook -i inventory playbooks/infrastructure-deploy-complete.yml -K
# -K prompts for sudo/SSH password if required
```

### Install Kubernetes Applications

```sh
ansible-playbook -i inventory playbooks/infrastructure-install-k8s-apps.yml -K
```

### Update All Systems

```sh
ansible-playbook -i inventory playbooks/maintenance-update-packages.yml -K
```

### Reboot Devices

```sh
ansible-playbook -i inventory playbooks/maintenance-reboot-systems.yml -K
```

### Monitor System Health

```sh
ansible-playbook -i inventory playbooks/monitoring-system-health.yml -K
```

### Test Notifications

```sh
ansible-playbook -i inventory playbooks/testing-notification-system.yml -K
```

---

## Roles / Playbooks at a Glance

### Roles

**Infrastructure**
| Role                 | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| infra_rpi_setup      | Installs & configures iSCSI, sets cgroup options, enables services |
| infra_k3s_agent      | Joins RHEL nodes to K3s cluster as agents                      |

**Library Roles**
| Role                 | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| common_k8s           | Reusable Kubernetes resource library (namespace, ingress, storage, etc.) |

**Core & Observability**
| Role                 | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| core_cert_manager    | Deploys cert-manager for TLS certificates                      |
| core_traefik         | Configures Traefik ingress controller                          |
| core_longhorn        | Deploys Longhorn distributed storage                           |
| observability_*      | Victoria Metrics, Grafana, Node Exporter                       |

**Applications & Dashboards**
| Role                 | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| dashboard_*          | Kubernetes Dashboard, Headlamp, Homepage                       |
| app_*                | Jellyfin, Media stack, Paperless, Plane, Immich                |

**Utilities**
| Role                 | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| util_reboot          | Reboots systems in a controlled manner                         |
| util_ntfy_notify     | Sends notifications via ntfy                                   |

### Playbooks
| Playbook                             | Purpose                                                        |
|--------------------------------------|----------------------------------------------------------------|
| infrastructure-deploy-complete.yml   | Complete infrastructure deployment (Pi setup + K8s apps)      |
| infrastructure-install-k8s-apps.yml  | Install Kubernetes applications (Dashboard, Docmost, Ghost, etc.) |
| infrastructure-install-nfs-support.yml | Install NFS support on Kubernetes nodes                     |
| maintenance-update-packages.yml      | Update all system packages with notification support          |
| maintenance-reboot-systems.yml       | Reboot all systems in the inventory                          |
| monitoring-system-health.yml         | Monitor system health with ntfy notifications                |
| testing-notification-system.yml      | Test ntfy notification system functionality                   |

---

## App Deployments

| App           | Stack Components                                 | Notes                |
|---------------|--------------------------------------------------|----------------------|
| Docmost       | StatefulSet, Postgres, Redis, Cloudflared tunnel | Knowledge-base       |
| Ghost         | StatefulSet, MySQL, Cloudflared, sealed secrets  | Blogging CMS         |
| K8s Dashboard | Web UI exposed via NodePort or LB                | Admin token auto-created |

All manifests live in `roles/k8s/files/<app>/`.  
Update domain names and secret values for your environment.

---

## Security Checklist

- Never commit plaintext secrets – always use Kubeseal.
- Replace placeholder domains (`*.mulliken.net`) with your own.
- Use SSH keys wherever possible (password auth only as fallback).

---

## Testing

This project includes comprehensive Molecule testing for all roles. To run tests:

```bash
# Test a single role
cd roles/system_update
molecule test

# Test all roles
for role in roles/*/; do (cd "$role" && molecule test); done
```

See `MOLECULE_TESTING.md` for detailed testing documentation.

## Extending the Stack

1. Add a new role under `roles/` and reference it in the relevant playbook.
2. Use the `common_k8s` library role for common resources (namespace, ingress, storage, etc.) - see `roles/common_k8s/README.md`
3. Use variables and templates for environment-specific tweaks.
4. Add Molecule tests for validation (templates available in existing roles).

---

## Migration to common_k8s Library

The following roles can be migrated to use the `common_k8s` library to eliminate duplicate code:

### Dashboard Roles
- [ ] `dashboard_kubernetes` - Uses IngressRoute (keep as-is for HTTPS backend)
- [ ] `dashboard_headlamp` - Migrate certificate, ingress, storage
- [ ] `dashboard_homepage` - Migrate certificate, ingress, storage

### Application Roles
- [ ] `app_personal_site` - Migrate ingress
- [x] `app_jellyfin` - Migrate certificate, ingress, cloudflare, storage
- [x] `app_media` - Migrate certificate, ingress, storage
- [x] `app_paperless` - Migrate cloudflare, storage
- [ ] `app_plane` - Migrate certificate, ingress, storage
- [ ] `app_immich` - Migrate certificate, ingress, storage
- [ ] `app_uptime_kuma` - Check if applicable

### Observability Roles
- [ ] `observability_grafana` - Migrate certificate, ingress, storage
- [ ] `observability_victoria_metrics` - Migrate certificate, ingress, storage
- [ ] `observability_node_exporter` - No common resources needed (DaemonSet only)

### Migration Benefits
- **Reduce codebase by ~500+ lines** (eliminate duplicate templates)
- **Improve consistency** across all applications
- **Easier maintenance** - fix bugs once, benefit everywhere
- **Variable validation** - catch configuration errors early

### Migration Steps
1. Identify templates that can be replaced (certificate, ingress, storage, cloudflare)
2. Update role's `tasks/main.yml` to use `include_role` with `common_k8s`
3. Delete redundant template files
4. Test the role to ensure functionality
5. Mark checkbox above as complete

---

## License

GPL-2.0-or-later – see `galaxy.yml` for full details.

---

Built for pragmatic, security-minded automation of ARM clusters and K8s workloads. PRs to improve, modernize, or harden are welcome.
