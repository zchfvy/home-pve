# Homeserver Infrastructure

Automated provisioning and configuration for a Proxmox-based homeserver stack using Terraform and Ansible.

**GitHub**: https://github.com/zchfvy/home-pve

## Architecture

- **Terraform/Terragrunt**: Provisions Proxmox VMs and LXC containers
- **Ansible**: Configures services and deploys applications
- **Secrets**: Age encryption for infrastructure, Ansible Vault for application secrets

## Prerequisites

Install the following tools:
- [Terraform](https://www.terraform.io/)
- [Terragrunt](https://terragrunt.gruntwork.io/)
- [Ansible](https://www.ansible.com/)
- [Age](https://github.com/FiloSottile/age) (for secrets encryption)

Install the Ansible Terraform inventory plugin:
```bash
ansible-galaxy collection install cloud.terraform
```

## Directory Structure

```
.
├── apps/       # Service definitions (terraform + ansible per service)
├── roles/      # Reusable Ansible roles
├── secrets/    # Encrypted secrets (infrastructure + application)
├── modules/    # Terraform modules
├── docs/       # Additional documentation
└── Makefile    # Deployment automation
```

## Initial Setup

### 1. Proxmox Configuration

Proxmox requires root credentials for LXC mount operations. API keys cannot provide the necessary permissions.

### 2. Secrets Setup

**Infrastructure secrets** (Proxmox credentials):
```bash
# Copy the template
cp secrets/infrastructure-template.env secrets/infrastructure.env

# Edit with your Proxmox credentials
# PROXMOX_VE_USERNAME="root@pam"
# PROXMOX_VE_PASSWORD="your_password"

# Encrypt with age
age -e -R ~/.age/recipients.txt secrets/infrastructure.env > secrets/infrastructure.age
rm secrets/infrastructure.env
```

**Application secrets** (service credentials):
```bash
# Copy the template
cp secrets/ansible/group_vars/all/vault-template.yml secrets/ansible/group_vars/all/vault.yml

# Edit with your application secrets
# Then encrypt with ansible-vault
ansible-vault encrypt secrets/ansible/group_vars/all/vault.yml
```

See `docs/SECRETS_MANAGEMENT_SUMMARY.md` for detailed documentation.

## Deployment

Use the Makefile for all deployments:

```bash
# Show available targets
make help

# Deploy a complete service (infrastructure + application)
make deploy-immich
make deploy-portal

# Deploy only infrastructure
make deploy-infra-immich

# Deploy only application configuration
make deploy-app-immich

# Dry-run to preview changes
make check-app-immich
make check-all
```

## Maintenance

### Proxmox Certificate Renewal

When Proxmox certificates expire (annually), regenerate them:

1. Delete or move the existing certificates:
```bash
rm /etc/pve/pve-root-ca.pem
rm /etc/pve/priv/pve-root-ca.key
rm /etc/pve/nodes/<node>/pve-ssl.pem
rm /etc/pve/nodes/<node>/pve-ssl.key
```

2. Regenerate certificates:
```bash
pvecm updatecerts -f
```

Run this on each node in the cluster.

## Documentation

Additional documentation in `docs/`:
- `SECRETS_MANAGEMENT_SUMMARY.md` - Secrets architecture and usage
- `CLEANUP_ANALYSIS.md` - Codebase analysis and improvement plan
