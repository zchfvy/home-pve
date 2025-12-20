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

Use the Makefile for all deployments. Run `make help` to see all available targets.

### Single Service Deployment

```bash
# Deploy a complete service (infrastructure + application)
make deploy-immich
make deploy-portal

# Deploy only infrastructure
make deploy-infra-immich

# Deploy only application configuration
make deploy-app-immich

# Preview infrastructure changes
make plan-infra-immich

# Dry-run application changes
make check-app-immich
```

### Batch Deployment (All Services)

Batch commands prompt for passphrases once and apply to all services:

```bash
# Preview all infrastructure changes (drift detection)
make plan-infra-all

# Apply all infrastructure changes
make apply-infra-all

# Deploy all applications
make deploy-app-all

# Dry-run all applications
make check-app-all

# Preview everything (infra plan + app check)
make plan-all
```

### Full Stack Deployment

Deploy everything with a single command:

```bash
make deploy-all
```

This will:
1. Prompt for infrastructure passphrase (age)
2. Prompt for application passphrase (ansible-vault)
3. Show terraform plan for all services
4. Prompt for confirmation before applying
5. Apply all infrastructure changes
6. Wait for VMs/LXCs to be SSH-ready (2 min timeout)
7. Deploy all applications via Ansible

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
