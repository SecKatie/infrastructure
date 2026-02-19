# Tasks: DynDNS Ingress Migration

**Input**: Design documents from `/specs/001-dyndns-ingress-migration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable
independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Constitution amendment and OpenTofu provider configuration

- [x] T001 Amend constitution Principle V in .specify/memory/constitution.md: replace "External access MUST use Cloudflare Tunnels with TLS" with "External access MUST use Kubernetes Ingress with TLS certificates managed by cert-manager". Also update Security Requirements to remove "at the Cloudflare edge or" from the TLS termination rule. Bump version to 1.1.0 (MINOR). See research.md R7 for exact wording.
- [x] T002 Add DNSimple provider block to opentofu/provider.tf with token and account variables sourced from environment variables (DNSIMPLE_TOKEN, DNSIMPLE_ACCOUNT). Mark token as sensitive in a new opentofu/variables.tf file.

---

## Phase 2: Foundational (DNS Provider Migration — Blocking)

**Purpose**: Migrate ALL DNS records from Cloudflare to DNSimple in
OpenTofu. This MUST complete before any user story can proceed because
DNS must resolve via DNSimple for ingress and DynDNS to function.

**CRITICAL**: No user story work can begin until nameservers are
changed and DNS propagation is confirmed.

- [x] T003 Rewrite opentofu/dns.tf replacing all `cloudflare_dns_record` resources with `dnsimple_zone_record` equivalents per data-model.md. Create wildcard A (`name = "*"`) and apex A (`name = ""`) records with TTL 300 and `lifecycle { ignore_changes = [value] }`. Create all email records (MX, SPF, DKIM, DMARC, TXT) and external CNAMEs (home, links, tools, mta-sts, openpgpkey) with TTL 3600. Create static A records (gemini, proxy, status). Do NOT create tunnel CNAMEs (jellyfin, jellyseerr, umami, paperless, apex CNAME, owntracks). Remove the `cloudflare_zone` resource entirely.
- [x] T004 Remove Cloudflare provider from opentofu/versions.tf (delete the `cloudflare` entry from `required_providers`). Remove Cloudflare provider block from opentofu/provider.tf.
- [x] T005 Run `just tf-fmt` to format all OpenTofu files in opentofu/
- [x] T006 Run `just tf-validate` and `just tf-plan` to preview changes. Verify plan shows only DNSimple resources and no Cloudflare resources.
- [ ] T007 Run `just tf-apply` to create all DNSimple DNS records.
- [ ] T008 Change nameservers for mulliken.net at the domain registrar from Cloudflare to DNSimple. This is a manual step. Document the nameserver values in a commit message.
- [ ] T009 Validate DNS propagation: verify `dig mulliken.net` and `dig anything.mulliken.net` return the expected IP. Verify `dig MX mulliken.net` returns mail.tutanota.de. Verify external CNAMEs resolve correctly.

**Checkpoint**: DNS fully managed by DNSimple. All records resolve. Email works.

---

## Phase 3: User Story 1 — Automatic DNS Updates (Priority: P1)

**Goal**: A CronJob on the cluster detects the public IP and keeps
the wildcard + apex A records in DNSimple current.

**Independent Test**: Run the CronJob manually. Verify DNSimple records
match the cluster's public IP. Check ntfy.sh/mulliken for failure
notifications.

### Implementation for User Story 1

- [x] T010 [US1] Create namespace manifest in k8s-apps/utilities/dyndns-updater/namespace.yaml for the `dyndns-updater` namespace. Follow existing pattern from k8s-apps/media/jellyfin/namespace.yaml with labels `app.kubernetes.io/name: dyndns-updater`, `app.kubernetes.io/part-of: utilities`, `app.kubernetes.io/managed-by: argocd`.
- [x] T011 [P] [US1] Create ConfigMap with the DynDNS update shell script in k8s-apps/utilities/dyndns-updater/configmap.yaml. Script must: (1) detect public IP via `https://ifconfig.me` with fallback to `https://icanhazip.com`, (2) GET current record value from DNSimple API, (3) compare IPs, (4) if different PATCH both wildcard and apex A records, (5) on any failure POST to `https://ntfy.sh/mulliken` with error details and exit non-zero, (6) track failure state to avoid duplicate notifications. See contracts/dnsimple-api.md for API details.
- [x] T012 [P] [US1] Create SealedSecret placeholder in k8s-apps/utilities/dyndns-updater/sealedsecret.yaml for `dnsimple-credentials` with keys: DNSIMPLE_TOKEN, DNSIMPLE_ACCOUNT_ID, DNSIMPLE_ZONE, WILDCARD_RECORD_ID, APEX_RECORD_ID. Use existing SealedSecret pattern from k8s-apps/media/jellyfin/sealedsecret.yaml. Note: actual sealed values must be generated with `kubeseal` at deploy time.
- [x] T013 [US1] Create CronJob manifest in k8s-apps/utilities/dyndns-updater/cronjob.yaml. Schedule `*/5 * * * *`. Container `alpine/curl` (pin to specific digest). Mount ConfigMap as script, SealedSecret as env vars. Set resource requests 10m/32Mi, limits 50m/64Mi. Security context: runAsNonRoot true, runAsUser 1000. Set `failedJobsHistoryLimit: 3`, `successfulJobsHistoryLimit: 1`. Prefer non-control-plane nodes via affinity.
- [x] T014 [US1] Create kustomization.yaml in k8s-apps/utilities/dyndns-updater/kustomization.yaml listing namespace.yaml, sealedsecret.yaml, configmap.yaml, cronjob.yaml as resources with `namespace: dyndns-updater`.
- [x] T015 [US1] ~~Create ArgoCD Application manifest~~ — superseded by existing `utility-apps` ApplicationSet which auto-discovers all `k8s-apps/utilities/*` directories. No individual Application manifest needed.
- [x] T016 [US1] Validate: verify CronJob is scheduled (`kubectl get cronjob -n dyndns-updater`), trigger a manual job run, check logs confirm IP detection and DNS comparison, verify DNSimple records match public IP.

**Checkpoint**: DynDNS updater running. DNS A records stay current automatically.

---

## Phase 4: User Story 2 — Public Service Access via Ingress (Priority: P2)

**Goal**: Jellyfin, Jellyseerr, Umami, Paperless, and the personal
site are accessible at their public *.mulliken.net URLs via Traefik
ingress with valid TLS certificates.

**Independent Test**: From outside the local network, `curl -sI
https://jellyfin.mulliken.net` returns 200 with a valid cert. Repeat
for all 5 services.

### Implementation for User Story 2

- [x] T017 [P] [US2] Create public-certificate.yaml and public-ingress.yaml for Jellyfin in k8s-apps/media/jellyfin/. Certificate: name `jellyfin-public-tls`, issuerRef `letsencrypt-prod` ClusterIssuer, dnsName `jellyfin.mulliken.net`. Ingress: host `jellyfin.mulliken.net`, ingressClassName `traefik`, annotation `traefik.ingress.kubernetes.io/router.entrypoints: websecure`, TLS secretName `jellyfin-public-tls`, backend service `jellyfin` port 8096. Update k8s-apps/media/jellyfin/kustomization.yaml to add both new files to resources list.
- [x] T018 [P] [US2] Create public-certificate.yaml and public-ingress.yaml for Jellyseerr in k8s-apps/media/jellyseerr/. Certificate for `jellyseerr.mulliken.net`, ingress routing to service `jellyseerr` port 5055. Update k8s-apps/media/jellyseerr/kustomization.yaml to add both new files.
- [x] T019 [P] [US2] Create public-certificate.yaml and public-ingress.yaml for Umami in k8s-apps/utilities/umami/. Certificate for `umami.mulliken.net`, ingress routing to service `umami` port 3000. Update k8s-apps/utilities/umami/kustomization.yaml to add both new files.
- [x] T020 [P] [US2] Create public-certificate.yaml and public-ingress.yaml for Paperless in k8s-apps/utilities/paperless/. Certificate for `paperless.mulliken.net`, ingress routing to service `paperless` port 8000. Update k8s-apps/utilities/paperless/kustomization.yaml to add both new files.
- [x] T021 [US2] Create personal-site manifests in k8s-apps/utilities/personal-site/. Create: namespace.yaml (namespace `personal-site`), deployment.yaml (image `quay.io/kmulliken/personal-site` pinned by digest `sha256:8512e1451392ddf57adde2e20c808df2938fb15685172135502647f4ecf6346a`, port 80 named `http`, resources 10m/32Mi req 100m/64Mi limit, liveness `/health` 30s, readiness `/health` 10s, prefer non-control-plane), service.yaml (ClusterIP port 80 targetPort `http`), certificate.yaml (name `personal-site-tls`, dnsName `mulliken.net`, issuerRef `letsencrypt-prod`), ingress.yaml (host `mulliken.net`, ingressClassName `traefik`, websecure entrypoint, TLS secret `personal-site-tls`, backend `personal-site` port 80), kustomization.yaml listing all resources with `namespace: personal-site`.
- [x] T022 [US2] Update ArgoCD application in k8s-manifests/argocd/applications/personal-site.yaml: change source repoURL to the infrastructure repo URL, change source path to `k8s-apps/utilities/personal-site`, keep all other settings (project, destination, syncPolicy).
- [ ] T023 [US2] Validate public access per quickstart.md: `curl -sI https://jellyfin.mulliken.net`, `curl -sI https://jellyseerr.mulliken.net`, `curl -sI https://umami.mulliken.net`, `curl -sI https://paperless.mulliken.net`, `curl -sI https://mulliken.net`. Verify all return valid TLS certificates via `openssl s_client`. Run from outside the local network.

**Checkpoint**: All 5 services accessible via public URLs with valid TLS.

---

## Phase 5: User Story 3 — Cloudflare Tunnel Removal (Priority: P3)

**Goal**: All Cloudflare tunnel infrastructure removed from the
cluster. Zero cloudflared pods running.

**Independent Test**: `kubectl get pods --all-namespaces | grep
cloudflared` returns nothing. All public services still accessible.

### Implementation for User Story 3

- [x] T024 [P] [US3] Delete k8s-apps/media/jellyfin/cloudflare-tunnel.yaml. Remove `cloudflare-tunnel.yaml` from k8s-apps/media/jellyfin/kustomization.yaml resources list. Remove tunnel-credentials SealedSecret from k8s-apps/media/jellyfin/sealedsecret.yaml (if it only contains tunnel creds, delete the file and remove from kustomization; if it contains other secrets, remove only the tunnel-credentials entry).
- [x] T025 [P] [US3] Delete k8s-apps/media/jellyseerr/cloudflare-tunnel.yaml. Remove from k8s-apps/media/jellyseerr/kustomization.yaml. Remove tunnel-credentials SealedSecret.
- [x] T026 [P] [US3] Delete k8s-apps/utilities/umami/cloudflare-tunnel.yaml. Remove from k8s-apps/utilities/umami/kustomization.yaml. Remove tunnel-credentials SealedSecret.
- [x] T027 [P] [US3] Delete k8s-apps/utilities/paperless/tunnel/ directory (configmap.yaml and deployment.yaml). Remove tunnel kustomization reference from k8s-apps/utilities/paperless/kustomization.yaml. Remove tunnel-credentials SealedSecret.
- [x] T028 [US3] Remove cloudflared deployment from personal-site namespace. Since personal-site manifests are now in k8s-apps/utilities/personal-site/ (created in T021), ensure no cloudflared resources are included. ArgoCD prune will remove the orphaned cloudflared deployment automatically.
- [ ] T029 [US3] Validate: `kubectl get pods --all-namespaces | grep cloudflared` returns nothing. `kubectl get configmaps --all-namespaces | grep cloudflared` returns nothing. `kubectl get secrets --all-namespaces | grep tunnel-credentials` returns nothing. All 5 public services remain accessible.

**Checkpoint**: Zero Cloudflare tunnel infrastructure in the cluster.

---

## Phase 6: User Story 4 — DNS Cleanup (Priority: P4)

**Goal**: Verify clean DNS state. No Cloudflare references remain in
OpenTofu. Email and external services work.

**Independent Test**: `just tf-plan` shows no changes. Email delivery
works. All external CNAMEs resolve.

### Implementation for User Story 4

- [ ] T030 [US4] Run `just tf-plan` to verify no Cloudflare resources remain and state is clean. If any drift detected (e.g., from DynDNS updater changing A record values), verify it's expected and that lifecycle ignore_changes is working.
- [ ] T031 [US4] Validate email by checking DNS records: `dig MX mulliken.net`, `dig TXT mulliken.net` (SPF), `dig TXT _dmarc.mulliken.net` (DMARC), `dig CNAME fm1._domainkey.mulliken.net` (DKIM). Optionally send a test email to verify delivery.
- [ ] T032 [US4] Validate external services: `dig CNAME home.mulliken.net` (Nabu Casa), `dig CNAME links.mulliken.net` (Fly.dev), `dig CNAME tools.mulliken.net` (GitHub Pages). Verify each URL loads correctly.

**Checkpoint**: DNS fully migrated. Email works. All services operational.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates and final validation

- [ ] T033 Update CLAUDE.md: replace "External Access" section describing Cloudflare Tunnels with the new architecture (DynDNS + Ingress). Update the Architecture section if needed. Remove any references to cloudflared or Cloudflare Tunnels.
- [ ] T034 Run full validation per quickstart.md: DynDNS updater check, all 5 public services, zero cloudflared pods, clean tf-plan, email DNS, internal .corp.mulliken.net access unchanged.
- [ ] T035 Run `kustomize build` on all modified app directories to verify manifests are valid: k8s-apps/media/jellyfin, k8s-apps/media/jellyseerr, k8s-apps/utilities/umami, k8s-apps/utilities/paperless, k8s-apps/utilities/dyndns-updater, k8s-apps/utilities/personal-site.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T002 provider config) — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 (DNS records must exist in DNSimple)
- **US2 (Phase 4)**: Depends on Phase 2 (DNS must resolve) and Phase 3 (DynDNS updater keeps records current)
- **US3 (Phase 5)**: Depends on Phase 4 (public ingress validated before tunnel removal)
- **US4 (Phase 6)**: Depends on Phase 2 (already mostly done) — can run in parallel with Phase 5
- **Polish (Phase 7)**: Depends on all previous phases

### Within Each Phase

- Tasks marked [P] within a phase can run in parallel
- T017-T020 (public ingress per app) are all parallelizable
- T024-T027 (tunnel removal per app) are all parallelizable
- Non-[P] tasks must run sequentially within their phase

### Parallel Opportunities

```text
# Phase 4: All public ingress tasks can run in parallel:
T017 (Jellyfin), T018 (Jellyseerr), T019 (Umami), T020 (Paperless)

# Phase 5: All tunnel removal tasks can run in parallel:
T024 (Jellyfin), T025 (Jellyseerr), T026 (Umami), T027 (Paperless)

# Phase 3: ConfigMap and SealedSecret can run in parallel:
T011 (script ConfigMap), T012 (SealedSecret)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (constitution, provider)
2. Complete Phase 2: Foundational (DNS migration, nameservers)
3. Complete Phase 3: User Story 1 (DynDNS updater)
4. **STOP and VALIDATE**: Verify DNS records update automatically
5. This alone delivers automatic DNS management even before ingress

### Incremental Delivery

1. Setup + Foundational → DNS managed by DNSimple
2. Add US1 → DynDNS updater keeps records current
3. Add US2 → All 5 services accessible via public ingress (MVP!)
4. Add US3 → Tunnels removed, clean cluster
5. Add US4 → Verify clean state, email works
6. Polish → Documentation, final validation

### Commit Strategy

This migration benefits from splitting into multiple commits:
1. `docs: amend constitution for ingress-based external access`
2. `feat(opentofu): migrate DNS from Cloudflare to DNSimple`
3. `feat(dyndns): add DynDNS updater CronJob for DNSimple`
4. `feat(ingress): add public ingress for externally-exposed services`
5. `feat(personal-site): migrate manifests to infrastructure repo`
6. `refactor: remove Cloudflare tunnel infrastructure`
7. `docs: update CLAUDE.md for new architecture`

---

## Notes

- Router port forwards (80/443 → cluster) are a manual prerequisite
- SealedSecrets must be generated with `kubeseal` at deploy time
- Nameserver change at registrar is manual (T008)
- DNS propagation after nameserver change may take up to 48 hours
- The big-bang tunnel removal (Phase 5) may cause a brief outage
- All [P] tasks operate on different files with no dependencies
