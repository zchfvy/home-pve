#!/bin/bash
#
# Batch Ansible operations with single vault password prompt
# Usage: batch-ansible.sh <deploy|check> <services...>
#
# Examples:
#   batch-ansible.sh deploy immich paperless portal
#   batch-ansible.sh check immich paperless portal qbittorent plex jellyfin servarr
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <deploy|check> <services...>" >&2
    exit 1
fi

mode=$1
shift
services="$@"

# Validate mode
if [[ "$mode" != "deploy" && "$mode" != "check" ]]; then
    echo "ERROR: Mode must be 'deploy' or 'check'" >&2
    exit 1
fi

# Prompt for vault password once
read -s -p "Ansible Vault password: " vault_pass
echo

# Store in secure temp file
VAULT_FILE=$(mktemp)
chmod 600 "$VAULT_FILE"
echo "$vault_pass" > "$VAULT_FILE"
trap "rm -f $VAULT_FILE" EXIT

# Set check mode args if needed
check_args=""
if [[ "$mode" == "check" ]]; then
    check_args="--check --diff"
fi

# Track failures
failed_services=()

for service in $services; do
    app_dir="$ROOT_DIR/apps/$service"

    if [[ ! -d "$app_dir" ]]; then
        echo "WARNING: Service directory not found: $app_dir" >&2
        failed_services+=("$service")
        continue
    fi

    if [[ ! -f "$app_dir/playbook.yml" ]]; then
        echo "WARNING: No playbook.yml in $service, skipping" >&2
        continue
    fi

    echo ""
    echo "=========================================="
    echo "  $mode: $service"
    echo "=========================================="

    if ! (cd "$app_dir" && \
         ANSIBLE_ROLES_PATH=../../roles ansible-playbook \
           -i inventory.yml playbook.yml \
           --vault-password-file "$VAULT_FILE" \
           -e @../../secrets/ansible/group_vars/all/vault.yml \
           -e @../../secrets/ansible/group_vars/all/vars.yml \
           $check_args); then
        echo "ERROR: $mode failed for $service" >&2
        failed_services+=("$service")
    fi
done

echo ""
echo "=========================================="

if [[ ${#failed_services[@]} -gt 0 ]]; then
    echo "FAILED services: ${failed_services[*]}"
    exit 1
else
    echo "All services completed successfully"
fi
