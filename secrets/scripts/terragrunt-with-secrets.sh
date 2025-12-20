#!/bin/bash
#
# Wrapper script that loads secrets and runs terragrunt
# Usage: ./terragrunt-with-secrets.sh <terragrunt-args>
#
# If INFRA_SECRETS_FILE is set (from session-secrets.sh), uses cached secrets.
# Otherwise, decrypts interactively.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check if running in a session with cached secrets
if [[ -n "$INFRA_SECRETS_FILE" && -f "$INFRA_SECRETS_FILE" ]]; then
    # Use cached secrets from session
    SECRETS_FILE="$INFRA_SECRETS_FILE"
else
    # Interactive mode: decrypt secrets now
    echo "Loading infrastructure secrets..." >&2

    INFRA_AGE="$ROOT_DIR/secrets/infrastructure.age"
    SECRETS_FILE=$(mktemp)
    trap "rm -f $SECRETS_FILE" EXIT

    if ! age --decrypt "$INFRA_AGE" > "$SECRETS_FILE"; then
        echo "ERROR: Failed to decrypt infrastructure secrets" >&2
        exit 1
    fi
fi

# Parse and export variables
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
done < "$SECRETS_FILE"

# Run terragrunt with all arguments
exec terragrunt "$@"