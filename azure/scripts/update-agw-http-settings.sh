#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit


: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"

readonly SUBSCRIPTION_CODE=$1
readonly HTTP_SETTING_NAME=$2
readonly BACKEND_PORT=$3
readonly OVERRIDE_BACKEND_PATH=$4
readonly AGW_NAME=$5
readonly AGW_RG_NAME=$6
readonly CUSTOM_PROBE_NAME=$7
readonly TIMEOUT=$8

pushd "$(dirname "$0")"
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(../build-subscription-option.sh "${SUBSCRIPTION_CODE}")

## 一覧表示
# shellcheck disable=SC2086
EXISTING_HTTP_SETTING_NAME=$(az network application-gateway http-settings list \
  ${SUBSCRIPTION_OPTION} \
  --gateway-name "${AGW_NAME}" \
  --resource-group "${AGW_RG_NAME}" \
  --query "[?name=='${HTTP_SETTING_NAME}'].name" \
  --output tsv \
)

if [ -n "${EXISTING_HTTP_SETTING_NAME}" ]; then
  echo "update http-settings record"
  # shellcheck disable=SC2086
  az network application-gateway http-settings update \
    ${SUBSCRIPTION_OPTION} \
    --gateway-name "${AGW_NAME}" \
    --resource-group "${AGW_RG_NAME}" \
    --name "${HTTP_SETTING_NAME}" \
    --port "${BACKEND_PORT}" \
    --path "${OVERRIDE_BACKEND_PATH}" \
    --probe "${CUSTOM_PROBE_NAME}" \
    --timeout "${TIMEOUT}"
else
  echo "create http-settings record"
  # shellcheck disable=SC2086
  az network application-gateway http-settings create \
    ${SUBSCRIPTION_OPTION} \
    --gateway-name "${AGW_NAME}" \
    --resource-group "${AGW_RG_NAME}" \
    --name "${HTTP_SETTING_NAME}" \
    --port "${BACKEND_PORT}" \
    --path "${OVERRIDE_BACKEND_PATH}" \
    --probe "${CUSTOM_PROBE_NAME}" \
    --timeout "${TIMEOUT}"
fi
