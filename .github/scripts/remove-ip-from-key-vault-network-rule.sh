#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# description
# ==========
# Remove the argument IP from the network rule for the Key Vault secret.
#
# arguments
# ==========
#
# 1. IP_ADDRESS
#
# 2. SUBSCRIPTION_ID
#
# 3. KV_RG_NAME
#    Key Vault Resource Group Name
#
################################################################################
: $1 $2 $3

readonly IP_ADDRESS=$1
readonly SUBSCRIPTION_ID=$2
readonly KV_RG_NAME=$3

KEY_VAULT_ID=$(
  az resource list \
    --subscription ${SUBSCRIPTION_ID} \
    --resource-group ${KV_RG_NAME} \
    --resource-type "Microsoft.KeyVault/vaults" \
    | jq -r .[0].id \
)
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")

az keyvault network-rule remove \
  --subscription ${SUBSCRIPTION_ID} \
  --resource-group ${KV_RG_NAME} \
  --name ${KEY_VAULT_NAME} \
  --ip-address "${IP_ADDRESS}/32"