#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit


: "$1" "$2" "$3"

readonly ENV_NAME=${1:?}
readonly SUBSCRIPTION_CODE=${2:?}
readonly APP_CODE=${3:?}

pushd "$(dirname "$0")"
trap "popd" EXIT

read -ra SUBSCRIPTION_OPTION <<< \
  "$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")"
BLOB_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-st-blob-agw-backup"
BLOB_ID=$(./get-storage-account-id.sh "${SUBSCRIPTION_CODE}" \
  "${BLOB_RG_NAME}")
BLOB_NAME=$(basename "${BLOB_ID}")

az storage container create \
  "${SUBSCRIPTION_OPTION[@]}" \
  --auth-mode login \
  --account-name "${BLOB_NAME}" \
  --name agw-backup
