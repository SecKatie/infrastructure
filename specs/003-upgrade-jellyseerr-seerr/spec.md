# Feature Specification: Upgrade Jellyseerr to Seerr

**Feature Branch**: `003-upgrade-jellyseerr-seerr`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "Upgrade Jellyseerr to Seerr"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Migrate Jellyseerr to Seerr (Priority: P1)

As the cluster operator, I want to replace the Jellyseerr deployment
with Seerr so that I am running the actively maintained successor
before Jellyseerr reaches end-of-life at the end of March 2026.

Jellyseerr and Overseerr have officially merged into Seerr (v3.0.x),
a unified media request management tool. Seerr automatically migrates
existing Jellyseerr data (users, requests, settings, Jellyfin/Sonarr/
Radarr connections) on first startup when it detects an existing
configuration directory.

**Why this priority**: Jellyseerr is being deprecated. Without
migrating, the service will stop receiving updates and security
patches. This is the core migration that everything else depends on.

**Independent Test**: After deploying the updated manifests and ArgoCD
syncing, visit the Seerr web interface and confirm it loads, existing
media requests are present, and Jellyfin/Sonarr/Radarr integrations
are functional.

**Acceptance Scenarios**:

1. **Given** the updated manifests are committed to `main`, **When**
   ArgoCD syncs, **Then** a Seerr pod is running and healthy in its
   namespace.
2. **Given** Seerr has started for the first time, **When** it detects
   the existing Jellyseerr configuration, **Then** it automatically
   migrates all data (users, requests, settings, integrations) without
   manual intervention.
3. **Given** Seerr is running, **When** I visit the web interface,
   **Then** all previously configured Jellyfin, Sonarr, and Radarr
   connections are intact and functional.
4. **Given** Seerr is running, **When** I check the request history,
   **Then** all previous media requests from Jellyseerr are present.

---

### User Story 2 - Access Seerr at Existing URLs (Priority: P2)

As a user of the media request system, I want to continue accessing
the service at the same URLs so that my bookmarks and habits are not
disrupted by the migration.

**Why this priority**: Maintaining URL continuity avoids confusion for
users who have bookmarked the existing Jellyseerr addresses. The
internal and public endpoints should continue to work.

**Independent Test**: Navigate to both the internal and public URLs
and confirm the Seerr interface loads over HTTPS with valid TLS
certificates.

**Acceptance Scenarios**:

1. **Given** Seerr is deployed, **When** I visit the internal URL
   (jellyseerr.corp.mulliken.net), **Then** the Seerr web interface
   loads over HTTPS with a valid TLS certificate.
2. **Given** Seerr is deployed, **When** I visit the public URL
   (jellyseerr.mulliken.net) from an external network, **Then** the
   Seerr web interface loads over HTTPS with a valid Let's Encrypt
   certificate.

---

### User Story 3 - Data Persistence Across Restarts (Priority: P3)

As the cluster operator, I want to confirm that Seerr's data survives
pod restarts so that the migration is durable and production-ready.

**Why this priority**: This validates that the migration is not just
a one-time success but persists correctly with the new container's
user permissions and storage configuration.

**Independent Test**: Restart the Seerr pod and confirm all data
(users, requests, settings) is still present afterward.

**Acceptance Scenarios**:

1. **Given** Seerr is running with migrated data, **When** the pod is
   restarted, **Then** all users, requests, settings, and integrations
   are preserved.
2. **Given** the Seerr container runs as a non-root user, **When** the
   pod starts, **Then** it has correct permissions to read and write
   the configuration volume.

---

### Edge Cases

- What happens if the Longhorn volume still has root-owned files from
  Jellyseerr? Seerr runs as non-root (UID 1000) and will fail to
  start if it cannot write to the configuration directory. File
  ownership must be corrected before or during the first startup.
- What happens if the automatic database migration fails? The pod
  should show clear errors in logs. A Longhorn snapshot taken before
  migration allows rollback to the previous Jellyseerr state.
- What happens if Seerr's health check endpoint differs from
  Jellyseerr's? Probes must be updated to match the new application's
  health endpoint to avoid unnecessary pod restarts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Jellyseerr deployment MUST be replaced with Seerr
  using the official container image, pinned to a specific version.
- **FR-002**: The existing Longhorn PVC MUST be reused so that
  Jellyseerr's SQLite database and configuration are available for
  automatic migration.
- **FR-003**: The Seerr container MUST run as a non-root user
  (UID 1000) with appropriate security context and file permissions.
- **FR-004**: The existing internal and public ingress endpoints MUST
  continue to work at the same hostnames (jellyseerr.corp.mulliken.net
  and jellyseerr.mulliken.net).
- **FR-005**: A Longhorn volume snapshot MUST be taken before the
  migration to enable rollback if migration fails.
- **FR-006**: Health check probes MUST be updated to use the correct
  endpoint for Seerr.
- **FR-007**: The deployment MUST be managed by ArgoCD via the existing
  media ApplicationSet, requiring no manual `kubectl` commands to
  deploy or update.

### Key Entities

- **Seerr Instance**: The running media request management service;
  succeeds Jellyseerr with the same functionality plus unified
  Overseerr features. Stores users, media requests, and integration
  settings in an embedded SQLite database.
- **Configuration Volume**: The existing Longhorn PVC containing the
  SQLite database, settings, and cache. Mounted at `/app/config` in
  both Jellyseerr and Seerr containers.

### Assumptions

- The existing Longhorn PVC (`jellyseerr-config-pvc`, 5Gi) will be
  reused. No new volume is needed.
- Seerr's automatic migration handles the Jellyseerr-to-Seerr data
  transition without manual database steps.
- The app directory will remain at `k8s-apps/media/jellyseerr/` to
  preserve ArgoCD application identity and avoid unnecessary churn.
  Renaming is a cosmetic change that can be done separately.
- The port remains 5055, so the Service manifest needs no port changes.
- DNS is handled by existing wildcard records; no DNS changes are
  needed.
- File ownership correction (chown to UID 1000) can be handled via an
  init container in the deployment manifest.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Seerr pod is running and healthy within 60 seconds of
  ArgoCD completing its sync.
- **SC-002**: All existing media requests from Jellyseerr are visible
  in the Seerr interface after migration.
- **SC-003**: Jellyfin, Sonarr, and Radarr integrations are functional
  without reconfiguration.
- **SC-004**: Both internal and public URLs serve the Seerr interface
  over HTTPS with valid certificates.
- **SC-005**: Data persists across pod restarts — requests and settings
  created before a restart are still present afterward.
- **SC-006**: No plaintext secrets exist in the Git repository (no new
  secrets are introduced by this migration).
