# Quickstart: DynDNS Ingress Migration Validation

**Branch**: `001-dyndns-ingress-migration`

## Prerequisites

- [ ] Router port forwards configured: 80 → cluster, 443 → cluster
- [ ] DNSimple account with API token
- [ ] `kubeseal` CLI installed (for creating SealedSecrets)
- [ ] Domain nameservers changed from Cloudflare to DNSimple
- [ ] OpenTofu DNS records applied via `just tf-apply`

## Validation Steps

### 1. DynDNS Updater

```bash
# Verify the CronJob is scheduled
kubectl get cronjob -n dyndns-updater

# Check recent job runs
kubectl get jobs -n dyndns-updater --sort-by=.metadata.creationTimestamp

# Check logs of the most recent job
kubectl logs -n dyndns-updater job/$(kubectl get jobs -n dyndns-updater \
  --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')

# Verify DNS resolves to your current public IP
dig +short mulliken.net
dig +short anything.mulliken.net
curl -s https://ifconfig.me
# All three should return the same IP
```

### 2. Public Ingress & TLS

```bash
# Test each public service (from outside the local network, or
# use a phone on cellular data)
curl -sI https://jellyfin.mulliken.net | head -5
curl -sI https://jellyseerr.mulliken.net | head -5
curl -sI https://umami.mulliken.net | head -5
curl -sI https://paperless.mulliken.net | head -5
curl -sI https://mulliken.net | head -5

# Verify TLS certificates are valid
echo | openssl s_client -connect jellyfin.mulliken.net:443 -servername jellyfin.mulliken.net 2>/dev/null | openssl x509 -noout -dates

# Check certificate resources in cluster
kubectl get certificates --all-namespaces | grep mulliken.net
```

### 3. Cloudflare Tunnel Removal

```bash
# Verify zero cloudflared pods
kubectl get pods --all-namespaces | grep cloudflared
# Should return nothing

# Verify no tunnel ConfigMaps remain
kubectl get configmaps --all-namespaces | grep cloudflared
# Should return nothing

# Verify no tunnel secrets remain
kubectl get secrets --all-namespaces | grep tunnel-credentials
# Should return nothing
```

### 4. DNS Provider Migration

```bash
# Verify no Cloudflare resources in OpenTofu
just tf-plan
# Should show no changes (all clean)

# Verify email DNS records
dig +short MX mulliken.net
dig +short TXT mulliken.net
dig +short TXT _dmarc.mulliken.net

# Verify external service CNAMEs
dig +short CNAME home.mulliken.net
dig +short CNAME links.mulliken.net
dig +short CNAME tools.mulliken.net
```

### 5. Internal Access Unchanged

```bash
# Verify .corp.mulliken.net ingresses still work
curl -sk https://jellyfin.corp.mulliken.net | head -1
curl -sk https://headlamp.corp.mulliken.net | head -1
```

### 6. Notification Test

```bash
# Trigger a test notification (temporarily break DNS update)
# Or check ntfy.sh/mulliken subscription for any alerts
```

## Rollback Plan

If the migration fails:

1. Change nameservers back to Cloudflare at the registrar.
2. Re-apply the Cloudflare DNS records via OpenTofu
   (`git revert` the DNS migration commit, then `just tf-apply`).
3. Re-add cloudflare-tunnel.yaml files to the affected apps
   (`git revert` the tunnel removal commit).
4. ArgoCD will sync the tunnel deployments back automatically.
