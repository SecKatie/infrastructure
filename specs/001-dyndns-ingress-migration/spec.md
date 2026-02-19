# Feature Specification: DynDNS Ingress Migration

**Feature Branch**: `001-dyndns-ingress-migration`
**Created**: 2026-02-19
**Status**: Draft
**Input**: Migrate from Cloudflare tunnels to DynDNS with ingresses.
Port forwards for 80/443 to the cluster, a job running on the cluster
that does DynDNS updates to DNSimple, a wildcard A record pointing to
the cluster public IP, and ingresses managing domain-to-service routing.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic DNS Updates (Priority: P1)

As the cluster operator, when my ISP-assigned public IP changes, DNS
records MUST automatically update so that all publicly-exposed services
remain reachable without manual intervention.

This is the foundational capability. Without accurate DNS pointing at
the cluster's current public IP, no external access works at all.

**Why this priority**: Everything else depends on DNS resolving to the
correct IP. This is the single prerequisite for the entire migration.

**Independent Test**: Deploy only the DynDNS updater. Verify that
the wildcard A record in DNSimple reflects the cluster's actual public
IP, and that it updates within the target window after an IP change.

**Acceptance Scenarios**:

1. **Given** the DynDNS updater is running and the cluster's public IP
   has not changed, **When** the updater runs its check cycle, **Then**
   no DNS update is issued and the existing A record remains unchanged.
2. **Given** the cluster's public IP changes, **When** the updater
   detects the new IP, **Then** the wildcard A record in DNSimple is
   updated to the new IP within the configured interval.
3. **Given** the DNSimple API is temporarily unreachable, **When** the
   updater attempts an update, **Then** it retries on subsequent cycles
   without crashing or losing track of the current IP.
4. **Given** a DNS update fails, **When** the updater detects the
   failure, **Then** the operator receives a notification via
   ntfy.sh/mulliken describing the failure.

---

### User Story 2 - Public Service Access via Ingress (Priority: P2)

As an end user, I can access Jellyfin, Jellyseerr, Umami, Paperless,
and the personal site (mulliken.net) at their existing public URLs
with valid TLS certificates, routed through standard Kubernetes
ingress instead of Cloudflare tunnels.

**Why this priority**: This delivers the core migration value ---
services remain externally accessible but through a simpler, provider-
independent architecture. Depends on P1 (DNS pointing to the cluster).

**Independent Test**: With the DynDNS updater running from P1 and port
forwards in place, add ingress resources for each public service.
Verify HTTPS access from outside the local network using the public
domain names. Confirm valid TLS certificates are served.

**Acceptance Scenarios**:

1. **Given** DNS resolves *.mulliken.net to the cluster IP and port
   forwards are active, **When** a user navigates to
   `https://jellyfin.mulliken.net`, **Then** the request is routed to
   the Jellyfin service and the page loads with a valid TLS certificate.
2. **Given** the same infrastructure, **When** a user navigates to
   `https://paperless.mulliken.net`, **Then** the request reaches the
   Paperless service with a valid TLS certificate.
3. **Given** the apex A record resolves mulliken.net to the cluster IP,
   **When** a user navigates to `https://mulliken.net`, **Then** the
   request is routed to the personal-site service and the page loads
   with a valid TLS certificate.
4. **Given** a service is temporarily down, **When** a user accesses
   its public URL, **Then** the ingress returns an appropriate error
   page rather than a connection timeout.

---

### User Story 3 - Cloudflare Tunnel Removal (Priority: P3)

As the cluster operator, after confirming public ingress access works,
all Cloudflare tunnel deployments, ConfigMaps, SealedSecrets, and
associated DNS CNAME records are removed so that no dead infrastructure
remains.

**Why this priority**: Cleanup depends on P2 being validated. Removing
tunnels before confirming ingress works would cause an outage.

**Independent Test**: After completing P2, remove all tunnel resources.
Verify that no cloudflared pods are running, no tunnel ConfigMaps
exist, and the previously tunneled services remain accessible via
ingress.

**Acceptance Scenarios**:

1. **Given** all public services are confirmed accessible via ingress,
   **When** Cloudflare tunnel deployments are removed, **Then** zero
   cloudflared pods run in the cluster.
2. **Given** tunnel CNAME records are removed from DNS configuration,
   **When** DNS is queried for any *.mulliken.net subdomain, **Then**
   the wildcard A record responds (no stale CNAMEs).
3. **Given** tunnel SealedSecrets are removed, **When** the cluster
   state is inspected, **Then** no tunnel credential secrets exist.

---

### User Story 4 - DNS Provider Migration (Priority: P4)

As the cluster operator, DNS management for mulliken.net transitions
entirely from Cloudflare to DNSimple in the OpenTofu configuration,
including all non-tunnel records (MX, SPF, DKIM, DMARC, external
CNAMEs).

**Why this priority**: This completes the full separation from
Cloudflare. It can proceed in parallel with P3 but is lower priority
since tunnels are the primary target.

**Independent Test**: After migrating DNS records in OpenTofu, run
`just tf-plan` and `just tf-apply`. Verify that email delivery still
works (MX/SPF/DKIM/DMARC), external service CNAMEs resolve correctly,
and no records remain in Cloudflare configuration.

**Acceptance Scenarios**:

1. **Given** all DNS records are defined in OpenTofu targeting
   DNSimple, **When** `just tf-plan` is run, **Then** no Cloudflare
   resources appear in the plan.
2. **Given** MX, SPF, DKIM, and DMARC records are migrated, **When**
   an email is sent to the domain, **Then** it is delivered correctly.
3. **Given** external CNAME records (home, links, tools) are migrated,
   **When** their URLs are accessed, **Then** they resolve to the
   correct external services.

---

### Edge Cases

- What happens when the public IP changes while a user is mid-session?
  Existing TCP connections are unaffected; new connections use the
  updated DNS. Brief window of stale DNS is expected (bounded by TTL).
- What happens if the DynDNS updater pod is evicted or the node
  reboots? The updater MUST be scheduled to restart automatically.
  Missed update cycles are recovered on the next successful run.
- What happens if cert-manager cannot complete a TLS challenge? The
  service remains accessible via HTTP (if configured) or shows a
  certificate error. The operator is alerted via existing monitoring.
- What happens if port forwards on the router are misconfigured? No
  external traffic reaches the cluster. This is an out-of-scope
  manual prerequisite.
- What happens to the apex domain (mulliken.net)? The apex domain
  serves the personal-site application (a Go blog at
  personal-site.personal-site:80). An apex A record and ingress
  MUST route mulliken.net to this service. Note: a wildcard A record
  does NOT cover the apex --- both records are required.
- What happens to owntracks.mulliken.net? OwnTracks is dead. The
  Cloudflare tunnel CNAME MUST be removed during DNS migration with
  no replacement.

## Clarifications

### Session 2026-02-19

- Q: What observability is needed for the DynDNS updater? → A: Alert
  on missed updates via ntfy.sh/mulliken to notify operator of failures.
- Q: Should tunnels and ingress run in parallel during migration? →
  A: No. Big-bang cutover --- remove all tunnels at once after ingress
  is set up. Brief potential outage is accepted.
- Q: Is loss of Cloudflare DDoS protection / origin IP hiding an
  accepted tradeoff? → A: Yes. Accepted tradeoff, no mitigation
  needed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST run a job on the cluster that detects the
  cluster's public IP and updates both a wildcard A record
  (*.mulliken.net) and an apex A record (mulliken.net) in DNSimple.
- **FR-002**: The DynDNS updater MUST check for IP changes at a
  regular interval (no longer than every 5 minutes).
- **FR-003**: The DynDNS updater MUST store DNSimple API credentials
  as a SealedSecret --- never in plaintext.
- **FR-004**: Both the wildcard A record (*.mulliken.net) and the apex
  A record (mulliken.net) in DNSimple MUST resolve to the cluster's
  current public IP.
- **FR-005**: DNS TTL for both A records MUST be set low enough
  (300 seconds or less) to minimize stale-IP windows after changes.
- **FR-006**: Ingress resources MUST be created for each publicly-
  exposed service: Jellyfin, Jellyseerr, Umami, Paperless on their
  respective *.mulliken.net hostnames, and the personal site on the
  apex domain (mulliken.net).
- **FR-013**: Personal-site Kubernetes manifests (namespace, deployment,
  service, ingress, certificate) MUST be added to `k8s-apps/` in the
  infrastructure repo, replacing the current external ArgoCD
  application source. The cloudflared sidecar in the personal-site
  namespace MUST be removed.
- **FR-014**: The owntracks.mulliken.net CNAME record MUST be deleted
  with no replacement (service is decommissioned).
- **FR-007**: Each public ingress MUST serve a valid TLS certificate
  for its hostname.
- **FR-008**: All Cloudflare tunnel Deployments, ConfigMaps, and
  SealedSecrets MUST be removed from the cluster manifests in a
  single big-bang cutover after all ingress resources are deployed.
  A brief outage window during cutover is acceptable.
- **FR-009**: All Cloudflare tunnel CNAME records MUST be removed from
  the OpenTofu DNS configuration.
- **FR-010**: All non-tunnel DNS records (MX, SPF, DKIM, DMARC,
  external CNAMEs) MUST be migrated from Cloudflare to DNSimple in
  OpenTofu.
- **FR-011**: The OpenTofu provider MUST change from Cloudflare to
  DNSimple for DNS management.
- **FR-012**: The DynDNS updater MUST be resilient to transient API
  failures (retry on next cycle without crashing).
- **FR-015**: The DynDNS updater MUST send a notification via
  ntfy.sh/mulliken when a DNS update fails, so the operator is
  alerted to potential service disruption.
- **FR-016**: The DynDNS updater MUST NOT send duplicate notifications
  for the same ongoing failure (notify once, then again only after
  recovery and a new failure).

### Key Entities

- **DynDNS Updater**: A workload running on the cluster responsible
  for detecting the public IP and updating DNSimple. Attributes:
  check interval, DNSimple API credentials, target record.
- **DNS A Records**: Two A records in DNSimple --- a wildcard
  (*.mulliken.net) for subdomains and an apex (mulliken.net) for the
  bare domain --- both resolving to the cluster's public IP.
- **Public Ingress**: Kubernetes Ingress resources routing external
  traffic from public hostnames to internal services with TLS
  termination. One per externally-exposed service.
- **TLS Certificate**: Per-hostname certificate issued by a trusted
  CA, managed by the cluster's certificate infrastructure.

### Assumptions

- The home router supports port forwarding for ports 80 and 443 to a
  stable internal cluster IP. This is a manual, out-of-scope
  prerequisite.
- Moving from Cloudflare tunnels to direct port forwarding removes
  DDoS protection and exposes the cluster's public IP. This is an
  accepted tradeoff.
- The existing Traefik ingress controller and cert-manager with the
  letsencrypt-prod ClusterIssuer will be reused for public ingress
  and TLS.
- cert-manager can issue certificates via HTTP-01 challenges once
  ports 80/443 are forwarded, or DNS-01 challenges can be configured
  for DNSimple if needed.
- The internal `.corp.mulliken.net` ingress resources remain unchanged
  and continue to function for local network access.
- DNSimple account and API token are already available or will be
  provisioned outside this feature's scope.
- External services (home.mulliken.net via Nabu Casa,
  links.mulliken.net, tools.mulliken.net) use CNAME records that
  point elsewhere and do not require cluster routing.
- The personal-site is currently deployed from
  `SecKatie/personal-site.git` via ArgoCD. Its manifests will be
  brought into the infrastructure repo under `k8s-apps/` and the
  ArgoCD application source updated accordingly.
- OwnTracks is decommissioned and its DNS record will be deleted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: DNS changes propagate within 5 minutes of a public IP
  change, as verified by querying the wildcard A record.
- **SC-002**: All five migrated services (Jellyfin, Jellyseerr, Umami,
  Paperless, and the personal site at mulliken.net) are accessible at
  their public URLs with valid TLS certificates from outside the local
  network.
- **SC-003**: Zero cloudflared pods running in the cluster after
  migration is complete.
- **SC-004**: `just tf-plan` shows no Cloudflare resources --- all DNS
  is managed via DNSimple.
- **SC-005**: Email delivery to the domain continues to work (MX, SPF,
  DKIM, DMARC records intact in DNSimple).
- **SC-006**: The DynDNS updater recovers automatically from transient
  failures without operator intervention.
