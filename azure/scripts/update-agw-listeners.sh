#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"

readonly SUBSCRIPTION_CODE=$1
readonly LISTENER_NAME=$2
readonly FRONTEND_IP=$3
readonly FRONTEND_PORT=$4
readonly SSL_CERT=$5
readonly HOST_NAMES=$6
readonly AGW_NAME=$7
readonly AGW_RG_NAME=$8
readonly WAF_NAME=${9:-}
readonly WAF_RG_NAME=${10:-}

pushd "$(dirname "$0")"
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

WAF_OPTION=""
if [ -n "${WAF_NAME}" ]; then
  WAF_POLICY_ID=$(bash ./get-waf-policy-id.sh "${SUBSCRIPTION_CODE}" "${WAF_RG_NAME}" "${WAF_NAME}")
  WAF_OPTION="--waf-policy ${WAF_POLICY_ID}"
fi

echo "create or update listener"
az network application-gateway http-listener create \
  ${SUBSCRIPTION_OPTION} \
  --gateway-name "${AGW_NAME}" \
  --resource-group "${AGW_RG_NAME}" \
  --name "${LISTENER_NAME}" \
  --frontend-ip "${FRONTEND_IP}" \
  --frontend-port "${FRONTEND_PORT}" \
  --ssl-cert "${SSL_CERT}" \
  --host-names "${HOST_NAMES}" \
  ${WAF_OPTION}

