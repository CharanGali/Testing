#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

: "$1" "$2"

readonly SUBSCRIPTION_CODE=${1:?}
readonly ST_RG_NAME=${2:?}

pushd "$(dirname "$0")" >/dev/null
trap "popd > /dev/null" EXIT

read -ra SUBSCRIPTION_OPTION <<< \
  "$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")"

ST_RESOURCE_ID=$(./get-storage-account-id.sh \
  "${SUBSCRIPTION_CODE}" \
  "${ST_RG_NAME}"
)
az storage account show-connection-string \
  "${SUBSCRIPTION_OPTION[@]}" \
  --name "$(basename "${ST_RESOURCE_ID}")" \
  --query "connectionString" \
  --output tsv
