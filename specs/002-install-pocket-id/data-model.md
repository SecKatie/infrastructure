# Data Model: Install Pocket-ID

**Feature Branch**: `002-install-pocket-id`
**Date**: 2026-02-21

## Overview

Pocket-ID manages its own data model internally via an embedded SQLite
database. This feature does not define custom entities — Pocket-ID's
schema is managed by the application itself. This document describes the
Kubernetes resource entities that make up the deployment.

## Kubernetes Resources

### Namespace: pocket-id

Dedicated namespace isolating all Pocket-ID resources from other apps.

- **Labels**: `app.kubernetes.io/name: pocket-id`,
  `app.kubernetes.io/part-of: utilities`,
  `app.kubernetes.io/managed-by: argocd`

### ConfigMap: pocket-id-config

Non-secret Pocket-ID configuration variables. Having a dedicated
ConfigMap makes it easy to add or change settings without modifying the
deployment manifest.

- `APP_URL` = `https://auth.mulliken.net`
- `PORT` = `1411`
- `ALLOW_USER_SIGNUPS` = `disabled`

### Deployment: pocket-id

Single-replica deployment running the Pocket-ID container.

- **Image**: `ghcr.io/pocket-id/pocket-id:v2.2.0`
- **Port**: 1411 (HTTP)
- **Replicas**: 1
- **Volume mount**: `/data` → PVC for SQLite database persistence
- **Environment source**: `envFrom` referencing both
  `pocket-id-config` (ConfigMap) and `pocket-id-secrets` (Secret)
- **Probes**: HTTP GET `/health` on port 1411
- **Resources**: 50m-250m CPU, 128Mi-256Mi memory
- **Node affinity**: Prefer non-control-plane nodes

### Service: pocket-id

ClusterIP service exposing port 80 → target port 1411.

### PersistentVolumeClaim: pocket-id-data

- **Storage class**: longhorn
- **Access mode**: ReadWriteOnce
- **Size**: 2Gi

### SealedSecret: pocket-id-secrets

Encrypted secret containing:
- `encryption-key`: Generated encryption key for Pocket-ID's internal
  data protection

### Certificate: pocket-id-tls (internal)

- **Issuer**: letsencrypt-prod (ClusterIssuer)
- **DNS name**: pocket-id.corp.mulliken.net

### Ingress: pocket-id (internal)

- **Class**: traefik
- **Host**: pocket-id.corp.mulliken.net
- **TLS secret**: pocket-id-tls
- **Backend**: pocket-id service, port 80

### Certificate: pocket-id-public-tls (public)

- **Issuer**: letsencrypt-prod (ClusterIssuer)
- **DNS name**: auth.mulliken.net

### Ingress: pocket-id-public (public)

- **Class**: traefik
- **Host**: auth.mulliken.net
- **TLS secret**: pocket-id-public-tls
- **Backend**: pocket-id service, port 80

## External Dependency: ArgoCD Project

The `utilities` ArgoCD project at
`k8s-manifests/argocd/projects/utilities.yaml` must include
`pocket-id` in its allowed destination namespaces.
