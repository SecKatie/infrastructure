# observability_perses

Deploys [Perses](https://perses.dev), a CNCF sandbox project for observability visualization, as a Grafana replacement.

## Why Perses?

- **Apache 2.0 License**: Truly open source (vs Grafana's AGPL)
- **GitOps-native**: Dashboard-as-code with CUE/Go SDKs
- **Lightweight**: Single Go binary, minimal resource usage
- **CNCF backed**: Active development, Prometheus ecosystem focused
- **Migration tools**: Built-in Grafana dashboard migration via `percli`

## Requirements

- Kubernetes cluster (K3s)
- Longhorn storage class
- cert-manager with `letsencrypt-prod` ClusterIssuer
- Victoria Metrics or Prometheus-compatible datasource
- Traefik ingress controller

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `perses_namespace` | `monitoring` | Kubernetes namespace |
| `perses_image` | `persesdev/perses:v0.50.0-distroless` | Container image |
| `perses_cpu_request` | `50m` | CPU request |
| `perses_cpu_limit` | `200m` | CPU limit |
| `perses_memory_request` | `64Mi` | Memory request |
| `perses_memory_limit` | `128Mi` | Memory limit |
| `perses_storage_size` | `5Gi` | Persistent storage size |
| `perses_storage_class` | `longhorn` | Storage class |
| `perses_ingress_enabled` | `true` | Enable ingress |
| `perses_ingress_host` | `perses.corp.mulliken.net` | Ingress hostname |
| `perses_tls_secret_name` | `perses-tls` | TLS certificate secret |
| `perses_prometheus_url` | `http://victoria-metrics.monitoring.svc.cluster.local:8428` | Prometheus-compatible datasource URL |
| `perses_prometheus_name` | `VictoriaMetrics` | Datasource display name |
| `perses_anonymous_access` | `true` | Allow anonymous read access |

## Usage

```bash
# Deploy Perses
ansible-playbook -i inventory playbooks/observability.yml --tags perses

# Deploy full observability stack
ansible-playbook -i inventory playbooks/observability.yml
```

## Access

- **HTTPS**: `https://perses.corp.mulliken.net`
- **Port-forward**: `kubectl -n monitoring port-forward svc/perses 8080:8080`

## Creating Dashboards

Perses supports multiple methods for creating dashboards:

1. **Web UI**: Create dashboards directly in the Perses interface
2. **Dashboard-as-Code**: Use CUE or Go SDKs
3. **CLI**: Use `percli` to manage dashboards
4. **Migrate from Grafana**: Use `percli migrate` to convert Grafana dashboards

### Migrating Grafana Dashboards

```bash
# Install percli
brew install perses/tap/percli

# Migrate a Grafana dashboard JSON file
percli migrate --input grafana-dashboard.json --output perses-dashboard.json

# Apply to Perses
percli apply -f perses-dashboard.json
```

## Resources

- [Perses Documentation](https://perses.dev)
- [Perses GitHub](https://github.com/perses/perses)
- [Perses CLI (percli)](https://perses.dev/perses/docs/cli/)
