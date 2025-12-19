# Secrets Management Migration Guide

## Overview
This guide will migrate your current `creds.age` + environment variable approach to a cleaner hybrid system:
- **Infrastructure secrets** (Terraform/Proxmox) → Age-encrypted files
- **Application secrets** (Ansible/Docker) → Ansible Vault

## Migration Steps

### Step 1: Backup Current System
```bash
# Backup your current encrypted secrets
cp creds.age creds.age.backup
```

### Step 2: Create Infrastructure Secrets File

1. **Decrypt your current secrets temporarily:**
```bash
age --decrypt creds.age > temp_creds
```

2. **Create the infrastructure secrets file:**
```bash
# Copy the template
cp secrets/infrastructure-template.env secrets/infrastructure.env

# Edit and add only the infrastructure values from temp_creds:
# - PROXMOX_VE_USERNAME
# - PROXMOX_VE_PASSWORD  
# - PM_USER, PM_PASS (if used)
nano secrets/infrastructure.env
```

3. **Encrypt the infrastructure secrets:**
```bash
age --passphrase --output secrets/infrastructure.age secrets/infrastructure.env
rm secrets/infrastructure.env  # Remove plaintext version
```

### Step 3: Create Application Secrets Vault

1. **Create the vault file:**
```bash
# Copy template and edit
cp secrets/ansible/group_vars/all/vault-template.yml secrets/ansible/group_vars/all/vault.yml

# Fill in the application secrets from temp_creds:
nano secrets/ansible/group_vars/all/vault.yml
```

2. **Encrypt with Ansible Vault:**
```bash
ansible-vault encrypt secrets/ansible/group_vars/all/vault.yml
```

3. **Clean up temporary files:**
```bash
rm temp_creds  # Remove temporary plaintext file
```

### Step 4: Update Your Workflow

## New Command Workflow

### For Terragrunt (Infrastructure):
```bash
# Use Makefile targets (recommended)
make deploy-infra-portal

# Or use wrapper script directly
cd apps/portal && ../../secrets/scripts/terragrunt-with-secrets.sh apply
```

### For Ansible (Applications):
```bash
# Method 1: Prompt for vault password each time
ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass

# Method 2: Store vault password in age-encrypted file (recommended)
# Create vault password file:
echo "your_vault_password" | age --passphrase --output secrets/.vault-pass.age
# Then use:
age --decrypt secrets/.vault-pass.age | ansible-playbook -i inventory.yml playbook.yml --vault-password-file /dev/stdin
```

### Convenience Scripts

Create these wrapper scripts for easier usage:

**`scripts/deploy-infra.sh`:**
```bash
#!/bin/bash
set -e
source secrets/scripts/decrypt-infra.sh
terragrunt run-all apply
```

**`scripts/deploy-apps.sh`:**
```bash
#!/bin/bash
set -e
if [[ -f secrets/.vault-pass.age ]]; then
    age --decrypt secrets/.vault-pass.age | ansible-playbook -i inventory.yml playbook.yml --vault-password-file /dev/stdin
else
    ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass
fi
```

## Testing the Migration

1. **Test infrastructure secrets:**
```bash
# This should set PROXMOX_VE_* variables
source secrets/scripts/decrypt-infra.sh
echo "Testing: $PROXMOX_VE_USERNAME"
```

2. **Test ansible vault:**
```bash
# This should show decrypted content
ansible-vault view secrets/ansible/group_vars/all/vault.yml
```

3. **Test a simple playbook run (dry run):**
```bash
ansible-playbook -i apps/immich/inventory.yml apps/immich/playbook.yml --ask-vault-pass --check
```

## After Migration Success

1. **Update .gitignore:**
```bash
# Add to .gitignore:
secrets/infrastructure.env
secrets/.vault-pass.age
secrets/ansible/group_vars/all/vault.yml.decrypted
```

2. **Remove old files:**
```bash
rm creds.age.backup  # Only after confirming everything works
rm creds.empty       # Template no longer needed
```

3. **Update documentation:**
   - Update README.md with new workflow
   - Remove references to old `source creds` approach

## Troubleshooting

- **"Vault password incorrect"**: Ensure you're using the right password for `ansible-vault`
- **"PROXMOX_VE_* not set"**: Make sure to `source secrets/scripts/decrypt-infra.sh` before terragrunt
- **"lookup('env'...) returns empty"**: Playbooks still need to be updated to use vault variables instead of env lookups

## Next Steps
After migration, the playbooks will be updated to use `{{ vault_* }}` variables instead of `{{ lookup('env', '...') }}` calls.