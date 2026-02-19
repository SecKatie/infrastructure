# Research: DynDNS Ingress Migration

**Date**: 2026-02-19
**Branch**: `001-dyndns-ingress-migration`

## R1: DNSimple OpenTofu Provider

**Decision**: Use `dnsimple/dnsimple ~> 2.0` provider (already declared
in `opentofu/versions.tf`).

**Rationale**: The provider is already in the project's required
providers block. It supports all needed record types (A, CNAME, MX,
TXT) via the `dnsimple_zone_record` resource.

**Alternatives considered**:
- Manual API calls: Less auditable, no state tracking.
- Different DNS provider: DNSimple was explicitly chosen by the user.

**Key details**:
- Authentication requires `token` (API access token) and `account`
  (account ID) in the provider block.
- Records use `dnsimple_zone_record` with fields: `zone_name`, `name`,
  `type`, `value`, `ttl`, `priority`.
- For apex/root records, use `name = ""` (empty string).
- For wildcard records, use `name = "*"`.
- TXT records are normalized per RFC --- use exact values to avoid
  state drift.
- The `dnsimple_zone` data source is deprecated; use the resource.

**HCL pattern**:
```hcl
resource "dnsimple_zone_record" "wildcard" {
  zone_name = "mulliken.net"
  name      = "*"
  type      = "A"
  value     = "MANAGED_BY_DYNDNS"  # placeholder, managed externally
  ttl       = 300
}
```

Note: The wildcard and apex A records will be initially created in
OpenTofu but their `value` will be managed by the DynDNS updater at
runtime. OpenTofu lifecycle `ignore_changes` on `value` will prevent
drift.

## R2: DynDNS Updater Approach

**Decision**: Custom CronJob with a shell script using curl to call
the DNSimple API and ntfy.sh for notifications.

**Rationale**: Simpler, more auditable, and more maintainable than
pulling in a third-party container. The DNSimple API is straightforward
REST, and the entire updater logic fits in ~30 lines of shell. Matches
the project's preference for minimal dependencies.

**Alternatives considered**:
- `oleduc/dnsimple-dynamic-dns`: Python-based, heavier image, YAML
  config. Overkill for updating two records.
- `benwyrosdick/dnsimple-ddns`: Uses basic auth (email/password)
  instead of API tokens. Less secure.
- Kubernetes ExternalDNS: Designed for service-based DNS, not public
  IP tracking. Wrong tool for this job.

**Implementation approach**:
- CronJob runs every 5 minutes.
- Script detects public IP via `https://ifconfig.me` (with fallback
  to `https://icanhazip.com`).
- Compares against current DNSimple record value via API GET.
- If different, updates both wildcard and apex A records via API PATCH.
- On failure, sends POST to `https://ntfy.sh/mulliken` with error
  details.
- Tracks failure state to avoid duplicate notifications (uses a small
  emptyDir volume to persist state between retries within a job).

**DNSimple API endpoints**:
```
GET    /v2/{account}/zones/{zone}/records        # List records
PATCH  /v2/{account}/zones/{zone}/records/{id}   # Update record
```

**Container**: `alpine/curl` (minimal Alpine image with curl and sh).

## R3: TLS Certificate Strategy

**Decision**: Use existing cert-manager with `letsencrypt-prod`
ClusterIssuer and HTTP-01 challenges for public hostnames.

**Rationale**: HTTP-01 challenges will work once ports 80/443 are
forwarded to the cluster. This reuses the existing infrastructure
with zero additional configuration. Each public service gets its own
Certificate resource for its specific hostname.

**Alternatives considered**:
- DNS-01 challenges via DNSimple: Would require a cert-manager
  webhook for DNSimple. More complex, no benefit for single-hostname
  certs.
- Wildcard certificate via DNS-01: Single cert for *.mulliken.net.
  Requires DNS-01 solver. The apex domain (mulliken.net) would need
  a separate cert anyway since wildcards don't cover the apex.

## R4: Public Ingress Strategy

**Decision**: Add separate ingress and certificate resources for
public hostnames alongside existing internal `.corp.mulliken.net`
resources.

**Rationale**: Keeps internal and public access independent. Internal
ingresses continue working unchanged. Public ingresses can be added
and removed without affecting internal access.

**Affected apps and their public hostnames**:
- Jellyfin: `jellyfin.mulliken.net` → `jellyfin.jellyfin:8096`
- Jellyseerr: `jellyseerr.mulliken.net` → `jellyseerr.jellyseerr:5055`
- Umami: `umami.mulliken.net` → `umami.umami:3000`
- Paperless: `paperless.mulliken.net` → `paperless.paperless:8000`
- Personal site: `mulliken.net` → `personal-site.personal-site:80`

## R5: Personal-Site Migration

**Decision**: Create manifests in `k8s-apps/utilities/personal-site/`
in the infrastructure repo. Update the ArgoCD application to point to
the new local path instead of the external GitHub repo.

**Rationale**: Brings the personal-site under the same management
pattern as all other apps. The external repo (`SecKatie/personal-site`)
contains the Go source code; the k8s manifests belong in the
infrastructure repo.

**Current state** (from cluster inspection):
- Deployment: `personal-site` in namespace `personal-site`, port 80
- Service: ClusterIP on port 80
- Also running: `cloudflared` deployment (to be removed)
- ArgoCD app: `k8s-manifests/argocd/applications/personal-site.yaml`
  currently points to `SecKatie/personal-site.git` path `k8s`

**Action**: Extract deployment/service spec from running cluster,
create manifests, update ArgoCD application source path.

## R6: DNS Migration Ordering

**Decision**: Migrate DNS records to DNSimple in OpenTofu before
the tunnel removal cutover. The nameserver change for mulliken.net
(from Cloudflare to DNSimple) is a manual step at the domain
registrar.

**Rationale**: DNS propagation for nameserver changes can take up to
48 hours. By migrating the records in OpenTofu first and then changing
nameservers, we minimize the window where records might be missing.

**Sequence**:
1. Create all records in DNSimple via OpenTofu (additive).
2. Change nameservers at registrar from Cloudflare to DNSimple.
3. Wait for propagation.
4. Remove Cloudflare resources from OpenTofu.

## R7: Constitution Amendment Required

**Decision**: Principle V of the constitution must be amended to
replace the Cloudflare Tunnels requirement with the new ingress-based
external access pattern.

**Current text** (violating gate):
> External access MUST use Cloudflare Tunnels with TLS; direct
> NodePort or LoadBalancer exposure is forbidden for public services.

**Proposed amendment**:
> External access MUST use Kubernetes Ingress with TLS certificates
> managed by cert-manager. Direct NodePort or LoadBalancer exposure
> is forbidden for public services.

**Security Requirements** also needs update:
> All external traffic MUST terminate TLS at the Cloudflare edge or
> at an ingress controller with a valid certificate.

Should become:
> All external traffic MUST terminate TLS at an ingress controller
> with a valid certificate.
