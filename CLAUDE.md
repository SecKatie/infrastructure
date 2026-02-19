# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal infrastructure automation managing a Kubernetes cluster with self-hosted applications. DNS is managed via Cloudflare using OpenTofu (Terraform-compatible IaC).


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
opentofu/           # Cloudflare DNS records (managed via OpenTofu)
k8s-apps/           # Kubernetes application manifests (Kustomize)
  ├── media/        # Jellyfin, Jellyseerr, Sonarr, Radarr, qBittorrent, etc.
  ├── monitoring/   # Victoria Metrics, Node Exporter, Headlamp
  └── utilities/    # Paperless, Umami, Agate, Sealed Secrets
scripts/            # Helper scripts for K8s operations
```

### Kubernetes App Structure

Each app in `k8s-apps/` follows this pattern:
- `kustomization.yaml` - Kustomize config listing resources
- `namespace.yaml` - Dedicated namespace
- `sealedsecret.yaml` - Encrypted secrets (Sealed Secrets)
- `storage.yaml` - PersistentVolume/PVC definitions
- `cloudflare-tunnel.yaml` - Cloudflared deployment for external access
- `certificate.yaml` / `ingress.yaml` - TLS and routing

### External Access

Services exposed externally use Cloudflare Tunnels:
1. Tunnel credentials stored as SealedSecrets
2. Cloudflared deployment routes traffic to internal services
3. DNS CNAMEs in `opentofu/dns.tf` point to tunnel endpoints

### Secrets Management

All secrets use Bitnami Sealed Secrets. Never commit plaintext secrets.

## Active Technologies
- Shell (POSIX sh for CronJob script), HCL (OpenTofu) + Traefik (ingress controller), cert-manager (001-dyndns-ingress-migration)

## Recent Changes
- 001-dyndns-ingress-migration: Added Shell (POSIX sh for CronJob script), HCL (OpenTofu) + Traefik (ingress controller), cert-manager
