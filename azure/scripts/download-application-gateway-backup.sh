#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

: "$1"
readonly ST_RG_NAME=${1:?}
readonly SUBSCRIPTION_CODE=${2:-gcspre}
RESTORE_FILE_NAME=${3:-}

pushd "$(dirname "$0")" >/dev/null
trap "popd > /dev/null" EXIT

read -ra SUBSCRIPTION_OPTION <<< \
  "$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")"

ST_CONNSTR=$(./get-storage-account-connstr.sh \
  "${SUBSCRIPTION_CODE}" \
  "${ST_RG_NAME}"
)
readonly ST_CONTAINER_NAME="agw-backup"

if [[ -z ${RESTORE_FILE_NAME} ]]; then
  ST_PREFIX="ARMBK"
  RESTORE_FILE_NAME=$(az storage blob list \
    "${SUBSCRIPTION_OPTION[@]}" \
    --connection-string "${ST_CONNSTR}" \
    --container-name "${ST_CONTAINER_NAME}" \
    --prefix "${ST_PREFIX}" \
    --query 'reverse(sort_by(@,&name))[0].name' \
    --output tsv
  )
fi

LOCAL_FILE_PATH=$(mktemp -d)/${RESTORE_FILE_NAME}
az storage blob download \
  "${SUBSCRIPTION_OPTION[@]}" \
  --connection-string "${ST_CONNSTR}" \
  --container-name "${ST_CONTAINER_NAME}" \
  --name "${RESTORE_FILE_NAME}" \
  --file "${LOCAL_FILE_PATH}" \
  --no-progress \
  3>&2 2>&1 1>&3

echo "${LOCAL_FILE_PATH}"
