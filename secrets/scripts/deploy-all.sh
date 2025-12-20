#!/bin/bash
#
# Full deployment: plan -> confirm -> apply infra -> wait -> deploy apps
# Usage: deploy-all.sh <services...>
#
# Prompts for both passphrases upfront, shows full plan, requires confirmation
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <services...>" >&2
    exit 1
fi

services="$@"

echo "=========================================="
echo "  HOMESERVER FULL DEPLOYMENT"
echo "=========================================="
echo ""
echo "Services: $services"
echo ""

# 1. Start session - prompt for infrastructure secrets
source "$SCRIPT_DIR/session-secrets.sh"
start_session

# 2. Prompt for vault password
read -s -p "Ansible Vault password: " vault_pass
echo

VAULT_FILE=$(mktemp)
chmod 600 "$VAULT_FILE"
echo "$vault_pass" > "$VAULT_FILE"

# Cleanup on exit
cleanup() {
    rm -f "$VAULT_FILE"
    end_session
}
trap cleanup EXIT

# 3. Show infrastructure plan for all services
echo ""
echo "=========================================="
echo "  INFRASTRUCTURE PLAN"
echo "=========================================="

plan_failed=false
for service in $services; do
    app_dir="$ROOT_DIR/apps/$service"

    if [[ ! -f "$app_dir/terragrunt.hcl" ]]; then
        echo "--- $service: no terragrunt config, skipping ---"
        continue
    fi

    echo ""
    echo "--- Plan: $service ---"
    if ! (cd "$app_dir" && terragrunt plan -no-color 2>&1); then
        echo "WARNING: Plan failed for $service"
        plan_failed=true
    fi
done

if [[ "$plan_failed" == "true" ]]; then
    echo ""
    echo "WARNING: Some plans failed. Review output above."
fi

# 4. Prompt for approval
echo ""
echo "=========================================="
echo ""
read -p "Apply all changes above? [y/N] " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Deployment aborted."
    exit 0
fi

# 5. Apply all infrastructure
echo ""
echo "=========================================="
echo "  APPLYING INFRASTRUCTURE"
echo "=========================================="

for service in $services; do
    app_dir="$ROOT_DIR/apps/$service"

    if [[ ! -f "$app_dir/terragrunt.hcl" ]]; then
        continue
    fi

    echo ""
    echo "--- Applying: $service ---"
    (cd "$app_dir" && terragrunt apply -auto-approve)
done

# 6. Wait for hosts to be SSH-ready
echo ""
echo "=========================================="
echo "  WAITING FOR HOSTS"
echo "=========================================="

"$SCRIPT_DIR/wait-for-hosts.sh" $services

# 7. Deploy all applications
echo ""
echo "=========================================="
echo "  DEPLOYING APPLICATIONS"
echo "=========================================="

for service in $services; do
    app_dir="$ROOT_DIR/apps/$service"

    if [[ ! -f "$app_dir/playbook.yml" ]]; then
        echo "--- $service: no playbook, skipping ---"
        continue
    fi

    echo ""
    echo "--- Deploying: $service ---"
    (cd "$app_dir" && \
     ANSIBLE_ROLES_PATH=../../roles ansible-playbook \
       -i inventory.yml playbook.yml \
       --vault-password-file "$VAULT_FILE" \
       -e @../../secrets/ansible/group_vars/all/vault.yml \
       -e @../../secrets/ansible/group_vars/all/vars.yml)
done

echo ""
echo "=========================================="
echo "  DEPLOYMENT COMPLETE"
echo "=========================================="
