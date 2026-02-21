# Implementation Plan: Install Pocket-ID

**Branch**: `002-install-pocket-id` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-install-pocket-id/spec.md`

## Summary

Deploy Pocket-ID v2.2.0 as a self-hosted OIDC provider in the
Kubernetes cluster. The deployment follows the standard utilities app
convention with plain Kustomize manifests, Longhorn-backed SQLite
persistence, a ConfigMap for expandable configuration, a SealedSecret
for the encryption key, and dual ingress (internal at
pocket-id.corp.mulliken.net, public at auth.mulliken.net). ArgoCD
auto-discovers the app via the existing utilities ApplicationSet.

## Technical Context

**Language/Version**: YAML (Kubernetes manifests), Kustomize
**Primary Dependencies**: Pocket-ID v2.2.0 (`ghcr.io/pocket-id/pocket-id:v2.2.0`)
**Storage**: SQLite (embedded in Pocket-ID), persisted on Longhorn PVC (2Gi)
**Testing**: Manual validation (health endpoint, OIDC discovery, browser access)
**Target Platform**: Kubernetes (ARM64/AMD64 — Pocket-ID multi-arch image)
**Project Type**: Infrastructure deployment (Kustomize manifests)
**Performance Goals**: N/A (personal use, single operator)
**Constraints**: Single replica only (SQLite does not support concurrent writers)
**Scale/Scope**: 1 operator, <10 OIDC clients, <10 user accounts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Declarative Everything | PASS | All resources are Kustomize YAML manifests in `k8s-apps/utilities/pocket-id/`. No manual kubectl commands required for deployment. |
| II. Convention Over Configuration | PASS | Follows standard app structure: namespace.yaml, configmap.yaml, deployment.yaml, service.yaml, storage.yaml, sealedsecret.yaml, certificate.yaml, ingress.yaml, public-certificate.yaml, public-ingress.yaml, kustomization.yaml. |
| III. Minimal Moving Parts | PASS | SQLite eliminates a separate database pod. Single container, no Helm chart, no CRDs. ConfigMap adds one resource but provides expandability. |
| IV. One-Step Deployment | PASS | Commit to main → ArgoCD auto-syncs via utilities ApplicationSet. Only manual step is initial kubeseal for the encryption key (one-time). |
| V. Secrets Discipline | PASS | Encryption key stored in SealedSecret. No plaintext secrets in repo. |

**Post-Phase 1 re-check**: All gates still pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/002-install-pocket-id/
├── plan.md              # This file
├── research.md          # Phase 0: technology decisions
├── data-model.md        # Phase 1: Kubernetes resource definitions
├── quickstart.md        # Phase 1: deployment and validation guide
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
k8s-apps/utilities/pocket-id/
├── kustomization.yaml        # Kustomize root listing all resources
├── namespace.yaml            # pocket-id namespace
├── configmap.yaml            # Non-secret Pocket-ID configuration
├── deployment.yaml           # Single-replica Pocket-ID deployment
├── service.yaml              # ClusterIP service (port 80 → 1411)
├── storage.yaml              # Longhorn PVC (2Gi)
├── sealedsecret.yaml         # Encrypted encryption key
├── certificate.yaml          # Internal TLS (pocket-id.corp.mulliken.net)
├── ingress.yaml              # Internal ingress
├── public-certificate.yaml   # Public TLS (auth.mulliken.net)
└── public-ingress.yaml       # Public ingress

k8s-manifests/argocd/projects/
└── utilities.yaml            # Add pocket-id namespace to destinations
```

**Structure Decision**: Flat directory under `k8s-apps/utilities/pocket-id/`
following the simple app pattern (like umami and personal-site). No
subdirectories needed since Pocket-ID is a single-container app with no
external database. The ArgoCD utilities ApplicationSet auto-discovers
this directory — no new Application manifest is required.

## Complexity Tracking

> No constitution violations. No complexity justifications needed.
