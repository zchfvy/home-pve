# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Homeserver Infrastructure - automated provisioning and configuration for a Proxmox-based homeserver stack using Terraform/Terragrunt for infrastructure and Ansible for configuration management.

## Common Commands

### Deployment (via Makefile)

```bash
# Single service
make deploy-<service>          # Full deployment (infra + app)
make plan-infra-<service>      # Preview terraform changes
make deploy-infra-<service>    # Apply infrastructure only
make deploy-app-<service>      # Deploy application only
make check-app-<service>       # Dry-run application (ansible --check)

# Batch operations (single passphrase prompt)
make plan-infra-all            # Plan all infrastructure
make apply-infra-all           # Apply all infrastructure
make deploy-app-all            # Deploy all applications
make deploy-all                # Full stack: plan → confirm → apply → wait → deploy

# Network/DNS
make deploy-dns                # Deploy Pi-hole DNS configuration
make check-dns                 # Dry-run DNS configuration

# Available services
# immich, paperless, portal, qbittorent, plex, jellyfin, servarr, nginx
```

### Direct Commands

```bash
# Terraform (from apps/<service>/)
../../secrets/scripts/terragrunt-with-secrets.sh plan
../../secrets/scripts/terragrunt-with-secrets.sh apply

# Ansible (from apps/<service>/)
ANSIBLE_ROLES_PATH=../../roles ansible-playbook -i inventory.yml playbook.yml \
  --ask-vault-pass \
  -e @../../secrets/ansible/group_vars/all/vault.yml \
  -e @../../secrets/ansible/group_vars/all/vars.yml
```

## Architecture

### Infrastructure Flow

```
Makefile → Secrets Decryption → Terragrunt/Terraform → Proxmox VMs/LXCs
                              → Ansible Playbooks → Docker/Systemd Services
```

### Directory Structure

- `apps/<service>/` - Per-service Terraform + Ansible configurations
  - `main.tf` - VM/LXC provisioning
  - `playbook.yml` - Ansible configuration
  - `inventory.yml` - Auto-generated from Terraform
  - `<service>/` - Docker compose files and configs
- `network/` - Network infrastructure (Pi-hole DNS configuration)
- `roles/` - Reusable Ansible roles (docker, docker_compose, nfs_mount, systemd_service)
- `modules/` - Terraform modules (vm_common, lxc_common)
- `secrets/` - Encrypted credentials (age for infra, ansible-vault for apps)
- `secrets/scripts/` - Deployment wrapper scripts

### Secrets Architecture

Two-tier system:
1. **Infrastructure** (`secrets/infrastructure.age`) - Age-encrypted Proxmox credentials, auto-loaded by terragrunt wrapper
2. **Application** (`secrets/ansible/group_vars/all/vault.yml`) - Ansible Vault for service credentials (API keys, passwords)
3. **Configuration** (`secrets/ansible/group_vars/all/vars.yml`) - Non-sensitive settings (NFS paths, versions, ports)

### Terraform Modules

- `modules/vm_common/` - Proxmox VM provisioning with Ubuntu 22.04
- `modules/lxc_common/` - Proxmox LXC containers with NFS/video passthrough support

### Ansible Roles

- `docker` - Installs Docker CE from official repo
- `docker_compose` - Deploys and manages compose applications
- `nfs_mount` - Configures NFS mounts with fstab
- `systemd_service` - Creates systemd unit files

## Key Patterns

### Adding a New Service

1. Create `apps/<service>/main.tf` using vm_common or lxc_common module
2. Create `apps/<service>/playbook.yml` using existing roles
3. Add service name to `SERVICES` variable in Makefile
4. If proxied through nginx, add to `proxy_services` in `secrets/ansible/group_vars/all/vars.yml`

### Playbook Structure

```yaml
- name: Setup <Service>
  hosts: <service_name>
  roles:
    - role: nfs_mount      # If NFS needed
    - role: docker         # If containers used
    - role: docker_compose # Deploy compose stack
  tasks:
    # Additional custom configuration
```

### Terraform Module Usage

```hcl
module "vm_<service>" {
  source            = "../../modules/vm_common"
  node_name         = "<service>"
  proxmox_node_name = var.proxmox_node_name
  cpu_cores         = 4
  disk_size         = 16
  dedicated_memory  = 4096
}
```

## Important Notes

- Proxmox requires root credentials (API keys insufficient for LXC mounts)
- All secrets must be encrypted before commit (age or ansible-vault)
- Terraform state files and SSH keys are git-ignored
- VMs use Ubuntu 22.04 (Jammy) as base image
- DNS routing: `home.arpa` domains resolve directly to services (via DHCP); external domains and simple names route through nginx proxy. This ensures upstream connections work with native ports.
