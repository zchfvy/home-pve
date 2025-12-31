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

# Track failures and plan totals
failed_services=()
total_add=0
total_change=0
total_destroy=0

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

    # Capture output while displaying it
    output=$(cd "$app_dir" && terragrunt "$command" 2>&1 | tee /dev/stderr) || {
        echo "ERROR: $command failed for $service" >&2
        failed_services+=("$service")
        continue
    }

    # Parse plan summary if this is a plan command
    if [[ "$command" == "plan" ]]; then
        # Strip ANSI color codes for parsing
        clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

        # Match "Plan: X to add, Y to change, Z to destroy"
        if echo "$clean_output" | grep -q "Plan:"; then
            add=$(echo "$clean_output" | grep -oP 'Plan: \K\d+(?= to add)' || true)
            change=$(echo "$clean_output" | grep -oP '\d+(?= to change)' || true)
            destroy=$(echo "$clean_output" | grep -oP '\d+(?= to destroy)' || true)

            if [[ -n "$add" && -n "$change" && -n "$destroy" && "$total_add" != "unknown" && "$total_change" != "unknown" && "$total_destroy" != "unknown" ]]; then
                total_add=$((total_add + add))
                total_change=$((total_change + change))
                total_destroy=$((total_destroy + destroy))
            elif [[ -z "$add" || -z "$change" || -z "$destroy" ]]; then
                # Parsing failed, mark totals as unknown
                total_add="unknown"
                total_change="unknown"
                total_destroy="unknown"
            fi
        fi
    fi
done

echo ""
echo "=========================================="

if [[ "$command" == "plan" ]]; then
    echo ""
    echo "  TOTAL: $total_add to add, $total_change to change, $total_destroy to destroy"
    echo ""
fi

if [[ ${#failed_services[@]} -gt 0 ]]; then
    echo "FAILED services: ${failed_services[*]}"
    exit 1
else
    echo "All services completed successfully"
fi
