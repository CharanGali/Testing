#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -eux
shopt -s inherit_errexit
set +v

: $1 $2

readonly SUBSCRIPTION_CODE=$1
readonly RG_NAME=$2

pushd $(dirname $0) > /dev/null
trap "popd > /dev/null" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

STORAGE_ACCOUNT_ID=($( \
  az resource list \
    ${SUBSCRIPTION_OPTION} \
    --resource-group ${RG_NAME} \
    --resource-type "Microsoft.Storage/storageAccounts" \
    | jq -r .[0].id \
))

echo ${STORAGE_ACCOUNT_ID}
