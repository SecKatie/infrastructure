# Quickstart: Install Pocket-ID

**Feature Branch**: `002-install-pocket-id`
**Date**: 2026-02-21

## Prerequisites

- `kubectl` access to the cluster
- `kubeseal` installed locally (for sealing the encryption key)
- Access to the Sealed Secrets controller's public certificate
- The `002-install-pocket-id` branch merged to `main`

## Deployment Steps

### 1. Generate and seal the encryption key

```bash
# Generate a random encryption key
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Create a temporary secret manifest and seal it
kubectl create secret generic pocket-id-secrets \
  --namespace=pocket-id \
  --from-literal=ENCRYPTION_KEY="$ENCRYPTION_KEY" \
  --dry-run=client -o yaml | \
  kubeseal --format yaml \
  --controller-name sealed-secrets \
  --controller-namespace kube-system > k8s-apps/utilities/pocket-id/sealedsecret.yaml
```

**Important**: Save the raw encryption key value somewhere safe (e.g.,
password manager) before sealing. You will need it if you ever need to
reseal the secret or migrate the deployment.

### 2. Commit and push

```bash
git add k8s-apps/utilities/pocket-id/ k8s-manifests/argocd/projects/utilities.yaml
git commit -m "feat(utilities): add pocket-id OIDC provider"
git push origin main
```

### 3. Verify ArgoCD sync

ArgoCD will automatically detect the new directory via the utilities
ApplicationSet and create an Application for pocket-id. Check sync
status:

```bash
# Via ArgoCD CLI (if installed)
argocd app get pocket-id

# Or via kubectl
kubectl get pods -n pocket-id
kubectl get ingress -n pocket-id
```

### 4. Verify access

```bash
# Internal access
curl -k https://pocket-id.corp.mulliken.net/health

# Public access (once DNS propagates)
curl https://auth.mulliken.net/health

# OIDC discovery endpoint
curl https://auth.mulliken.net/.well-known/openid-configuration
```

### 5. Initial setup

1. Navigate to https://auth.mulliken.net in a browser
2. Pocket-ID will prompt you to create the initial admin account
3. Register a passkey (hardware security key or platform authenticator)
4. The admin account can then create OIDC clients for other services

## Validation Checklist

- [ ] Pod is running: `kubectl get pods -n pocket-id`
- [ ] Health endpoint responds: `curl https://auth.mulliken.net/health`
- [ ] OIDC discovery works: `curl https://auth.mulliken.net/.well-known/openid-configuration`
- [ ] TLS certificate is valid (internal): browser shows valid cert for
  pocket-id.corp.mulliken.net
- [ ] TLS certificate is valid (public): browser shows valid cert for
  auth.mulliken.net
- [ ] Admin account created via first-run setup
- [ ] Data persists after pod restart:
  `kubectl rollout restart deployment/pocket-id -n pocket-id`
