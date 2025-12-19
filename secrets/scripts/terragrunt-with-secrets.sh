#!/bin/bash
#
# Wrapper script that loads secrets and runs terragrunt
# Usage: ./terragrunt-with-secrets.sh <terragrunt-args>
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOAD_SCRIPT="$ROOT_DIR/secrets/scripts/load-infra-secrets.sh"

# Load secrets directly in this script instead of relying on external file
echo "Loading infrastructure secrets..." >&2

INFRA_AGE="$ROOT_DIR/secrets/infrastructure.age"
TEMP_SECRETS=$(mktemp)
trap "rm -f $TEMP_SECRETS" EXIT

if ! age --decrypt "$INFRA_AGE" > "$TEMP_SECRETS"; then
    echo "ERROR: Failed to decrypt infrastructure secrets" >&2
    exit 1
fi

# Parse and export variables directly
while IFS= read -r line; do
    if [[ $line =~ ^export\ ([A-Z_]+)=(.*)$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        # Remove surrounding quotes if present
        if [[ $var_value =~ ^\"(.*)\"$ ]]; then
            var_value="${BASH_REMATCH[1]}"
        elif [[ $var_value =~ ^\'(.*)\'$ ]]; then
            var_value="${BASH_REMATCH[1]}"
        fi
        export "$var_name=$var_value"
    fi
done < "$TEMP_SECRETS"

# Run terragrunt with all arguments
exec terragrunt "$@"