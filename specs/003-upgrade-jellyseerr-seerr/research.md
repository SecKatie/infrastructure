# Research: Upgrade Jellyseerr to Seerr

**Feature Branch**: `003-upgrade-jellyseerr-seerr`
**Date**: 2026-02-21

## Decision 1: Seerr Image and Version

**Decision**: Use `ghcr.io/seerr-team/seerr:v3.0.1`

**Rationale**: v3.0.1 is the latest stable release (February 14, 2026),
a patch on top of the initial v3.0.0 unification release. Pinning to a
specific version rather than `latest` follows the principle of
reproducible deployments. The image is confirmed available on GHCR with
multi-arch support (amd64/arm64).

**Alternatives considered**:
- `latest` tag: Rejected — unpinned tags cause non-deterministic
  deployments and make rollback harder.
- `v3.0.0`: Rejected — v3.0.1 includes rebranding fixes; no reason to
  use the older patch.

## Decision 2: Migration Strategy

**Decision**: In-place migration using existing PVC. Seerr automatically
migrates Jellyseerr data on first startup.

**Rationale**: Seerr detects existing Jellyseerr configuration in
`/app/config` and performs an automatic database migration. The mount
path (`/app/config`) and port (5055) are identical. No manual database
steps are required. A Longhorn snapshot before deployment provides
rollback safety.

**Alternatives considered**:
- Fresh install with manual data re-entry: Rejected — unnecessary data
  loss and manual effort when automatic migration exists.
- Side-by-side deployment: Rejected — SQLite does not support concurrent
  access, and running two instances adds complexity with no benefit.

## Decision 3: File Permission Handling

**Decision**: Use `fsGroup: 1000` with `fsGroupChangePolicy:
OnRootMismatch` in the pod security context. No init container needed.

**Rationale**: Jellyseerr ran as root, so existing PVC files are
root-owned. Seerr runs as `node` (UID 1000, GID 1000). Kubernetes
`fsGroup` natively handles group ownership on volume mounts.
`OnRootMismatch` detects the ownership mismatch on first startup and
fixes it automatically, avoiding a slow recursive chown on every
subsequent startup.

**Alternatives considered**:
- Init container with `chown -R 1000:1000 /app/config`: Rejected —
  `fsGroup` handles this natively with less manifest complexity and
  better performance on subsequent startups.
- Manual `kubectl exec` chown before migration: Rejected — violates
  "Declarative Everything" principle.

## Decision 4: Health Check Endpoint

**Decision**: Switch from TCP socket probe to HTTP GET on
`/api/v1/status` (port 5055).

**Rationale**: The current Jellyseerr deployment uses `tcpSocket` probes
which only verify the port is open. Seerr exposes `/api/v1/status` as a
proper health endpoint that validates the application is actually
responding. This is a strictly better probe.

**Note**: There is a known issue (#659) where `/api/v1/status` can
timeout during GitHub outages (update check). A 3-second timeout with
a failure threshold of 3+ prevents false-negative restarts.

**Alternatives considered**:
- Keep TCP socket probes: Rejected — less informative, does not verify
  application health.

## Decision 5: Container Security Context

**Decision**: Add container-level security context with `runAsUser:
1000`, `runAsGroup: 1000`, `runAsNonRoot: true`,
`allowPrivilegeEscalation: false`, `drop: ALL` capabilities.

**Rationale**: Seerr's Dockerfile sets `USER node:node` (UID/GID 1000).
Explicitly declaring the security context in the manifest makes the
non-root requirement enforceable by Kubernetes admission controllers and
documents the security posture.

**Alternatives considered**:
- Rely on Dockerfile USER only: Rejected — not enforceable at the
  cluster level and not visible in the manifest.

## Decision 6: Directory and Naming

**Decision**: Keep the app directory at `k8s-apps/media/jellyseerr/`.
Do not rename namespace, service, or ingress resources.

**Rationale**: Renaming the directory would cause ArgoCD to delete the
old `jellyseerr` Application and create a new `seerr` one, potentially
causing downtime and requiring PVC migration between namespaces.
Keeping the existing directory preserves continuity. A cosmetic rename
can be done as a separate follow-up if desired.

**Alternatives considered**:
- Rename directory to `seerr/`: Rejected for this migration — adds risk
  of PVC data loss and ArgoCD application identity change. Can be done
  separately.

## Decision 7: Environment Variables

**Decision**: Keep existing `TZ` and `LOG_LEVEL` environment variables
unchanged. No new environment variables needed.

**Rationale**: Seerr supports the same environment variables as
Jellyseerr. `TZ=America/New_York` and `LOG_LEVEL=info` remain valid.
No new secrets or config maps are required for the migration.
