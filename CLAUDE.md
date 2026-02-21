# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal infrastructure automation managing a Kubernetes cluster with self-hosted applications. DNS is managed via DNSimple using OpenTofu (Terraform-compatible IaC). External services are exposed via Traefik Ingress with TLS certificates from Let's Encrypt (cert-manager + DNSimple DNS-01 webhook).


## Commands

Task runner uses `just`. Run `just --list` to see available recipes.

```bash
# OpenTofu/Terraform (DNS management)
just tf-init      # Initialize OpenTofu
just tf-plan      # Preview infrastructure changes
just tf-apply     # Apply infrastructure changes
just tf-validate  # Validate configs
just tf-fmt       # Format .tf files

# Kubernetes
just dashboard-token  # Get K8s dashboard token (copies to clipboard)
```

## Architecture

```
opentofu/           # DNSimple DNS records (managed via OpenTofu)
k8s-apps/           # Kubernetes application manifests (Kustomize)
  ├── media/        # Jellyfin, Jellyseerr, Sonarr, Radarr, qBittorrent, etc.
  ├── monitoring/   # Victoria Metrics, Node Exporter, Headlamp
  └── utilities/    # Paperless, Umami, Agate, DynDNS Updater, Personal Site, Sealed Secrets
k8s-manifests/      # Cluster-level manifests (ArgoCD apps, projects, cert-manager)
scripts/            # Helper scripts for K8s operations
```

### Kubernetes App Structure

Each app in `k8s-apps/` follows this pattern:
- `kustomization.yaml` - Kustomize config listing resources
- `namespace.yaml` - Dedicated namespace
- `sealedsecret.yaml` - Encrypted secrets (Sealed Secrets)
- `storage.yaml` - PersistentVolume/PVC definitions
- `certificate.yaml` / `ingress.yaml` - Internal TLS and routing (*.corp.mulliken.net)
- `public-certificate.yaml` / `public-ingress.yaml` - Public TLS and routing (*.mulliken.net)

### External Access

Services exposed externally use Traefik Ingress with Let's Encrypt TLS:
1. A DynDNS updater CronJob (`k8s-apps/utilities/dyndns-updater/`) keeps wildcard and apex A records in DNSimple current with the cluster's public IP
2. Traefik ingress routes external traffic to services via `public-ingress.yaml` manifests
3. cert-manager issues TLS certificates via DNS-01 challenge using the DNSimple webhook (`cert-manager-webhook-dnsimple`)
4. Router port-forwards 80/443 to Traefik NodePorts (HTTP: 31899, HTTPS: 30443)

Public services: Jellyfin, Jellyseerr, Umami, Paperless, Personal Site (mulliken.net)
Internal services: accessible via *.corp.mulliken.net (unchanged)

### Secrets Management

All secrets use Bitnami Sealed Secrets. Never commit plaintext secrets.

When adding keys to an existing sealed secret, pipe `kubectl get secret` JSON through `jq` directly to `kubeseal` — do NOT use `kubectl apply --dry-run=client` in the pipeline as it strips newly-added keys:

```bash
kubectl get secret <name> -n <ns> -o json | \
  jq '.data["new-key"] = "'$(echo -n "VALUE" | base64)'"' | \
  kubeseal --format yaml \
  --controller-name sealed-secrets \
  --controller-namespace kube-system > path/to/sealedsecret.yaml
```

### OIDC/SSO via Pocket-ID

Apps can authenticate against the Pocket-ID instance at `auth.mulliken.net`. Paperless-ngx uses django-allauth's `openid_connect` provider, configured via env vars in the deployment. Secret values (client ID/secret) are injected into the `PAPERLESS_SOCIALACCOUNT_PROVIDERS` JSON string using Kubernetes `$(ENV_VAR)` interpolation — the secret refs must be defined as env vars earlier in the list so they resolve at container startup.

## Active Technologies
- HCL (OpenTofu) — DNSimple DNS management
- Shell (POSIX sh) — DynDNS updater CronJob script
- Traefik — Ingress controller for external and internal routing
- cert-manager + DNSimple webhook — Automated TLS certificate management via DNS-01
- YAML (Kubernetes manifests), Kustomize + Pocket-ID v2.2.0 (`ghcr.io/pocket-id/pocket-id:v2.2.0`) (002-install-pocket-id)
- SQLite (embedded in Pocket-ID), persisted on Longhorn PVC (2Gi) (002-install-pocket-id)
- YAML (Kubernetes manifests), Kustomize + Seerr v3.0.1 (`ghcr.io/seerr-team/seerr:v3.0.1`) (003-upgrade-jellyseerr-seerr)
- SQLite (embedded in Seerr), persisted on existing Longhorn PVC (5Gi) (003-upgrade-jellyseerr-seerr)

## Recent Changes
- 002-install-pocket-id: Added YAML (Kubernetes manifests), Kustomize + Pocket-ID v2.2.0 (`ghcr.io/pocket-id/pocket-id:v2.2.0`)
