# Research: Install Pocket-ID

**Feature Branch**: `002-install-pocket-id`
**Date**: 2026-02-21

## Decision: Container Image & Version

- **Decision**: Use `ghcr.io/pocket-id/pocket-id:v2.2.0` (latest release,
  published 2026-01-11)
- **Rationale**: Official image from the Pocket-ID project. Pinning to a
  specific tag ensures reproducible deployments.
- **Alternatives considered**: Using `latest` tag (rejected — breaks
  reproducibility and could introduce breaking changes on pod restart).

## Decision: Database Backend

- **Decision**: SQLite (embedded, default)
- **Rationale**: Pocket-ID stores its database at `data/pocket-id.db` by
  default. SQLite eliminates the need for a separate PostgreSQL pod,
  aligning with the "Minimal Moving Parts" constitution principle.
  Personal infrastructure with a single operator does not need
  PostgreSQL's concurrency capabilities.
- **Alternatives considered**: PostgreSQL (rejected — adds a second
  deployment, PVC, and service with no benefit at this scale).

## Decision: Storage Backend

- **Decision**: Longhorn PVC, 2Gi, ReadWriteOnce
- **Rationale**: Consistent with how other small stateful utility apps
  (Redis for Paperless, Victoria Metrics) use Longhorn. SQLite database
  files are small; 2Gi is generous for an OIDC provider with a handful
  of users and clients. ReadWriteOnce is appropriate since Pocket-ID
  runs as a single replica.
- **Alternatives considered**: NFS (rejected — overkill for a small
  database file; NFS is used for large document storage like Paperless).

## Decision: DynDNS Updater Changes

- **Decision**: No changes required
- **Rationale**: The DynDNS updater maintains a wildcard A record for
  `*.mulliken.net`. The subdomain `auth.mulliken.net` is automatically
  covered by this wildcard record. FR-009 from the spec is already
  satisfied by the existing infrastructure.
- **Alternatives considered**: Adding a dedicated A record for
  auth.mulliken.net (rejected — redundant with wildcard).

## Decision: ArgoCD Project Configuration

- **Decision**: Add `pocket-id` namespace to the utilities project's
  allowed destinations in
  `k8s-manifests/argocd/projects/utilities.yaml`
- **Rationale**: The utilities ArgoCD project explicitly lists allowed
  namespaces rather than using a wildcard. Without adding `pocket-id`,
  ArgoCD will refuse to sync resources into the new namespace.
- **Alternatives considered**: Using a wildcard namespace (rejected —
  breaks least-privilege principle and is inconsistent with existing
  configuration).

## Decision: Application Structure

- **Decision**: Flat directory structure (no subdirectories) under
  `k8s-apps/utilities/pocket-id/`
- **Rationale**: Pocket-ID is a single-container application with no
  external database or cache dependencies. A flat structure (like
  personal-site or umami) is simpler than a hierarchical one (like
  paperless). The ApplicationSet auto-discovers directories under
  `k8s-apps/utilities/*` so no ArgoCD application manifest is needed.
- **Alternatives considered**: Hierarchical structure with app/ and
  secrets/ subdirectories (rejected — unnecessary complexity for a
  single-container app).

## Decision: Pocket-ID Configuration

- **Decision**: Store non-secret configuration in a ConfigMap
  (`pocket-id-config`) and secret values in a SealedSecret
  (`pocket-id-secrets`). The deployment references both via `envFrom`.
- **Rationale**: APP_URL must match the public URL for OIDC redirect
  validation to work correctly. Disabling signups ensures only the
  operator can create accounts. A ConfigMap makes it easy to add or
  change Pocket-ID configuration variables in the future without
  touching the deployment manifest. The encryption key protects private
  keys at rest and must not be in plaintext.
- **Alternatives considered**: Inline env vars in the deployment
  (rejected — harder to expand configuration over time; a ConfigMap
  provides a single place to manage all non-secret settings).

## Decision: Resource Requests/Limits

- **Decision**: Requests: 50m CPU, 128Mi memory.
  Limits: 250m CPU, 256Mi memory.
- **Rationale**: Pocket-ID is a lightweight Go application serving a
  small number of users. Resource profile is comparable to umami
  (light utility app). Can be adjusted upward if monitoring shows
  resource pressure.
- **Alternatives considered**: Higher limits like paperless (rejected —
  paperless runs OCR and document processing; Pocket-ID only handles
  authentication requests).

## Decision: Internal Domain

- **Decision**: `pocket-id.corp.mulliken.net` for internal access
- **Rationale**: Follows the established `{app}.corp.mulliken.net`
  convention for internal services.
- **Alternatives considered**: `auth.corp.mulliken.net` (rejected —
  internal hostname should match the app directory name per convention).
