#!/bin/bash
set -e

# Load BWS Access Token
if [ -f "/run/secrets/bws_access_token" ]; then
    export BWS_ACCESS_TOKEN=$(cat /run/secrets/bws_access_token)
else
    echo "Error: bws_access_token secret not found."
    exit 1
fi

echo "Retrieving credentials from Bitwarden..."

# Fetch Proxmox environment variables
export PROXMOX_URL=$(bws secret get "$BWS_PROXMOX_URL_ID" | jq -r '.value')
export PROXMOX_USER=$(bws secret get "$BWS_PROXMOX_USER_ID" | jq -r '.value')
export PROXMOX_PASSWORD=$(bws secret get "$BWS_PROXMOX_PASSWORD_ID" | jq -r '.value')

# Fetch the SSH keys
if [ -n "$BWS_SSH_KEY_ID" ]; then
    mkdir -p ~/.ssh
    bws secret get "$BWS_SSH_KEY_ID" | jq -r '.value' > ~/.ssh/id_ansible
    chmod 600 ~/.ssh/id_ansible
    export ANSIBLE_HOST_KEY_CHECKING=False
fi

# Handle Inventory Override
HAS_INVENTORY=false
for arg in "$@"; do
    if [[ "$arg" == "-i" ]] || [[ "$arg" == "--inventory" ]] || [[ "$arg" == "--inventory-file" ]]; then
        HAS_INVENTORY=true
        break
    fi
done

# Execute Ansible with Proxmox Dynaic Inventory Default
if [ "$HAS_INVENTORY" = true ]; then
    echo "Executing playbook with user-supplied inventory target..."
    exec ansible-playbook "$@"
else
    echo "Executing playbook with Proxmox dynamic inventory..."
    exec ansible-playbook -i proxmox.yml "$@"
fi