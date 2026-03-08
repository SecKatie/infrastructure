# Quickstart: Upgrade Jellyseerr to Seerr

**Feature Branch**: `003-upgrade-jellyseerr-seerr`
**Date**: 2026-02-21

## Prerequisites

- `kubectl` access to the cluster
- Access to the Longhorn dashboard (for volume snapshot)
- The `003-upgrade-jellyseerr-seerr` branch merged to `main`

## Deployment Steps

### 1. Take a Longhorn snapshot (before committing)

Navigate to the Longhorn dashboard and create a snapshot of the
`jellyseerr-config-pvc` volume. This provides rollback capability if
the migration fails.

Alternatively via kubectl:

```bash
kubectl get pvc jellyseerr-config-pvc -n jellyseerr -o jsonpath='{.spec.volumeName}'
# Note the volume name, then create a snapshot in Longhorn UI
```

### 2. Commit and push

```bash
git add k8s-apps/media/jellyseerr/jellyseerr.yaml
git commit -m "feat(media): upgrade jellyseerr to seerr v3.0.1"
git push origin main
```

### 3. Verify ArgoCD sync

ArgoCD will detect the deployment change and sync automatically.

```bash
# Check sync status
kubectl get app jellyseerr -n argocd

# Watch the pod rollout
kubectl get pods -n jellyseerr -w
```

The old Jellyseerr pod will terminate and a new Seerr pod will start.
On first startup, Seerr automatically migrates the Jellyseerr database.

### 4. Verify access

```bash
# Health check
curl -s https://jellyseerr.mulliken.net/api/v1/status | python3 -m json.tool

# Internal access
curl -sk https://jellyseerr.corp.mulliken.net/api/v1/status | python3 -m json.tool
```

### 5. Verify migration

1. Navigate to https://jellyseerr.mulliken.net in a browser
2. Log in with your existing credentials
3. Verify:
   - Request history is intact
   - Jellyfin integration is connected
   - Sonarr and Radarr connections are functional
   - User accounts are present

## Validation Checklist

- [ ] Longhorn snapshot taken before deployment
- [ ] Pod is running: `kubectl get pods -n jellyseerr`
- [ ] Health endpoint responds: `curl https://jellyseerr.mulliken.net/api/v1/status`
- [ ] Internal URL works: browser loads jellyseerr.corp.mulliken.net
- [ ] Public URL works: browser loads jellyseerr.mulliken.net
- [ ] TLS certificates valid on both endpoints
- [ ] Existing media requests visible in UI
- [ ] Jellyfin integration functional
- [ ] Sonarr/Radarr connections functional
- [ ] Data persists after pod restart:
  `kubectl rollout restart deployment/jellyseerr -n jellyseerr`

## Rollback

If the migration fails:

1. Revert the commit: `git revert HEAD && git push origin main`
2. Wait for ArgoCD to sync (restores Jellyseerr image)
3. If data is corrupted, restore the Longhorn snapshot taken in step 1
