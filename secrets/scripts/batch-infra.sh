#!/bin/bash
#
# Batch infrastructure operations with single passphrase prompt
# Usage: batch-infra.sh <plan|apply> <services...>
#
# Examples:
#   batch-infra.sh plan immich paperless portal
#   batch-infra.sh apply immich paperless portal qbittorent plex jellyfin servarr
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <plan|apply> <services...>" >&2
    exit 1
fi

command=$1
shift
services="$@"

# Validate command
if [[ "$command" != "plan" && "$command" != "apply" ]]; then
    echo "ERROR: Command must be 'plan' or 'apply'" >&2
    exit 1
fi

# Start session - decrypt infrastructure secrets once
source "$SCRIPT_DIR/session-secrets.sh"
start_session

# Track failures
failed_services=()

for service in $services; do
    app_dir="$ROOT_DIR/apps/$service"

    if [[ ! -d "$app_dir" ]]; then
        echo "WARNING: Service directory not found: $app_dir" >&2
        failed_services+=("$service")
        continue
    fi

    if [[ ! -f "$app_dir/terragrunt.hcl" ]]; then
        echo "WARNING: No terragrunt.hcl in $service, skipping" >&2
        continue
    fi

    echo ""
    echo "=========================================="
    echo "  $command: $service"
    echo "=========================================="

    if ! (cd "$app_dir" && terragrunt "$command"); then
        echo "ERROR: $command failed for $service" >&2
        failed_services+=("$service")
        # Continue to next service instead of failing immediately
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
