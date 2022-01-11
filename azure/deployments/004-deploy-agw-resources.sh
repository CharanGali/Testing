#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

readonly SUBSCRIPTION_CODE=${1:-gcspre}
readonly REGION_CODE=${2:-japaneast}
readonly ENV_NAME=${3:-cmn}
readonly APP_CODE=${4:-lacmn}
readonly ST_RG_NAME=${5:-}
readonly RESTORE_FILE_NAME=${6:-}
readonly FORCE_UPDATE_FLAG=${7:-false}

pushd "$(dirname "$0")"

readonly SHARED_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
bash ./../scripts/add-myself-to-key-vault-access-policy.sh "${SUBSCRIPTION_CODE}" "${SHARED_KV_RG_NAME}"

# 作業完了後にポリシーを削除するための関数
function deletePolicy () {
  bash ./../scripts/remove-myself-to-key-vault-access-policy.sh "${SUBSCRIPTION_CODE}" "${SHARED_KV_RG_NAME}"
}

trap "deletePolicy; popd" EXIT

readonly COMMON_DEPLOYMENT_OPTIONS=(
  "${ENV_NAME}"
  "${REGION_CODE}"
  "${SUBSCRIPTION_CODE}"
  "${APP_CODE}"
)

echo '----------- create network public ip addresses -----------'
bash ./../scripts/create-network-public-ip-address.sh "${COMMON_DEPLOYMENT_OPTIONS[@]}"

echo '----------- create AGW WAF policies -----------'
bash ./../scripts/create-agw-waf-policies.sh "${COMMON_DEPLOYMENT_OPTIONS[@]}"

echo '----------- create AGW backup storage account -----------'
bash ./../scripts/create-storage-storage-accounts-for-agw-backup.sh \
  "${COMMON_DEPLOYMENT_OPTIONS[@]}"

echo '----------- create container of storage account -----------'
bash ./../scripts/create-storage-container-for-agw-backup.sh \
  "${ENV_NAME}" "${SUBSCRIPTION_CODE}" "${APP_CODE}"

if [[ -n ${ST_RG_NAME} ]]; then
  echo '----------- restore application gateway -----------'
  LOCAL_RESTORE_FILE=$(./../scripts/download-application-gateway-backup.sh \
    "${ST_RG_NAME}" "${SUBSCRIPTION_CODE}" "${RESTORE_FILE_NAME}")

  bash ./../scripts/restore-application-gateway.sh \
    "${LOCAL_RESTORE_FILE}" \
    "${COMMON_DEPLOYMENT_OPTIONS[@]}" \
    "${FORCE_UPDATE_FLAG}"
else
  echo '----------- create application gateway -----------'
  bash ./../scripts/create-application-gateway.sh \
    "${COMMON_DEPLOYMENT_OPTIONS[@]}" \
    "${FORCE_UPDATE_FLAG}"
fi
