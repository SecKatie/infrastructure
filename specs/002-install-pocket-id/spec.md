# Feature Specification: Install Pocket-ID

**Feature Branch**: `002-install-pocket-id`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "Install Pocket-ID OIDC provider in the Kubernetes cluster"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy Pocket-ID to the Cluster (Priority: P1)

As the cluster operator, I want Pocket-ID deployed as a running service
in the Kubernetes cluster so that I have a self-hosted OIDC provider
available for authenticating users to my services.

Pocket-ID is a lightweight OIDC provider that uses passkey-based
authentication. It uses an embedded SQLite database for storage, keeping
the deployment simple with no external database dependency.

**Why this priority**: Without a running Pocket-ID instance, no OIDC
functionality exists. This is the foundational deployment that everything
else depends on.

**Independent Test**: Navigate to the Pocket-ID URL in a browser and
confirm the login page loads. Verify the health endpoint returns a
successful response.

**Acceptance Scenarios**:

1. **Given** the manifests are committed to `main`, **When** ArgoCD
   syncs, **Then** a Pocket-ID pod is running and healthy in its
   dedicated namespace.
2. **Given** Pocket-ID is running, **When** I visit the internal URL
   (pocket-id.corp.mulliken.net), **Then** the Pocket-ID web interface
   loads over HTTPS with a valid TLS certificate.
3. **Given** Pocket-ID is running, **When** the pod restarts, **Then**
   all data (users, OIDC clients, passkeys) persists because the
   database is stored on a persistent volume.
4. **Given** Pocket-ID is running, **When** I check the health endpoint
   (/health), **Then** it returns a successful response.

---

### User Story 2 - Access Pocket-ID Publicly (Priority: P2)

As a user of public services (Paperless, Umami, etc.), I want
Pocket-ID accessible at a public URL so that OIDC login flows work
when I access services from outside the home network.

OIDC authentication requires the browser to redirect to the identity
provider. If public services use Pocket-ID for login, Pocket-ID itself
must also be publicly reachable.

**Why this priority**: Without public access, OIDC flows break for any
service exposed externally. This is needed before any service
integration can work for remote users.

**Independent Test**: From a device outside the home network, navigate
to the public Pocket-ID URL and confirm the login page loads over HTTPS.

**Acceptance Scenarios**:

1. **Given** Pocket-ID is deployed with public ingress, **When** I
   visit auth.mulliken.net from an external network,
   **Then** the Pocket-ID web interface loads over HTTPS with a valid
   Let's Encrypt certificate.
2. **Given** the cluster's public IP changes, **When** the DynDNS
   updater runs, **Then** the Pocket-ID public domain resolves to the
   new IP.

---

### User Story 3 - Register an OIDC Client (Priority: P3)

As the cluster operator, I want to register an OIDC client in
Pocket-ID so that I can configure a self-hosted service to use
Pocket-ID for authentication.

**Why this priority**: This validates that the OIDC provider actually
works end-to-end. Registering a client is the first step toward
integrating any service.

**Independent Test**: Log into the Pocket-ID admin interface using a
passkey, create a new OIDC client, and verify the client ID, client
secret, and redirect URIs are generated and displayed.

**Acceptance Scenarios**:

1. **Given** I am logged into Pocket-ID as an admin, **When** I create
   a new OIDC client with a name and redirect URI, **Then** the client
   is created and I receive a client ID and client secret.
2. **Given** an OIDC client is registered, **When** I visit the
   well-known OIDC discovery endpoint
   (/.well-known/openid-configuration), **Then** it returns valid
   OIDC metadata including authorization, token, and userinfo endpoints.

---

### Edge Cases

- What happens when the persistent volume is full? Pocket-ID should
  continue to serve existing authentication requests; new user
  registration may fail gracefully with an error message.
- What happens when the pod is evicted and rescheduled? Data must
  survive pod rescheduling because it is stored on a persistent volume
  independent of the pod lifecycle.
- What happens when the encryption key secret is missing or incorrect?
  Pocket-ID should fail to start with a clear error in logs rather than
  silently corrupting data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Pocket-ID MUST run as a single-replica deployment in a
  dedicated namespace following the established app directory convention.
- **FR-002**: Pocket-ID data (SQLite database, passkey data) MUST be
  persisted on a persistent volume that survives pod restarts and
  rescheduling.
- **FR-003**: The Pocket-ID encryption key MUST be stored as a Sealed
  Secret; it MUST NOT appear in plaintext in the repository.
- **FR-004**: Pocket-ID MUST be accessible internally via HTTPS at
  pocket-id.corp.mulliken.net with a valid TLS certificate.
- **FR-005**: Pocket-ID MUST be accessible publicly via HTTPS at a
  public domain with a valid Let's Encrypt TLS certificate.
- **FR-006**: The deployment MUST be managed by ArgoCD via the existing
  utilities ApplicationSet, requiring no manual `kubectl` commands to
  deploy or update.
- **FR-007**: Pocket-ID MUST expose a health endpoint that can be used
  for liveness and readiness probes.
- **FR-008**: Pocket-ID MUST use SQLite as its database backend (no
  external database dependency).
- **FR-009**: The public domain for Pocket-ID MUST be included in the
  DynDNS updater's managed records so it stays current with the
  cluster's public IP.

### Key Entities

- **Pocket-ID Instance**: The running OIDC provider service; stores
  user accounts, passkeys, OIDC client registrations, and session data
  in its embedded SQLite database.
- **OIDC Client**: A registered application that can use Pocket-ID for
  authentication; identified by client ID and client secret, scoped to
  specific redirect URIs and user groups.
- **Encryption Key**: A secret used by Pocket-ID to encrypt private
  keys and sensitive data at rest. Must be generated once and persisted
  securely.

### Assumptions

- Pocket-ID will be placed under `k8s-apps/utilities/pocket-id/`
  following the standard app directory convention.
- SQLite is preferred over PostgreSQL per the "Minimal Moving Parts"
  principle—no separate database pod is needed.
- Longhorn is the appropriate storage class for the SQLite database
  (small, single-node access, consistent with other utility apps).
- User signups will be disabled by default; the operator will create
  the initial admin account via the first-run setup flow.
- The existing `utilities` ArgoCD project and ApplicationSet will
  automatically pick up the new app directory.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pocket-ID is accessible and returns a login page within
  60 seconds of ArgoCD completing its sync.
- **SC-002**: The OIDC discovery endpoint
  (/.well-known/openid-configuration) returns valid metadata.
- **SC-003**: Data persists across pod restarts—a user or OIDC client
  created before a restart is still present after the pod comes back.
- **SC-004**: The public URL is reachable from outside the home network
  over HTTPS with a valid certificate.
- **SC-005**: No plaintext secrets exist in the Git repository; all
  sensitive values are sealed.
