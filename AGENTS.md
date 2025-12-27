# Repository Guidelines

## Project Structure and Module Organization
- `k8s-manifests/` contains the Argo CD bootstrap and config (projects, ApplicationSets, ingress, certs). The entry point is `k8s-manifests/kustomization.yaml`.
- `k8s-apps/<group>/<app>/` holds Kustomize-managed apps grouped by domain (`media`, `monitoring`, `utilities`). Each app directory should be self-contained with its own `kustomization.yaml` plus supporting manifests.
- `opentofu/` contains Cloudflare DNS infrastructure as code (`provider.tf`, `dns.tf`, `versions.tf`, and state files).
- `scripts/` includes kubectl utilities and one-off helpers.
- `justfile` provides shortcuts for OpenTofu and cluster tasks.

## Build, Test, and Development Commands
- `just tf-init` initializes OpenTofu in `opentofu/`.
- `just tf-validate` validates HCL configuration.
- `just tf-plan` previews DNS changes.
- `just tf-apply` applies DNS changes (requires a Cloudflare token).
- `just tf-fmt` formats HCL files.
- `just dashboard-token` copies the Kubernetes Dashboard admin token (requires `kubectl`).
- If you skip `just`, run the equivalent `tofu` commands from `opentofu/`.

## Coding Style and Naming Conventions
- YAML uses 2-space indentation and consistent `app.kubernetes.io/*` labels.
- App directories and namespaces are lower-case and hyphenated; Argo CD app names come from the directory basename.
- Keep common filenames (`namespace.yaml`, `ingress.yaml`, `certificate.yaml`, `storage.yaml`, `sealedsecret.yaml`, `kustomization.yaml`) so ApplicationSets stay predictable.
- Format HCL with `tofu fmt`; resource names use a `type_name` pattern (for example `a_status`, `cname_home`).

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
- Pass Cloudflare credentials via environment variables; avoid committing tokens or editing `.tfstate` by hand.
- Argo CD auto-syncs ApplicationSets, so changes under `k8s-apps/` can deploy quickly.
