#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"

readonly SUBSCRIPTION_CODE=$1
readonly ROUTING_PATH=$2
readonly HTTP_SETTING_NAME=$3
readonly BACKEND_POOL_NAME=$4
readonly DEFAULT_HTTP_SETTING_NAME=$5
readonly DEFAULT_BACKEND_POOL_NAME=$6
readonly RULE_NAME=$7
readonly AGW_NAME=$8
readonly AGW_RG_NAME=$9

pushd "$(dirname "$0")"
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

echo "create or update url path map"
az network application-gateway url-path-map create \
  ${SUBSCRIPTION_OPTION} \
  --gateway-name "${AGW_NAME}" \
  --resource-group "${AGW_RG_NAME}" \
  --name "${RULE_NAME}" \
  --paths "${ROUTING_PATH}" \
  --rule-name "url-path-map-${RULE_NAME}" \
  --address-pool "${BACKEND_POOL_NAME}" \
  --http-settings "${HTTP_SETTING_NAME}" \
  --default-http-settings "${DEFAULT_HTTP_SETTING_NAME}" \
  --default-address-pool "${DEFAULT_BACKEND_POOL_NAME}"

