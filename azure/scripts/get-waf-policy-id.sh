#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit
set +v

: "$1" "$2" "$3"

readonly SUBSCRIPTION_CODE=${1:?}
readonly WAF_RG_NAME=${2:?}
readonly WAF_NAME=${3:?}

pushd "$(dirname "$0")" > /dev/null
trap "popd > /dev/null" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

# リソースグループに含まれるWAF policyを一覧取得して、該当するWAF policy名のIDを抽出する
# shellcheck disable=SC2086
az resource list \
  ${SUBSCRIPTION_OPTION} \
  --resource-group "${WAF_RG_NAME}" \
  --resource-type "Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies" \
  --query "[?contains(name, '${WAF_NAME}')].id" \
  --output tsv
