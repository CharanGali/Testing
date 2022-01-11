#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -eux -o pipefail
shopt -s inherit_errexit
set +v

: "$1" "$2"

readonly SUBSCRIPTION_CODE=$1
readonly PIP_RG_NAME=$2

pushd "$(dirname "$0")" > /dev/null
trap "popd > /dev/null" EXIT

read -ra SUBSCRIPTION_OPTION <<< \
 "$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")"

az resource list \
  "${SUBSCRIPTION_OPTION[@]}" \
  --resource-group "${PIP_RG_NAME}" \
  --resource-type "Microsoft.Network/publicIPAddresses" \
  --query '[0].id' \
  --output tsv
