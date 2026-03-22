# Repository Guidelines

## Project Structure and Module Organization
- `k8s-manifests/` contains the Argo CD bootstrap and config (projects, ApplicationSets, ingress, certs). The entry point is `k8s-manifests/kustomization.yaml`.
- `k8s-apps/<group>/<app>/` holds Kustomize-managed apps grouped by domain (`media`, `monitoring`, `utilities`). Each app directory should be self-contained with its own `kustomization.yaml` plus supporting manifests.
- `opentofu/` contains DNSimple DNS infrastructure as code (`provider.tf`, `dns.tf`, `versions.tf`, and state files).
- `scripts/` includes kubectl utilities and one-off helpers.
- `justfile` provides shortcuts for OpenTofu and cluster tasks.

## Build, Test, and Development Commands
- `just tf-init` initializes OpenTofu in `opentofu/`.
- `just tf-validate` validates HCL configuration.
- `just tf-plan` previews DNS changes.
- `just tf-apply` applies DNS changes.
- `just tf-fmt` formats HCL files.
- `just dashboard-token` copies the Kubernetes Dashboard admin token (requires `kubectl`).
- If you skip `just`, run the equivalent `tofu` commands from `opentofu/`.

## Coding Style and Naming Conventions
- YAML uses 2-space indentation and consistent `app.kubernetes.io/*` labels.
- App directories and namespaces are lower-case and hyphenated; Argo CD app names come from the directory basename.
- Keep common filenames (`namespace.yaml`, `ingress.yaml`, `certificate.yaml`, `storage.yaml`, `sealedsecret.yaml`, `kustomization.yaml`) so ApplicationSets stay predictable.
- Format HCL with `tofu fmt`; resource names use a `type_name` pattern.

## Testing Guidelines
There is no automated test suite in this repo right now. Validate changes with:
- OpenTofu: `just tf-validate` and `just tf-plan` before any apply.
- Kubernetes: render Kustomize output (for example `kubectl kustomize k8s-apps/media/jellyfin`) and rely on Argo CD sync for rollout checks.

## Commit and Pull Request Guidelines
- Prefer Conventional Commit messages like `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `perf:`, `security:` with optional scopes (for example `feat(argocd): ...`).
- Keep commits scoped to one app or module.
- PRs should describe the change, list affected paths, and note validation performed (for example `just tf-plan` or `kubectl kustomize ...`).

## Security and Configuration Tips
- Store secrets as SealedSecrets; do not commit plaintext credentials.
- Pass credentials via environment variables; avoid committing tokens or editing `.tfstate` by hand.
- Argo CD auto-syncs ApplicationSets, so changes under `k8s-apps/` can deploy quickly.

## Kubernetes App Structure

Each app in `k8s-apps/` follows this pattern:
- `kustomization.yaml` - Kustomize config listing resources
- `namespace.yaml` - Dedicated namespace
- `sealedsecret.yaml` - Encrypted secrets (Sealed Secrets)
- `storage.yaml` - PersistentVolume/PVC definitions
- `certificate.yaml` / `ingress.yaml` - Internal TLS and routing (*.corp.mulliken.net)
- `public-certificate.yaml` / `public-ingress.yaml` - Public TLS and routing (*.mulliken.net)

## External Access Architecture

Services exposed externally use Traefik Ingress with Let's Encrypt TLS:
1. A DynDNS updater CronJob (`k8s-apps/utilities/dyndns-updater/`) keeps wildcard and apex A records in DNSimple current with the cluster's public IP
2. Traefik ingress routes external traffic to services via `public-ingress.yaml` manifests
3. cert-manager issues TLS certificates via DNS-01 challenge using the DNSimple webhook
4. Router port-forwards 80/443 to Traefik NodePorts (HTTP: 31899, HTTPS: 30443)

## Secrets Management

When adding keys to an existing sealed secret, pipe `kubectl get secret` JSON through `jq` directly to `kubeseal`:

```bash
kubectl get secret <name> -n <ns> -o json | \
  jq '.data["new-key"] = "'$(echo -n "VALUE" | base64)'"' | \
  kubeseal --format yaml \
  --controller-name sealed-secrets \
  --controller-namespace kube-system > path/to/sealedsecret.yaml
```

## ArgoCD Application Management

ArgoCD applications are managed via `k8s-manifests/argocd/kustomization.yaml`. There are two patterns:

1. **ApplicationSets** (`applicationsets/`) — auto-generate Applications from directory paths under `k8s-apps/{category}/*`. Used for media, monitoring, utilities, and tools.

2. **Standalone Applications** (`applications/`) — manually listed in `kustomization.yaml`. Used for apps that need multi-source Helm.

**When adding a new standalone Application**: add it to `k8s-manifests/argocd/kustomization.yaml` under the standalone applications section.

## Bitnami Images

Bitnami removed images from `docker.io/bitnami` in late 2025. Use `public.ecr.aws/bitnami/<image>` as the registry override in helm values. Set `global.security.allowInsecureImages: true` since Bitnami charts validate against an approved registry allowlist.

## Configuration Validation

**Never make up configuration options from memory.** Always search and verify against official documentation before adding any config keys to application manifests.
