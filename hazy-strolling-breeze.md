# Monitoring Stack Implementation Plan

## Overview

Add health checks and monitoring dashboard to the homeserver stack:
- **Uptime Kuma** - Service availability monitoring with push notifications
- **Prometheus + Grafana** - Metrics collection and dashboards
- **ntfy** - Self-hosted push notifications (no SMTP required)
- **Node Exporter** - System metrics from each host

## Files to Create

### 1. Infrastructure (`apps/monitoring/`)

| File | Description |
|------|-------------|
| `main.tf` | LXC container (2 CPU, 2GB RAM, 32GB disk) |
| `provider.tf` | Proxmox provider config (copy from immich) |
| `terragrunt.hcl` | Terragrunt include (copy from immich) |

### 2. Docker Stack (`apps/monitoring/monitoring/`)

| File | Description |
|------|-------------|
| `docker-compose.yml` | Uptime Kuma, Prometheus, Grafana, ntfy, Node Exporter |
| `.env` | Environment variables (templated) |
| `prometheus.yml` | Scrape configs for all hosts |
| `alert.rules.yml` | Alert rules (host down, high CPU/memory, disk space) |
| `grafana/provisioning/datasources/prometheus.yml` | Prometheus datasource |
| `grafana/provisioning/dashboards/dashboards.yml` | Dashboard provisioning |

### 3. Ansible (`apps/monitoring/`)

| File | Description |
|------|-------------|
| `playbook.yml` | Deploy docker stack + node exporters to other hosts |

### 4. Node Exporter Roles (`roles/`)

| File | Description |
|------|-------------|
| `roles/node_exporter_docker/tasks/main.yml` | For docker hosts (immich, paperless) |
| `roles/node_exporter_binary/tasks/main.yml` | For non-docker hosts (systemd service) |

## Files to Modify

| File | Change |
|------|--------|
| `Makefile` | Add `monitoring` to SERVICES list |
| `apps/portal/homepage/services.yaml` | Add Monitoring section with links |
| `secrets/ansible/group_vars/all/vars.yml` | Add proxy_services for monitoring URLs |
| `secrets/ansible/group_vars/all/vault.yml` | Add grafana_admin_password |
| `apps/immich/immich/docker-compose.yml` | Add healthchecks to services |
| `apps/paperless/paperless/docker-compose.yml` | Add healthchecks to services |

## Implementation Order

### Phase 1: Core Infrastructure
1. Create `apps/monitoring/main.tf` (LXC using lxc_common module)
2. Create `apps/monitoring/provider.tf` and `terragrunt.hcl`
3. Create docker-compose stack with all services
4. Create `apps/monitoring/playbook.yml`
5. Add `monitoring` to SERVICES in Makefile
6. Add secrets to vault.yml
7. Run `make deploy-monitoring`

### Phase 2: Node Exporters
8. Create `roles/node_exporter_docker/` role
9. Create `roles/node_exporter_binary/` role
10. Update monitoring playbook to deploy node exporters to all hosts
11. Redeploy: `make deploy-app-monitoring`

### Phase 3: Docker Healthchecks
12. Add healthchecks to `apps/immich/immich/docker-compose.yml`
13. Add healthchecks to `apps/paperless/paperless/docker-compose.yml`
14. Redeploy: `make deploy-app-immich deploy-app-paperless`

### Phase 4: Integration
15. Update `apps/portal/homepage/services.yaml` with monitoring section
16. Update `secrets/ansible/group_vars/all/vars.yml` with proxy_services
17. Run `make deploy-dns` (Pi-hole CNAMEs)
18. Run `make deploy-app-nginx` (reverse proxy)
19. Run `make deploy-app-portal` (homepage links)

### Phase 5: Manual Configuration
20. Configure Uptime Kuma monitors via web UI
21. Configure Grafana alerts with ntfy contact point
22. Install ntfy app on mobile
23. Test alerts end-to-end

## Key Implementation Details

### LXC Resource Sizing
```hcl
module "lxc_monitoring" {
  source            = "../../modules/lxc_common"
  node_name         = "monitoring"
  proxmox_node_name = var.proxmox_node_name
  cpu_cores         = 2
  dedicated_memory  = 2048
  disk_size         = 32
}
```

### Docker Services & Ports
| Service | Port | Purpose |
|---------|------|---------|
| Uptime Kuma | 3001 | Uptime monitoring UI |
| Prometheus | 9090 | Metrics database |
| Grafana | 3000 | Dashboards |
| ntfy | 8080 | Push notifications |
| Node Exporter | 9100 | System metrics |

### Prometheus Scrape Targets
- All hosts via node_exporter on port 9100
- Immich metrics endpoint (built-in)
- Self-monitoring (prometheus, grafana)

### Alerting Flow
```
Service down → Uptime Kuma → ntfy → Mobile push notification
High CPU/disk → Prometheus → Grafana Alert → ntfy → Mobile push
```

## Notes

- ntfy provides push notifications without SMTP - email can be added later
- Uptime Kuma has built-in support for ntfy, Discord, Pushover, etc.
- Grafana can also send alerts directly to ntfy webhook
- Node Exporter should be deployed to ALL hosts for comprehensive system metrics
