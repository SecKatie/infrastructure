# Data Model: Upgrade Jellyseerr to Seerr

**Feature Branch**: `003-upgrade-jellyseerr-seerr`
**Date**: 2026-02-21

## Overview

This migration modifies a single Kubernetes resource (the Deployment +
Service manifest). All other resources (namespace, PVC, certificates,
ingresses, kustomization) remain unchanged. Seerr manages its own data
model internally via the same embedded SQLite database that Jellyseerr
used, with automatic migration on first startup.

## Changed Resources

### Deployment: jellyseerr (modified)

Changes from current state:

- **Image**: `ghcr.io/fallenbagel/jellyseerr:latest` →
  `ghcr.io/seerr-team/seerr:v3.0.1`
- **Container name**: `jellyseerr` → `seerr`
- **Description annotation**: Updated to reflect Seerr
- **Pod security context** (added):
  - `fsGroup: 1000`
  - `fsGroupChangePolicy: OnRootMismatch`
- **Container security context** (added):
  - `runAsUser: 1000`
  - `runAsGroup: 1000`
  - `runAsNonRoot: true`
  - `allowPrivilegeEscalation: false`
  - `capabilities: { drop: ["ALL"] }`
- **Liveness probe**: TCP socket → HTTP GET `/api/v1/status` on
  port 5055, initial delay 30s, period 15s, timeout 3s, failure
  threshold 3
- **Readiness probe**: TCP socket → HTTP GET `/api/v1/status` on
  port 5055, initial delay 20s, period 15s, timeout 3s, failure
  threshold 3

### Service: jellyseerr (unchanged)

No changes. Port 5055 → 5055, ClusterIP, same selectors.

## Unchanged Resources

All of the following remain as-is:

- **Namespace**: `jellyseerr` — no rename
- **PVC**: `jellyseerr-config-pvc` — reused for automatic migration
  (5Gi, Longhorn, ReadWriteOnce)
- **Certificate**: `jellyseerr-tls` — internal TLS for
  jellyseerr.corp.mulliken.net
- **Ingress**: `jellyseerr` — internal ingress, same hostname and
  backend
- **Certificate**: `jellyseerr-public-tls` — public TLS for
  jellyseerr.mulliken.net
- **Ingress**: `jellyseerr-public` — public ingress, same hostname and
  backend
- **Kustomization**: Same resource list, no changes

## Pre-Migration Requirement

A Longhorn volume snapshot of `jellyseerr-config-pvc` MUST be taken
before committing the deployment change. This enables rollback to the
Jellyseerr state if the automatic migration fails.
