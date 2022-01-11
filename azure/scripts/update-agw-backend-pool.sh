#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $2 $3 $4 $5

readonly SUBSCRIPTION_CODE=${1:?}
readonly ADDRESS_POOL_NAME=${2:?}
readonly TARGET_IP_ADDRESS=${3:?}
readonly AGW_NAME=${4:?}
readonly AGW_RG_NAME=${5:?}

pushd $(dirname $0)
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh ${SUBSCRIPTION_CODE})

## 一覧表示
EXISTING_ADDRESS_POOL_NAME=$(az network application-gateway address-pool list \
  ${SUBSCRIPTION_OPTION} \
  --gateway-name ${AGW_NAME} \
  --resource-group  ${AGW_RG_NAME} \
  --query "[?name=='"${ADDRESS_POOL_NAME}"'].name" \
  --output tsv \
)

if [ -n "${EXISTING_ADDRESS_POOL_NAME}" ]; then
  echo "update address-pool record"
  az network application-gateway address-pool update \
    ${SUBSCRIPTION_OPTION} \
    --gateway-name ${AGW_NAME} \
    --resource-group ${AGW_RG_NAME} \
    --name ${ADDRESS_POOL_NAME} \
    --servers ${TARGET_IP_ADDRESS}
else
  echo "create address-pool record"
  az network application-gateway address-pool create \
    ${SUBSCRIPTION_OPTION} \
    --gateway-name ${AGW_NAME} \
    --name ${ADDRESS_POOL_NAME} \
    --resource-group ${AGW_RG_NAME} \
    --servers ${TARGET_IP_ADDRESS}
fi
