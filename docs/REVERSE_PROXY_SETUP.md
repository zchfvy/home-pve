# Reverse Proxy and DNS Configuration

This document describes the nginx reverse proxy and Pi-hole DNS autoconfiguration setup.

## Overview

The infrastructure uses:
- **Nginx** (LXC container) - Reverse proxy for all services on port 80
- **Pi-hole** (external) - DNS server with CNAME records routing to nginx

### DNS Routing Strategy

There are two routing paths depending on the hostname used:

**External/Simple Names → Nginx Proxy:**
```
┌─────────────────────────────────────────────────────────────┐
│ Client Request: http://jellyfin.jasonxun2020.com            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Pi-hole DNS (192.168.1.253)                                 │
│ CNAME: jellyfin.jasonxun2020.com → nginx.home.arpa          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Nginx Reverse Proxy (nginx.home.arpa:80)                    │
│ SNI routing based on Host header                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Backend Service (jellyfin.home.arpa:8096)                   │
└─────────────────────────────────────────────────────────────┘
```

**Internal home.arpa Names → Direct to Service:**
```
┌─────────────────────────────────────────────────────────────┐
│ Client Request: http://jellyfin.home.arpa:8096              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Pi-hole DNS/DHCP                                            │
│ A record: jellyfin.home.arpa → 192.168.x.x (service IP)     │
│ (Set automatically by DHCP hostname registration)           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Backend Service directly (jellyfin:8096)                    │
└─────────────────────────────────────────────────────────────┘
```

**Why home.arpa uses direct routing:** The `home.arpa` internal domain should resolve directly to service IPs (not through nginx CNAME) so that upstream connections work correctly with native ports. This ensures services can communicate with each other directly without proxy overhead.

## Supported Hostnames

Each service supports three hostname variants with different routing:

| Type | Example | Routing | Use Case |
|------|---------|---------|----------|
| Simple name | `jellyfin` | Via nginx proxy (port 80) | Quick internal access |
| Internal FQDN | `jellyfin.home.arpa:8096` | Direct to service (native port) | Service-to-service communication |
| External domain | `jellyfin.jasonxun2020.com` | Via nginx proxy (port 80) | External/canonical access |

**Note:** The `home.arpa` internal domain resolves directly to service IPs via Pi-hole DHCP hostname registration. This requires using the service's native port but ensures proper upstream functionality.

## Services Proxied

| Service | Backend | Special Config |
|---------|---------|----------------|
| jellyfin | jellyfin.home.arpa:8096 | WebSocket support |
| radarr | servarr.home.arpa:7878 | - |
| sonarr | servarr.home.arpa:8989 | - |
| prowlarr | servarr.home.arpa:9696 | - |
| qbittorrent | qbittorrent.home.arpa:8080 | - |
| immich | immich.home.arpa:2283 | WebSocket, 50GB uploads |
| paperless | paperless.home.arpa:8000 | 100MB uploads |
| portal | portal.home.arpa:3000 | - |

## Deployment Steps

### Step 1: Deploy Nginx Infrastructure

```bash
# Preview changes
make plan-infra-nginx

# Deploy LXC container
make deploy-infra-nginx
```

This creates an LXC container with:
- 512 MB RAM
- 1 CPU core
- 4 GB disk
- DHCP IP address

### Step 2: Deploy Nginx Application

```bash
# Wait ~30 seconds for LXC to boot, then:
make deploy-app-nginx
```

This installs nginx and configures the reverse proxy.

### Step 3: Configure Pi-hole DNS

```bash
make deploy-dns
```

This SSHs into Pi-hole and deploys CNAME records for all services.

**Note:** Requires SSH key access to Pi-hole as user `pi`.

### Full Deployment (All Steps)

```bash
# Deploy everything
make deploy-nginx

# Wait for LXC boot
sleep 30

# Configure DNS
make deploy-dns
```

## Verification

Test that routing works:

```bash
# Simple name - via nginx proxy (requires DNS)
curl http://jellyfin/

# External domain - via nginx proxy
curl http://jellyfin.jasonxun2020.com/

# Internal FQDN - direct to service (requires native port)
curl http://jellyfin.home.arpa:8096/

# Nginx health check
curl http://nginx.home.arpa/health
```

**Note:** The `home.arpa` domain requires the service port since it resolves directly to the service, not through nginx.

## Configuration Files

### Centralized Service Configuration

| File | Purpose |
|------|---------|
| `secrets/ansible/group_vars/all/vars.yml` | Shared `proxy_services` and `network` config |

### Nginx

| File | Purpose |
|------|---------|
| `apps/nginx/main.tf` | LXC container definition |
| `apps/nginx/playbook.yml` | Ansible deployment |
| `apps/nginx/nginx/apps.conf.j2` | Nginx server block template |

### Pi-hole DNS

| File | Purpose |
|------|---------|
| `network/pihole/inventory.yml` | Pi-hole host definition |
| `network/pihole/playbook.yml` | DNS deployment |
| `network/pihole/templates/nginx-cnames.conf.j2` | CNAME record template (uses `proxy_services` keys) |

## Adding a New Service

To add a new service to the reverse proxy:

### 1. Update Centralized Configuration

Edit `secrets/ansible/group_vars/all/vars.yml` and add to `proxy_services`:

```yaml
proxy_services:
  # ... existing services ...
  newservice:
    backend: "newservice.{{ network.internal_domain }}:8080"
    websocket: false        # Set true if needed (for WebSocket support)
    client_max_body: "10M"  # Optional, for large uploads
```

This single configuration is shared by both nginx (for reverse proxy backends) and Pi-hole (for CNAME records).

### 2. Redeploy

```bash
make deploy-app-nginx
make deploy-dns
```

Both playbooks read from the centralized `proxy_services` configuration.

## Troubleshooting

### Nginx not responding

```bash
# Check nginx status
ssh root@nginx.home.arpa systemctl status nginx

# Check nginx config syntax
ssh root@nginx.home.arpa nginx -t

# View nginx logs
ssh root@nginx.home.arpa journalctl -u nginx -f
```

### DNS not resolving

```bash
# Check Pi-hole config
ssh pi@192.168.1.253 cat /etc/dnsmasq.d/10-nginx-proxy.conf

# Restart Pi-hole DNS
ssh pi@192.168.1.253 sudo pihole restartdns

# Test resolution
dig jellyfin.home.arpa @192.168.1.253
```

### Backend service unreachable

```bash
# Test from nginx container
ssh root@nginx.home.arpa curl -I http://jellyfin.home.arpa:8096/

# Check if backend is running
ssh root@jellyfin.home.arpa systemctl status jellyfin
```

## Future Enhancements

### HTTPS Support

The nginx template includes commented SSL configuration. To enable HTTPS:

1. Obtain certificates (Let's Encrypt or self-signed)
2. Place certificates in `/etc/nginx/ssl/` on nginx container
3. Uncomment SSL blocks in `apps/nginx/nginx/apps.conf.j2`
4. Redeploy: `make deploy-app-nginx`

### External DNS

For `*.jasonxun2020.com` to work externally:

1. Configure your domain registrar/DNS provider to point `*.jasonxun2020.com` to your home IP
2. Set up port forwarding on your router (port 80 → nginx LXC IP)
3. Consider using Cloudflare for DDoS protection and SSL termination
