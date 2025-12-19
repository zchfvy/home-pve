#!/bin/bash
#
# Helper script for managing secret encryption
# Usage: 
#   ./encrypt-secrets.sh encrypt <file>   - Encrypt a file with age
#   ./encrypt-secrets.sh decrypt <file>   - Decrypt a file with age
#   ./encrypt-secrets.sh vault-encrypt    - Encrypt ansible vault
#   ./encrypt-secrets.sh vault-decrypt    - Decrypt ansible vault
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

show_usage() {
    echo "Usage: $0 <command> [file]"
    echo ""
    echo "Commands:"
    echo "  encrypt <file>    Encrypt file with age (creates .age version)"
    echo "  decrypt <file>    Decrypt .age file (prints to stdout)"
    echo "  vault-encrypt     Encrypt Ansible vault files"
    echo "  vault-decrypt     Decrypt Ansible vault files for editing"
    echo "  help              Show this help"
}

case "${1:-}" in
    encrypt)
        if [[ -z "${2:-}" ]]; then
            echo "Error: File path required"
            show_usage
            exit 1
        fi
        input_file="$2"
        output_file="${input_file}.age"
        echo "Encrypting $input_file -> $output_file"
        age --passphrase --output "$output_file" "$input_file"
        echo "Encrypted successfully. Remember to securely delete the original file if needed."
        ;;
    decrypt)
        if [[ -z "${2:-}" ]]; then
            echo "Error: File path required"
            show_usage
            exit 1
        fi
        age_file="$2"
        echo "Decrypting $age_file..."
        age --decrypt "$age_file"
        ;;
    vault-encrypt)
        vault_file="$ROOT_DIR/secrets/ansible/group_vars/all/vault.yml"
        if [[ -f "$vault_file" ]]; then
            ansible-vault encrypt "$vault_file"
            echo "Ansible vault encrypted successfully"
        else
            echo "No vault file found at $vault_file"
            exit 1
        fi
        ;;
    vault-decrypt)
        vault_file="$ROOT_DIR/secrets/ansible/group_vars/all/vault.yml"
        if [[ -f "$vault_file" ]]; then
            ansible-vault decrypt "$vault_file"
            echo "Ansible vault decrypted successfully"
        else
            echo "No vault file found at $vault_file"
            exit 1
        fi
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Error: Unknown command '${1:-}'"
        echo ""
        show_usage
        exit 1
        ;;
esac