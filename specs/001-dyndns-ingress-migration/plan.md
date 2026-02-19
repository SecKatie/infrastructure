# Implementation Plan: DynDNS Ingress Migration

**Branch**: `001-dyndns-ingress-migration` | **Date**: 2026-02-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-dyndns-ingress-migration/spec.md`

## Summary

Migrate external service access from Cloudflare Tunnels to standard
Kubernetes Ingress with DynDNS. A CronJob updates DNSimple A records
with the cluster's public IP. Traefik ingress routes traffic to
5 services (Jellyfin, Jellyseerr, Umami, Paperless, personal-site)
with cert-manager TLS certificates. DNS management moves from
Cloudflare to DNSimple in OpenTofu. All tunnel infrastructure is
removed in a big-bang cutover.

## Technical Context

**Language/Version**: Shell (POSIX sh for CronJob script), HCL (OpenTofu)
**Primary Dependencies**: Traefik (ingress controller), cert-manager
(TLS), Kustomize (manifest management), ArgoCD (GitOps), DNSimple API
**Storage**: N/A
**Testing**: Manual validation per quickstart.md; `kustomize build`
for manifest validation; `just tf-plan` for OpenTofu validation
**Target Platform**: Kubernetes (k3s cluster)
**Project Type**: Infrastructure (Kubernetes manifests + OpenTofu)
**Performance Goals**: DNS propagation within 5 minutes of IP change
**Constraints**: DNS TTL ≤ 300s; CronJob interval ≤ 5 minutes
**Scale/Scope**: 5 public services, ~40 DNS records to migrate,
5 tunnel deployments to remove

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
| --------- | ------ | ----- |
| I. Declarative IaC | PASS | All changes are Kustomize manifests and OpenTofu HCL |
| II. Secrets Protection | PASS | DNSimple API token stored as SealedSecret (FR-003) |
| III. Clean Structure | PASS | New apps follow `k8s-apps/<category>/<app>/` pattern |
| IV. Automated Application | PASS | ArgoCD syncs manifests; `just` for OpenTofu |
| V. Best Practices | **VIOLATION** | See below |
| Security: TLS | PASS (amended) | TLS at ingress controller with cert-manager |

**Principle V violation**: The constitution states "External access
MUST use Cloudflare Tunnels with TLS." This migration intentionally
replaces Cloudflare Tunnels with ingress-based access. The
constitution MUST be amended as part of this feature (see Complexity
Tracking below and research.md R7).

**Post-design re-check**: All gates pass after the constitution
amendment is applied.

## Project Structure

### Documentation (this feature)

```text
specs/001-dyndns-ingress-migration/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md             # Created by /speckit.tasks
```

### Source Code (repository root)

```text
k8s-apps/
├── media/
│   ├── jellyfin/
│   │   ├── public-certificate.yaml   # NEW
│   │   ├── public-ingress.yaml       # NEW
│   │   ├── kustomization.yaml        # MODIFIED (add public-*, remove tunnel)
│   │   └── cloudflare-tunnel.yaml    # DELETED
│   ├── jellyseerr/
│   │   ├── public-certificate.yaml   # NEW
│   │   ├── public-ingress.yaml       # NEW
│   │   ├── kustomization.yaml        # MODIFIED
│   │   └── cloudflare-tunnel.yaml    # DELETED
│   └── ...                           # Other media apps unchanged
├── utilities/
│   ├── dyndns-updater/               # NEW app
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── sealedsecret.yaml
│   │   ├── configmap.yaml            # Update script
│   │   └── cronjob.yaml
│   ├── personal-site/                # NEW app (migrated)
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── certificate.yaml
│   │   └── ingress.yaml
│   ├── umami/
│   │   ├── public-certificate.yaml   # NEW
│   │   ├── public-ingress.yaml       # NEW
│   │   ├── kustomization.yaml        # MODIFIED
│   │   └── cloudflare-tunnel.yaml    # DELETED
│   └── paperless/
│       ├── public-certificate.yaml   # NEW
│       ├── public-ingress.yaml       # NEW
│       ├── kustomization.yaml        # MODIFIED
│       └── tunnel/                   # DELETED (entire directory)

k8s-manifests/argocd/
├── applications/
│   ├── personal-site.yaml            # MODIFIED (new source path)
│   └── dyndns-updater.yaml           # NEW

opentofu/
├── dns.tf                             # REWRITTEN (Cloudflare → DNSimple)
├── versions.tf                        # MODIFIED (remove Cloudflare provider)
└── provider.tf                        # MODIFIED (add DNSimple provider block)
```

**Structure Decision**: This is an infrastructure project. All changes
follow the existing `k8s-apps/<category>/<app>/` Kustomize pattern
and `opentofu/` HCL layout. No src/tests directories apply.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Constitution Principle V: "External access MUST use Cloudflare Tunnels" | This migration replaces tunnels with ingress by design. The principle was written for the pre-migration architecture. | Keeping Cloudflare Tunnels contradicts the feature's entire purpose. The constitution must be amended to reflect the new architecture. |
