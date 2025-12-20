#!/bin/bash
#
# Wait for hosts to be SSH-ready after infrastructure provisioning
# Usage: wait-for-hosts.sh <services...>
#
# Timeout: 2 minutes per host (24 retries x 5 seconds)
# Exits with error if any host times out
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

MAX_RETRIES=24
RETRY_DELAY=5

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <services...>" >&2
    exit 1
fi

services="$@"
failed_hosts=()

for service in $services; do
    inventory="$ROOT_DIR/apps/$service/inventory.yml"

    if [[ ! -f "$inventory" ]]; then
        echo "No inventory for $service, skipping"
        continue
    fi

    # Extract host from inventory
    # Handle terraform provider format (ansible_host with value sub-key)
    host=$(grep -A5 "ansible_host:" "$inventory" 2>/dev/null | grep "value:" | head -1 | awk '{print $2}' | tr -d '"' || true)

    # Fallback to simple format
    if [[ -z "$host" ]]; then
        host=$(grep "ansible_host:" "$inventory" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' || true)
    fi

    if [[ -z "$host" ]]; then
        echo "Could not extract host for $service, skipping"
        continue
    fi

    echo -n "Waiting for $service ($host)..."

    ready=false
    for ((i=1; i<=MAX_RETRIES; i++)); do
        if nc -z -w2 "$host" 22 2>/dev/null; then
            echo " ready"
            ready=true
            break
        fi
        echo -n "."
        sleep $RETRY_DELAY
    done

    if [[ "$ready" != "true" ]]; then
        echo " TIMEOUT"
        failed_hosts+=("$service")
    fi
done

echo ""

if [[ ${#failed_hosts[@]} -gt 0 ]]; then
    echo "ERROR: The following hosts timed out: ${failed_hosts[*]}" >&2
    exit 1
fi

echo "All hosts are ready"
