# Tasks: Upgrade Jellyseerr to Seerr

**Input**: Design documents from `/specs/003-upgrade-jellyseerr-seerr/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not requested in specification. US3 is manual post-deployment validation.

**Organization**: Tasks are grouped by user story. This is a focused
migration — only one manifest file changes. Phases reflect the
logical progression from pre-migration safety through deployment
and verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Pre-Migration Safety

**Purpose**: Ensure rollback capability before making any changes.

- [x] T001 Take Longhorn snapshot of jellyseerr-config-pvc volume via Longhorn dashboard

**Checkpoint**: Snapshot exists. Rollback to Jellyseerr state is possible if migration fails.

---

## Phase 2: User Story 1 - Migrate Jellyseerr to Seerr (Priority: P1)

**Goal**: Seerr running in the cluster with all Jellyseerr data
automatically migrated.

**Independent Test**: Visit jellyseerr.mulliken.net and confirm the
Seerr interface loads with existing media requests and integrations
intact.

- [x] T002 [US1] Update deployment image, container name, security context, and health probes in k8s-apps/media/jellyseerr/jellyseerr.yaml
- [x] T003 [US1] Validate Kustomize build succeeds by running kustomize build k8s-apps/media/jellyseerr/

**Checkpoint**: Manifest updated and valid. Ready to deploy.

---

## Phase 3: Deploy and Verify

**Purpose**: Commit, push, and verify the migration succeeds
end-to-end. This covers US1, US2, and US3 validation.

> **PAUSE**: Stop automated execution here. The operator must commit
> to main and wait for ArgoCD to sync before verification can begin.

- [x] T004 Commit updated manifest to main and push
- [x] T005 [US1] Verify Seerr pod is running and healthy in the jellyseerr namespace
- [x] T006 [US1] Verify automatic data migration completed (check pod logs for migration messages)
- [x] T007 [US2] Verify internal URL responds at https://jellyseerr.corp.mulliken.net
- [x] T008 [US2] Verify public URL responds at https://jellyseerr.mulliken.net
- [x] T009 [US1] Verify health endpoint returns valid response at https://jellyseerr.mulliken.net/api/v1/status
- [x] T010 [US1] Verify existing media requests are visible in the Seerr UI
- [x] T011 [US1] Verify Jellyfin, Sonarr, and Radarr integrations are functional
- [x] T012 [US3] Verify data persists after pod restart by running kubectl rollout restart deployment/jellyseerr -n jellyseerr

**Checkpoint**: Seerr is fully operational. All user stories validated.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Pre-Migration (Phase 1)**: No dependencies — must complete first
- **User Story 1 (Phase 2)**: Depends on Phase 1 (snapshot taken)
- **Deploy and Verify (Phase 3)**: MANUAL PAUSE — operator must
  commit to main, wait for ArgoCD sync, then verify

### User Story Dependencies

- **User Story 1 (P1)**: Core migration — T002 modifies the manifest
- **User Story 2 (P2)**: No manifest changes needed — ingress and
  certificates are unchanged. Verified in T007/T008 after deploy.
- **User Story 3 (P3)**: Post-deployment validation only — T012

### Parallel Opportunities

```text
# Phase 3: After ArgoCD sync completes
T007: Verify internal URL     (can run in parallel)
T008: Verify public URL       (can run in parallel)
T009: Verify health endpoint  (can run in parallel)
# Then sequential verification
T010: Check media requests in UI
T011: Check integrations
T012: Pod restart persistence test (must be last)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Take Longhorn snapshot
2. Complete Phase 2: Update manifest, validate build
3. **PAUSE**: Commit to main, wait for ArgoCD sync
4. Verify T005, T006, T009, T010, T011 — Seerr is running with
   migrated data

### Full Delivery

1. Complete Phase 1 (snapshot)
2. Complete Phase 2 (manifest update + validate)
3. **PAUSE**: Commit to main, push, ArgoCD syncs
4. Complete Phase 3 (all verification tasks T005–T012)

---

## Notes

- Only one file is modified: `k8s-apps/media/jellyseerr/jellyseerr.yaml`
- T001 (Longhorn snapshot) has already been completed during the
  planning phase.
- All verification tasks (T005–T012) require the deployment to be
  live in the cluster. They cannot be run locally.
- US2 requires no manifest changes — the existing ingress and
  certificates continue to work unchanged.
- Rollback: `git revert HEAD && git push origin main` restores
  Jellyseerr. If data is corrupted, restore the Longhorn snapshot.
