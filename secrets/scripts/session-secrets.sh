#!/bin/bash
#
# Session-based secret caching for batch operations
# Source this file to use start_session and end_session functions
#
# NOTE: This script requires bash. Run with: bash -c 'source ... && start_session'
#
# Usage:
#   source session-secrets.sh
#   start_session  # Prompts for age passphrase, caches decrypted secrets
#   # ... run terragrunt commands ...
#   end_session    # Cleans up (also runs automatically on EXIT)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Session state
_SESSION_DIR=""
_SESSION_ACTIVE=false

start_session() {
    if [[ "$_SESSION_ACTIVE" == "true" ]]; then
        echo "Session already active" >&2
        return 0
    fi

    # Create secure temp directory
    _SESSION_DIR=$(mktemp -d)
    chmod 700 "$_SESSION_DIR"

    # Decrypt infrastructure secrets
    local infra_age="$ROOT_DIR/secrets/infrastructure.age"
    export INFRA_SECRETS_FILE="$_SESSION_DIR/infrastructure.env"

    echo "Decrypting infrastructure secrets..." >&2
    if ! age --decrypt "$infra_age" > "$INFRA_SECRETS_FILE"; then
        echo "ERROR: Failed to decrypt infrastructure secrets" >&2
        rm -rf "$_SESSION_DIR"
        return 1
    fi
    chmod 600 "$INFRA_SECRETS_FILE"

    # Parse and export variables for current shell
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
    done < "$INFRA_SECRETS_FILE"

    _SESSION_ACTIVE=true

    # Set up cleanup trap
    trap end_session EXIT

    echo "Session started (secrets cached)" >&2
}

end_session() {
    if [[ "$_SESSION_ACTIVE" != "true" ]]; then
        return 0
    fi

    if [[ -n "$_SESSION_DIR" && -d "$_SESSION_DIR" ]]; then
        rm -rf "$_SESSION_DIR"
    fi

    unset INFRA_SECRETS_FILE
    unset PROXMOX_VE_USERNAME
    unset PROXMOX_VE_PASSWORD
    unset PM_USER
    unset PM_PASS

    _SESSION_DIR=""
    _SESSION_ACTIVE=false

    echo "Session ended (secrets cleared)" >&2
}
