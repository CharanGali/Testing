#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

readonly ZONE_NAME=$1
readonly SUB_DOMAIN=$2
readonly IP_ADDRESS=$3
readonly DNS_SUBSCRIPTION_CODE=$4
readonly DNS_RG_NAME=$5

pushd $(dirname $0)
trap "popd" EXIT

DNS_SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh ${DNS_SUBSCRIPTION_CODE})

EXISTING_RECORD=$(az network dns record-set a list \
  ${DNS_SUBSCRIPTION_OPTION} \
  --resource-group "${DNS_RG_NAME}" \
  --zone-name "${ZONE_NAME}" \
  --output json \
  | jq -r '.[] | select(.name  == "'${SUB_DOMAIN}'")'
)

if [ -n "${EXISTING_RECORD}" ]; then
  echo "update dns record"
  az network dns record-set a update \
    ${DNS_SUBSCRIPTION_OPTION} \
    --name "${SUB_DOMAIN}" \
    --resource-group "${DNS_RG_NAME}" \
    --zone-name "${ZONE_NAME}" \
    --set aRecords[0].ipv4Address="${IP_ADDRESS}"
else
  echo "add dns record"
  az network dns record-set a add-record \
    ${DNS_SUBSCRIPTION_OPTION} \
    --record-set-name "${SUB_DOMAIN}" \
    --resource-group "${DNS_RG_NAME}" \
    --zone-name "${ZONE_NAME}" \
    --ipv4-address "${IP_ADDRESS}"
fi
