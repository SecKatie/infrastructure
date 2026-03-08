# Implementation Plan: Upgrade Jellyseerr to Seerr

**Branch**: `003-upgrade-jellyseerr-seerr` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-upgrade-jellyseerr-seerr/spec.md`

## Summary

Upgrade the Jellyseerr media request manager to Seerr v3.0.1, the
unified successor created by the merger of the Overseerr and Jellyseerr
teams (February 2026). The migration is minimal: update the container
image, add security context for non-root execution, and switch health
probes to the proper HTTP endpoint. Seerr automatically migrates the
existing Jellyseerr SQLite database on first startup. All other
resources (namespace, PVC, certificates, ingresses) remain unchanged.

## Technical Context

**Language/Version**: YAML (Kubernetes manifests), Kustomize
**Primary Dependencies**: Seerr v3.0.1 (`ghcr.io/seerr-team/seerr:v3.0.1`)
**Storage**: SQLite (embedded in Seerr), persisted on existing Longhorn PVC (5Gi)
**Testing**: Manual validation (health endpoint, UI access, integration checks)
**Target Platform**: Kubernetes (ARM64/AMD64 — Seerr multi-arch image)
**Project Type**: Infrastructure deployment (Kustomize manifest modification)
**Performance Goals**: N/A (personal use)
**Constraints**: Single replica only (SQLite does not support concurrent writers)
**Scale/Scope**: 1 operator, <10 users, existing media library integrations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Declarative Everything | PASS | Only `jellyseerr.yaml` is modified. No manual kubectl commands for deployment. Longhorn snapshot is the only manual pre-step. |
| II. Convention Over Configuration | PASS | Follows existing app structure. Directory, namespace, and file naming preserved. No new files created. |
| III. Minimal Moving Parts | PASS | Single manifest change. No new CRDs, operators, or dependencies. No init container — uses native Kubernetes `fsGroup`. |
| IV. One-Step Deployment | PASS | Commit to main → ArgoCD auto-syncs. Rollback is `git revert HEAD`. |
| V. Secrets Discipline | PASS | No new secrets introduced. No plaintext secrets in repo. |

**Post-Phase 1 re-check**: All gates still pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-upgrade-jellyseerr-seerr/
├── plan.md              # This file
├── research.md          # Phase 0: technology decisions
├── data-model.md        # Phase 1: Kubernetes resource changes
├── quickstart.md        # Phase 1: deployment and validation guide
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
k8s-apps/media/jellyseerr/
├── kustomization.yaml        # Unchanged
├── namespace.yaml            # Unchanged
├── storage.yaml              # Unchanged
├── jellyseerr.yaml           # MODIFIED: image, security context, probes
├── certificate.yaml          # Unchanged
├── ingress.yaml              # Unchanged
├── public-certificate.yaml   # Unchanged
└── public-ingress.yaml       # Unchanged
```

**Structure Decision**: No structural changes. The existing flat
directory under `k8s-apps/media/jellyseerr/` is preserved. Only the
deployment manifest (`jellyseerr.yaml`) is modified. The directory name
remains `jellyseerr` to preserve ArgoCD application identity. No new
files are created.

## Complexity Tracking

> No constitution violations. No complexity justifications needed.
