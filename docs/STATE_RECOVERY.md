# Terraform State Recovery

This guide explains how to recover when Terraform state files are lost but VMs/LXCs still exist in Proxmox.

## What Gets Lost

When `terraform.tfstate` files are deleted:
- **VM/LXC resources** - Can be re-imported from Proxmox
- **SSH keys** (`key.pem`) - Lost, must be regenerated
- **Passwords** - Lost, must be regenerated
- **Ansible inventory** - Lost, recreated on apply

## Recovery Steps

### 1. Clear Any Partial State

```bash
rm -f apps/*/terraform.tfstate*
```

### 2. Get VM/LXC IDs from Proxmox

Open the Proxmox web UI and note the VMID/CTID for each service:
- VMs: immich, paperless
- LXCs: portal, qbittorent, plex, jellyfin, servarr, nginx

### 3. Run Import

```bash
make import-state
```

This will:
1. Prompt for each VMID/CTID (enter `skip` to skip any)
2. Import the resource from Proxmox
3. Patch the state with missing `file_id`/`template_file_id` attributes

### 4. Verify No Replacements

```bash
make plan-infra-all
```

You should see:
- **Creates** for: `ansible_host`, `local_file`, `random_password`, `tls_private_key`
- **In-place updates** for some container/VM attributes (harmless)
- **No replacements** (0 to destroy)

### 5. Apply to Generate New Keys

```bash
make apply-infra-all
```

This creates new SSH keys and `key.pem` files in each app directory.

### 6. Add SSH Keys to VMs/LXCs

The new SSH keys won't match what's on the existing VMs/LXCs. You need to add them via Proxmox.

**Get the public keys:**
```bash
for app in apps/*/; do
  if [ -f "$app/key.pem" ]; then
    echo "=== $(basename $app) ==="
    ssh-keygen -y -f "$app/key.pem"
  fi
done
```

**For LXCs** (via Proxmox host shell):
```bash
# Get a shell in the container (no password needed)
pct exec <CTID> bash

# Add the public key
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "ssh-rsa AAAA..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**For VMs** (if you don't know the password):

Option A - Reset password via cloud-init (only works on first boot):
1. Proxmox UI → Select VM → Cloud-Init tab
2. Set new password
3. Regenerate Image → Reboot

Option B - Recovery mode:
1. Console → Reboot → Hold Shift for GRUB
2. Select "Advanced options" → "Recovery mode"
3. Get root shell → `passwd ubuntu`

Option C - If QEMU guest agent is installed:
```bash
qm guest passwd <VMID> ubuntu
```

### 7. Verify Ansible Connectivity

```bash
make check-app-all
```

### 8. Deploy Applications

```bash
make deploy-app-all
```

## Preventing Future State Loss

Consider:
1. **Remote state backend** - Store state in S3, GCS, or Terraform Cloud
2. **Regular backups** - Back up `apps/*/terraform.tfstate` files
3. **State in git** - Remove `*.tfstate` from `.gitignore` (less secure but simpler)

## Technical Details

### Why Patching is Needed

When importing from Proxmox, some attributes aren't returned by the API because they're only used at creation time:
- `disk.file_id` - The source image for VMs
- `operating_system.template_file_id` - The template for LXCs

The import script patches these into the state to prevent Terraform from seeing a diff and wanting to recreate resources.

### State Serial Numbers

Terraform uses serial numbers to prevent concurrent modifications. When patching state, we increment the serial and use `-force` to push the modified state.
