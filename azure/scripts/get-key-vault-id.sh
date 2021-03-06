#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -eux
shopt -s inherit_errexit
set +v

: $1 $2

readonly SUBSCRIPTION_CODE=$1
readonly KV_RG_NAME=$2

pushd $(dirname $0) > /dev/null
trap "popd > /dev/null" EXIT

SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

KEY_VAULT_ID=($( \
  az resource list \
    ${SUBSCRIPTION_OPTION} \
    --resource-group ${KV_RG_NAME} \
    --resource-type "Microsoft.KeyVault/vaults" \
    | jq -r .[0].id \
))

echo ${KEY_VAULT_ID}
