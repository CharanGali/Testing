#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

readonly ENV_NAME=${1:-cmn}
readonly SUBSCRIPTION_CODE=${2:-gcspre}
readonly APP_CODE=${3:-lacmn}

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly AGW_SERVICE_CODE="agw"
read -ra SUBSCRIPTION_OPTION <<< \
  "$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")"

AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${AGW_SERVICE_CODE}"
RG_EXISTS=$(az group exists "${SUBSCRIPTION_OPTION[@]}" -n "${AGW_RG_NAME}")
if [ "${RG_EXISTS}" != true ]; then
  echo '----------- ResourceGroup does not exist -----------'
  exit 1
fi

BACKUP_TMP_FILE=$(mktemp)
az group export \
  --name "${AGW_RG_NAME}" \
  --include-parameter-default-value \
  > "${BACKUP_TMP_FILE}"

readonly ST_SERVICE_CODE="st-blob"
readonly ST_USAGE="agw-backup"
readonly ST_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${ST_SERVICE_CODE}-${ST_USAGE}"
ST_CONNSTR=$(./get-storage-account-connstr.sh \
  "${SUBSCRIPTION_CODE}" \
  "${ST_RG_NAME}"
)
readonly ST_CONTAINER_NAME="${ST_USAGE}"

UPLOAD_FILE_NAME="ARMBK$(date +%Y%m%d%H%M%S)-${AGW_RG_NAME}.json"

az storage blob upload \
  "${SUBSCRIPTION_OPTION[@]}" \
  --connection-string "${ST_CONNSTR}" \
  --container-name "${ST_CONTAINER_NAME}" \
  --file "${BACKUP_TMP_FILE}" \
  --name "${UPLOAD_FILE_NAME}" \
  --no-progress
