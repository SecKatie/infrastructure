# Data Model: DynDNS Ingress Migration

**Branch**: `001-dyndns-ingress-migration`
**Date**: 2026-02-19

This feature is infrastructure-only. The "data model" describes
Kubernetes resources and DNS records rather than application entities.

## Kubernetes Resources

### DynDNS Updater (NEW)

**Location**: `k8s-apps/utilities/dyndns-updater/`

| Resource         | Name              | Namespace        | Notes                              |
| ---------------- | ----------------- | ---------------- | ---------------------------------- |
| Namespace        | dyndns-updater    | —                | Dedicated namespace                |
| CronJob          | dyndns-updater    | dyndns-updater   | Runs every 5 minutes              |
| ConfigMap        | dyndns-script     | dyndns-updater   | Shell script for IP check/update  |
| SealedSecret     | dnsimple-credentials | dyndns-updater | API token + account ID            |

**CronJob behavior**:
- Schedule: `*/5 * * * *`
- Container: `alpine/curl` (pinned digest)
- Script: Detect public IP → compare with DNS → update if changed
- Notification: POST to `ntfy.sh/mulliken` on failure
- Failure state tracked via exit code (CronJob `failedJobsHistoryLimit`)

**SealedSecret keys**:
- `DNSIMPLE_TOKEN`: API access token
- `DNSIMPLE_ACCOUNT_ID`: Numeric account ID
- `DNSIMPLE_ZONE`: `mulliken.net`
- `WILDCARD_RECORD_ID`: Record ID for `*.mulliken.net`
- `APEX_RECORD_ID`: Record ID for `mulliken.net` A record

### Personal Site (NEW — migrated from external repo)

**Location**: `k8s-apps/utilities/personal-site/`

| Resource         | Name              | Namespace        | Notes                              |
| ---------------- | ----------------- | ---------------- | ---------------------------------- |
| Namespace        | personal-site     | —                | Already exists in cluster          |
| Deployment       | personal-site     | personal-site    | Go blog, port 80                  |
| Service          | personal-site     | personal-site    | ClusterIP on port 80              |
| Certificate      | personal-site-tls | personal-site    | For mulliken.net                  |
| Ingress          | personal-site     | personal-site    | Routes mulliken.net → service     |

**Deployment details**:
- Image: `quay.io/kmulliken/personal-site` (pinned by digest)
- Port: 80 (named `http`)
- Resources: 10m/32Mi request, 100m/64Mi limit
- Health: liveness `/health` (30s), readiness `/health` (10s)
- Affinity: prefer non-control-plane nodes

### Public Ingress + Certificate (NEW — per existing app)

Added to each app that currently uses a Cloudflare tunnel:

| App        | Ingress Host                  | Backend Service                        | Port  |
| ---------- | ----------------------------- | -------------------------------------- | ----- |
| Jellyfin   | `jellyfin.mulliken.net`       | `jellyfin.jellyfin:8096`               | 8096  |
| Jellyseerr | `jellyseerr.mulliken.net`     | `jellyseerr.jellyseerr:5055`           | 5055  |
| Umami      | `umami.mulliken.net`          | `umami.umami:3000`                     | 3000  |
| Paperless  | `paperless.mulliken.net`      | `paperless.paperless:8000`             | 8000  |

Each gets:
- `public-certificate.yaml`: cert-manager Certificate for `<app>.mulliken.net`
- `public-ingress.yaml`: Traefik Ingress routing the public hostname

### Resources to Remove

| App        | Files to Delete                              | Resources Removed                       |
| ---------- | -------------------------------------------- | --------------------------------------- |
| Jellyfin   | `cloudflare-tunnel.yaml`                     | ConfigMap, Deployment (cloudflared)     |
| Jellyseerr | `cloudflare-tunnel.yaml`                     | ConfigMap, Deployment (cloudflared)     |
| Umami      | `cloudflare-tunnel.yaml`                     | ConfigMap, Deployment (cloudflared)     |
| Paperless  | `tunnel/configmap.yaml`, `tunnel/deployment.yaml` | ConfigMap, Deployment (cloudflared) |

SealedSecrets containing tunnel credentials will also be removed
from each app (the encrypted `*-tunnel-credentials` secrets).

## DNS Records

### Records to Create in DNSimple

| Name       | Type  | Value                | TTL  | Notes                         |
| ---------- | ----- | -------------------- | ---- | ----------------------------- |
| `*`        | A     | (dynamic — public IP) | 300 | Managed by DynDNS updater     |
| (apex)     | A     | (dynamic — public IP) | 300 | Managed by DynDNS updater     |
| (apex)     | MX    | `mail.tutanota.de`   | 3600 | Priority 10                   |
| (apex)     | TXT   | SPF record           | 3600 | `v=spf1 include:spf.tutanota.de -all` |
| (apex)     | TXT   | Tutanota verify      | 3600 | `t-verify=...`                |
| (apex)     | TXT   | Keyoxide             | 3600 | `aspe:keyoxide.org:...`       |
| (apex)     | TXT   | Protonmail verify    | 3600 | `protonmail-verification=...` |
| `_dmarc`   | TXT   | DMARC policy         | 3600 | `v=DMARC1; p=quarantine; adkim=s` |
| `krs._domainkey` | TXT | DKIM RSA key    | 3600 | k=rsa; p=...                  |
| `fm1._domainkey` | CNAME | FM hosted DKIM  | 3600 | fm1.mulliken.net.dkim.fmhosted.com |
| `fm2._domainkey` | CNAME | FM hosted DKIM  | 3600 | fm2.mulliken.net.dkim.fmhosted.com |
| `fm3._domainkey` | CNAME | FM hosted DKIM  | 3600 | fm3.mulliken.net.dkim.fmhosted.com |
| `protonmail._domainkey` | CNAME | Proton DKIM | 3600 | protonmail.domainkey...       |
| `protonmail2._domainkey` | CNAME | Proton DKIM | 3600 | protonmail2.domainkey...     |
| `protonmail3._domainkey` | CNAME | Proton DKIM | 3600 | protonmail3.domainkey...     |
| `s1._domainkey` | CNAME | Tutanota DKIM   | 3600 | s1.domainkey.tutanota.de      |
| `s2._domainkey` | CNAME | Tutanota DKIM   | 3600 | s2.domainkey.tutanota.de      |
| `home`     | CNAME | Nabu Casa            | 3600 | `65b1ny6h...ui.nabu.casa`    |
| `_acme-challenge.home` | CNAME | Nabu Casa ACME | 3600 | ACME for Home Assistant  |
| `links`    | CNAME | Fly.dev              | 3600 | `my-link-blog.fly.dev`        |
| `_acme-challenge.links` | CNAME | Fly ACME    | 3600 | ACME for Links              |
| `tools`    | CNAME | GitHub Pages         | 3600 | `seckatie.github.io`          |
| `_mta-sts` | CNAME | Tutanota MTA-STS     | 3600 | `mta-sts.tutanota.de`         |
| `mta-sts`  | CNAME | Tutanota MTA-STS     | 3600 | `mta-sts.tutanota.de`         |
| `openpgpkey` | CNAME | WKD                | 3600 | `wkd.keys.openpgp.org`        |
| `gemini`   | A     | `136.57.83.9`        | 3600 | Static IP                     |
| `proxy`    | A     | `136.57.83.9`        | 3600 | Static IP                     |
| `status`   | A     | `66.63.163.116`      | 3600 | Static IP (was proxied)       |

### Records to Delete (no DNSimple equivalent)

| Name       | Type  | Notes                                    |
| ---------- | ----- | ---------------------------------------- |
| `jellyfin` | CNAME | Tunnel CNAME → replaced by wildcard A    |
| `jellyseerr` | CNAME | Tunnel CNAME → replaced by wildcard A |
| `umami`    | CNAME | Tunnel CNAME → replaced by wildcard A    |
| `paperless` | CNAME | Tunnel CNAME → replaced by wildcard A   |
| (apex)     | CNAME | Tunnel CNAME → replaced by apex A record |
| `owntracks` | CNAME | Tunnel CNAME → deleted (decommissioned) |

### Cloudflare Zone Resource

The `cloudflare_zone.mulliken_net` resource will be removed entirely.
The domain's nameservers will be changed at the registrar from
Cloudflare to DNSimple.
