#!/bin/bash
#
# Import existing Proxmox VMs/LXCs back into Terraform state
# and patch missing attributes that Proxmox API doesn't return
#
# Usage: import-state.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
PROXMOX_NODE="mariner"
VM_FILE_ID="local:iso/jammy-server-cloudimg-amd64.img"
LXC_TEMPLATE_ID="local:vztmpl/ubuntu-22.04-server-cloudimg-amd64-root.tar.xz"

# Define services and their types
declare -A SERVICE_TYPES=(
    ["immich"]="vm"
    ["paperless"]="vm"
    ["portal"]="lxc"
    ["qbittorent"]="lxc"
    ["plex"]="lxc"
    ["jellyfin"]="lxc"
    ["servarr"]="lxc"
    ["nginx"]="lxc"
)

# Load secrets directly (avoid session trap issues)
INFRA_AGE="$ROOT_DIR/secrets/infrastructure.age"
TEMP_SECRETS=$(mktemp)
trap "rm -f $TEMP_SECRETS" EXIT

echo "Decrypting infrastructure secrets..."
if ! age --decrypt "$INFRA_AGE" > "$TEMP_SECRETS"; then
    echo "ERROR: Failed to decrypt infrastructure secrets" >&2
    exit 1
fi

# Export variables
while IFS= read -r line; do
    if [[ $line =~ ^export\ ([A-Z_]+)=(.*)$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        var_value="${var_value#\"}"
        var_value="${var_value%\"}"
        export "$var_name=$var_value"
    fi
done < "$TEMP_SECRETS"

echo "Secrets loaded."

echo "=========================================="
echo "  TERRAFORM STATE IMPORT & PATCH"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Import existing VMs/LXCs from Proxmox"
echo "  2. Patch state with missing attributes (file_id, template_file_id)"
echo "  3. Generate new SSH keys and passwords on next apply"
echo ""
echo "You'll need the VMID/CTID for each resource from the Proxmox UI."
echo ""

# Collect all IDs first
echo "=========================================="
echo "  COLLECTING VM/LXC IDs"
echo "=========================================="
echo ""

declare -A SERVICE_IDS

for service in "${!SERVICE_TYPES[@]}"; do
    type="${SERVICE_TYPES[$service]}"
    if [[ "$type" == "lxc" ]]; then
        prompt="Enter CTID for $service (LXC), or 'skip': "
    else
        prompt="Enter VMID for $service (VM), or 'skip': "
    fi

    read -p "$prompt" id

    if [[ "$id" != "skip" && -n "$id" ]]; then
        SERVICE_IDS[$service]=$id
    fi
done

echo ""
echo "=========================================="
echo "  IMPORTING & PATCHING"
echo "=========================================="

import_and_patch_vm() {
    local service=$1
    local vmid=$2
    local app_dir="$ROOT_DIR/apps/$service"

    if [[ ! -d "$app_dir" ]]; then
        echo "  ERROR: Directory not found: $app_dir"
        return 1
    fi

    cd "$app_dir"

    # Initialize terraform
    echo "  Initializing..."
    if ! terragrunt init -upgrade; then
        echo "  ERROR: terragrunt init failed"
        return 1
    fi

    # Import the VM
    local resource="module.vm_${service}.proxmox_virtual_environment_vm.ubuntu_vm"
    local import_id="${PROXMOX_NODE}/${vmid}"

    echo "  Importing VM (ID: $vmid)..."
    if ! terragrunt import "$resource" "$import_id" 2>&1 | grep -v "^$"; then
        echo "  ERROR: Import failed"
        return 1
    fi

    # Patch the state to add file_id
    echo "  Patching state (adding file_id)..."
    terragrunt state pull > state.json.tmp

    jq --arg file_id "$VM_FILE_ID" '
      .serial += 1 |
      .resources |= map(
        if .type == "proxmox_virtual_environment_vm" then
          .instances |= map(
            .attributes.disk |= map(
              .file_id = $file_id
            )
          )
        else .
        end
      )
    ' state.json.tmp > state.json.patched

    terragrunt state push -force state.json.patched
    rm -f state.json.tmp state.json.patched

    echo "  Done"
}

import_and_patch_lxc() {
    local service=$1
    local ctid=$2
    local app_dir="$ROOT_DIR/apps/$service"

    if [[ ! -d "$app_dir" ]]; then
        echo "  ERROR: Directory not found: $app_dir"
        return 1
    fi

    cd "$app_dir"

    # Initialize terraform
    echo "  Initializing..."
    if ! terragrunt init -upgrade; then
        echo "  ERROR: terragrunt init failed"
        return 1
    fi

    # Import the container
    local resource="module.lxc_${service}.proxmox_virtual_environment_container.ubuntu_container"
    local import_id="${PROXMOX_NODE}/${ctid}"

    echo "  Importing LXC (ID: $ctid)..."
    if ! terragrunt import "$resource" "$import_id" 2>&1 | grep -v "^$"; then
        echo "  ERROR: Import failed"
        return 1
    fi

    # Patch the state to add template_file_id
    echo "  Patching state (adding template_file_id)..."
    terragrunt state pull > state.json.tmp

    jq --arg template_id "$LXC_TEMPLATE_ID" '
      .serial += 1 |
      .resources |= map(
        if .type == "proxmox_virtual_environment_container" then
          .instances |= map(
            .attributes.operating_system |= map(
              .template_file_id = $template_id
            )
          )
        else .
        end
      )
    ' state.json.tmp > state.json.patched

    terragrunt state push -force state.json.patched
    rm -f state.json.tmp state.json.patched

    echo "  Done"
}

# Process each service
for service in "${!SERVICE_IDS[@]}"; do
    id="${SERVICE_IDS[$service]}"
    type="${SERVICE_TYPES[$service]}"

    echo ""
    echo "--- $service ($type: $id) ---"

    if [[ "$type" == "vm" ]]; then
        import_and_patch_vm "$service" "$id"
    else
        import_and_patch_lxc "$service" "$id"
    fi
done

echo ""
echo "=========================================="
echo "  IMPORT COMPLETE"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Verify no replacements planned:"
echo "   make plan-infra-all"
echo ""
echo "2. Apply to create SSH keys, passwords, and ansible inventory:"
echo "   make apply-infra-all"
echo ""
echo "3. Add new SSH public keys to VMs/LXCs via Proxmox console:"
echo "   for app in apps/*/; do"
echo "     [ -f \"\$app/key.pem\" ] && echo \"=== \$(basename \$app) ===\" && ssh-keygen -y -f \"\$app/key.pem\""
echo "   done"
echo ""
echo "4. Then deploy applications:"
echo "   make deploy-app-all"
