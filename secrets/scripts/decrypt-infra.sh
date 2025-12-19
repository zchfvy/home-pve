#!/bin/bash
#
# DEPRECATED: Use terragrunt-with-secrets.sh wrapper script instead
# 
# Legacy script for manual testing only
# For normal deployment, use: make deploy-infra-<service>
#

# Detect if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SOURCED=false
    echo "Note: Running as script. Variables will not persist after script ends."
    echo "For persistent variables, run: source ${0}"
else
    SOURCED=true
fi

# Only set -e when executed (not sourced, to avoid closing shell on errors)
if [[ "$SOURCED" == "false" ]]; then
    set -e
fi

# Get script directory (handle both sourced and executed cases)
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFRA_AGE="$ROOT_DIR/secrets/infrastructure.age"
INFRA_TEMP=$(mktemp)

# Trap to clean up temp file
trap 'rm -f "$INFRA_TEMP"' EXIT

if [[ ! -f "$INFRA_AGE" ]]; then
    echo "Error: infrastructure.age not found at $INFRA_AGE"
    if [[ "$SOURCED" == "true" ]]; then
        return 1
    else
        exit 1
    fi
fi

echo "Decrypting infrastructure secrets..."
if ! age --decrypt "$INFRA_AGE" > "$INFRA_TEMP"; then
    echo "Error: Failed to decrypt infrastructure.age (incorrect password or corrupted file)"
    if [[ "$SOURCED" == "true" ]]; then
        return 1
    else
        exit 1
    fi
fi

# Source only infrastructure-related variables
echo "Loading infrastructure environment variables..."
while IFS='=' read -r key value; do
    if [[ $key =~ ^export\ (PROXMOX_VE_|PM_) ]]; then
        # Remove 'export ' prefix and export the variable
        clean_key="${key#export }"
        export "$clean_key=$value"
        echo "Loaded: $clean_key"
    fi
done < <(grep '^export ' "$INFRA_TEMP")

if [[ "$SOURCED" == "true" ]]; then
    echo "Infrastructure secrets loaded in current shell. You can now run terraform/terragrunt commands."
else
    echo "Variables displayed but not exported (script was executed, not sourced)."
    echo "To load variables into your shell, run: source secrets/scripts/decrypt-infra.sh"
fi
