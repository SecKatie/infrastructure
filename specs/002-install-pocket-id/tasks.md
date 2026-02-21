# Tasks: Install Pocket-ID

**Input**: Design documents from `/specs/002-install-pocket-id/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not requested in specification. US3 is manual post-deployment validation.

**Organization**: Tasks are grouped by user story. All manifest files
are written before the kustomization.yaml activates them for ArgoCD.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create directory structure and enable ArgoCD to deploy to
the new namespace.

- [x] T001 Create pocket-id app directory at k8s-apps/utilities/pocket-id/
- [x] T002 Add pocket-id namespace to ArgoCD utilities project allowed destinations in k8s-manifests/argocd/projects/utilities.yaml

**Checkpoint**: Directory exists and ArgoCD is authorized to deploy into the pocket-id namespace.

---

## Phase 2: Foundational (Shared Resources)

**Purpose**: Create resources shared across all user stories. These must
exist before the deployment or ingress manifests reference them.

- [x] T003 [P] Create namespace manifest in k8s-apps/utilities/pocket-id/namespace.yaml
- [x] T004 [P] Create ConfigMap with Pocket-ID configuration in k8s-apps/utilities/pocket-id/configmap.yaml
- [x] T005 [P] Create Longhorn PVC for SQLite persistence in k8s-apps/utilities/pocket-id/storage.yaml
- [x] T006 [P] Create SealedSecret placeholder for encryption key in k8s-apps/utilities/pocket-id/sealedsecret.yaml

**Checkpoint**: All shared resources defined. Deployment can reference ConfigMap, Secret, and PVC.

---

## Phase 3: User Story 1 - Deploy Pocket-ID to the Cluster (Priority: P1)

**Goal**: Pocket-ID running in the cluster, accessible internally at
pocket-id.corp.mulliken.net over HTTPS.

**Independent Test**: Visit pocket-id.corp.mulliken.net in a browser and
confirm the login page loads. Curl the /health endpoint and confirm a
successful response.

- [x] T007 [P] [US1] Create Deployment manifest in k8s-apps/utilities/pocket-id/deployment.yaml
- [x] T008 [P] [US1] Create ClusterIP Service manifest in k8s-apps/utilities/pocket-id/service.yaml
- [x] T009 [P] [US1] Create internal TLS Certificate in k8s-apps/utilities/pocket-id/certificate.yaml
- [x] T010 [US1] Create internal Ingress in k8s-apps/utilities/pocket-id/ingress.yaml

**Checkpoint**: Core deployment, service, and internal ingress defined. Pocket-ID is internally accessible after ArgoCD sync.

---

## Phase 4: User Story 2 - Access Pocket-ID Publicly (Priority: P2)

**Goal**: Pocket-ID accessible at auth.mulliken.net over HTTPS with a
valid Let's Encrypt certificate.

**Independent Test**: From an external network, visit
auth.mulliken.net and confirm the login page loads over HTTPS.

- [x] T011 [P] [US2] Create public TLS Certificate in k8s-apps/utilities/pocket-id/public-certificate.yaml
- [x] T012 [US2] Create public Ingress in k8s-apps/utilities/pocket-id/public-ingress.yaml

**Checkpoint**: Public ingress defined. auth.mulliken.net resolves (via existing wildcard) and serves Pocket-ID after ArgoCD sync.

---

## Phase 5: Finalize

**Purpose**: Create the Kustomize root that ties all resources together
and validate the build.

- [x] T013 Create kustomization.yaml listing all resources in k8s-apps/utilities/pocket-id/kustomization.yaml
- [x] T014 Validate Kustomize build succeeds by running kustomize build k8s-apps/utilities/pocket-id/

**Checkpoint**: `kustomize build` produces valid combined YAML with placeholder secret.

---

## Phase 6: Seal Secret (MANUAL — requires operator)

**Purpose**: Replace the placeholder SealedSecret with a real sealed
encryption key. This MUST happen before committing to main.

> **PAUSE**: Stop automated execution here. The operator must run
> `kubeseal` with access to the cluster's Sealed Secrets controller.
> See quickstart.md for the exact command.

- [x] T015 Generate and seal the real encryption key using kubeseal, replacing k8s-apps/utilities/pocket-id/sealedsecret.yaml
- [x] T016 Re-validate Kustomize build succeeds after replacing sealedsecret.yaml

**Checkpoint**: Real sealed secret in place. All manifests are valid and ready to commit.

---

## Phase 7: User Story 3 - Register an OIDC Client (Priority: P3)

**Goal**: Verify Pocket-ID works end-to-end by creating the admin
account and registering a test OIDC client.

**Independent Test**: Log into the admin interface, create an OIDC
client, and confirm the discovery endpoint returns valid metadata.

> **PAUSE**: This phase is post-deployment manual validation. It requires
> the manifests to be committed to main and ArgoCD to complete sync.

- [x] T017 [US3] Verify health endpoint responds at https://auth.mulliken.net/health
- [x] T018 [US3] Verify OIDC discovery endpoint returns valid metadata at https://auth.mulliken.net/.well-known/openid-configuration
- [ ] T019 [US3] Complete initial admin account setup and register a test OIDC client via https://auth.mulliken.net

**Checkpoint**: Pocket-ID is fully operational. OIDC clients can be registered for service integration.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on T001 (directory exists)
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion (ConfigMap, PVC, Secret exist)
- **User Story 2 (Phase 4)**: Depends on T008 (Service must exist for ingress backend)
- **Finalize (Phase 5)**: Depends on Phases 3 and 4 (all resources must exist to list them)
- **Seal Secret (Phase 6)**: MANUAL PAUSE — operator must run kubeseal before committing
- **User Story 3 (Phase 7)**: Depends on Phase 6 committed to main and ArgoCD sync complete

### Parallel Opportunities

```text
# Phase 2: All foundational resources in parallel
T003: namespace.yaml
T004: configmap.yaml
T005: storage.yaml
T006: sealedsecret.yaml

# Phase 3: Deployment, Service, and Certificate in parallel
T007: deployment.yaml
T008: service.yaml
T009: certificate.yaml
# Then T010 (ingress references certificate and service)

# Phase 4: Certificate and ingress in parallel with Phase 3
T011: public-certificate.yaml
# Then T012 (public ingress references certificate and service)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (directory + ArgoCD project)
2. Complete Phase 2: Foundational (namespace, configmap, storage, secret)
3. Complete Phase 3: User Story 1 (deployment, service, internal cert/ingress)
4. Complete Phase 5: Finalize (kustomization.yaml, validate build)
5. **STOP and VALIDATE**: Commit, sync, verify internal access works

### Full Delivery

1. Complete Phases 1–4 (all manifests with placeholder secret)
2. Complete Phase 5 (kustomization.yaml, validate build)
3. **PAUSE** for Phase 6: Operator seals real encryption key, re-validates
4. Commit to main, push, wait for ArgoCD sync
5. **PAUSE** for Phase 7: Operator validates health, OIDC, creates admin account

---

## Notes

- T006 creates a SealedSecret placeholder. Phase 6 (T015) replaces it
  with the real sealed key BEFORE committing to main.
- T013 (kustomization.yaml) is the activation point — ArgoCD will not
  deploy anything until this file exists and lists the resources.
- FR-009 (DynDNS) is already satisfied by the existing wildcard A
  record for *.mulliken.net. No DynDNS changes are needed.
- All [P] tasks within the same phase can be written in parallel.
- Two manual pause points: Phase 6 (seal secret) and Phase 7 (post-deploy validation).
- Commit only after Phase 6 completes for a single atomic deployment.
