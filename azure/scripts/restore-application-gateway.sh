#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

: "$1"

readonly RAW_EXPORT_FILE=${1:-?}
readonly ENV_NAME=${2:-cmn}
readonly REGION_CODE=${3:-japaneast}
readonly SUBSCRIPTION_CODE=${4:-gcspre}
readonly APP_CODE=${5:-lacmn}
readonly FORCE_UPDATE_FLAG=${6:-false}

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly SERVICE_CODE="agw"
read -ra SUBSCRIPTION_OPTION <<< \
  "$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")"

RG_NAME_TO_BE="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${SERVICE_CODE}"
RG_EXISTS=$(az group exists "${SUBSCRIPTION_OPTION[@]}" -n "${RG_NAME_TO_BE}")
if [ "${RG_EXISTS}" = true ]; then
  echo '----------- Skip processing because ResourceGroup already exists -----------'
  if [ "${FORCE_UPDATE_FLAG}" = true ]; then
    echo '----------- But the forced update flag is true, so processing continues -----------'
  else
    exit 0
  fi
fi

readonly CMN_ENV_NAME=cmn
readonly CMN_APP_CODE=main
readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./get-key-vault-id.sh "${SUBSCRIPTION_CODE}" "${KV_RG_NAME}")

# Create Resource Group and get its name
RG_NAME=$(./create-resource-group.sh \
  "${ENV_NAME}" \
  "${REGION_CODE}" \
  "${SUBSCRIPTION_CODE}" \
  "${APP_CODE}" \
  "${SERVICE_CODE}" | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")

PARAM_JSON_TMP_FILE=$(mktemp)
PARAM_JSON_TMPL=../parameters/application-gateway-restore.jsonc
sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
       "${PARAM_JSON_TMPL}" > "${PARAM_JSON_TMP_FILE}"

TEMPLATE_JSON_TMP_FILE=$(mktemp)
jq --arg subscCode "${SUBSCRIPTION_CODE}" \
  -f ./patch-agw-backup-json.jq \
  "${RAW_EXPORT_FILE}" > "${TEMPLATE_JSON_TMP_FILE}"

get_embedded_default_param() {
  local _KEY_WORD="$1"
  local _RAW_EXPORT_FILE="$2"
  jq --arg keyWord "${_KEY_WORD}" \
    -r '.parameters|to_entries[]|select(.key|contains($keyWord)).key' \
    "${_RAW_EXPORT_FILE}"
}

PIP_PARAM_NAME=$(get_embedded_default_param "pip" "${RAW_EXPORT_FILE}")
PIP_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-pip"
NEW_PIP_ID="$(./get-pip-id.sh "${SUBSCRIPTION_CODE}" "${PIP_RG_NAME}")"

## 2. ApplicationGateway名
AGW_NAME_PARAM_NAME=$(get_embedded_default_param "name" "${RAW_EXPORT_FILE}")
NEW_AGW_NAME="agw-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${REGION_CODE}"

## 3. 共通WAFポリシー
CMN_WAF_PARAM_NAME=$(get_embedded_default_param "cmnwaf" "${RAW_EXPORT_FILE}")
WAF_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-wgf"
NEW_CMN_WAF_ID="$(./get-waf-policy-id.sh \
  "${SUBSCRIPTION_CODE}" "${WAF_RG_NAME}" "waf")"

# リストア構築
az deployment group create \
  "${SUBSCRIPTION_OPTION[@]}" \
  --name "application-gateway-restore" \
  --resource-group "${RG_NAME}" \
  --template-file "${TEMPLATE_JSON_TMP_FILE}" \
  --parameters "${PARAM_JSON_TMP_FILE}" \
  --parameters \
    "${PIP_PARAM_NAME}"="${NEW_PIP_ID}" \
    "${AGW_NAME_PARAM_NAME}"="${NEW_AGW_NAME}" \
    "${CMN_WAF_PARAM_NAME}"="${NEW_CMN_WAF_ID}"
