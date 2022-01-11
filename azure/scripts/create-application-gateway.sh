#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

readonly ENV_NAME=${1:-cmn}
readonly REGION_CODE=${2:-japaneast}
readonly SUBSCRIPTION_CODE=${3:-gcspre}
readonly APP_CODE=${4:-lacmn}
readonly FORCE_UPDATE_FLAG=${5:-false}

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly SERVICE_CODE="agw"
DEPLOYMENT_VERSION=$(git describe --always)
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

readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./get-key-vault-id.sh "${SUBSCRIPTION_CODE}" "${KV_RG_NAME}")

PARAM_JSON_TMP_FILE=$(mktemp)
sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
       ../parameters/application-gateway.jsonc > "${PARAM_JSON_TMP_FILE}"

# Create Resource Group and get its name
RG_NAME=$(./create-resource-group.sh "${ENV_NAME}" "${REGION_CODE}" "${SUBSCRIPTION_CODE}" "${APP_CODE}" "${SERVICE_CODE}" | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")

# shellcheck disable=SC2086
az deployment group create \
  "${SUBSCRIPTION_OPTION[@]}" \
  --name "application-gateway" \
  --resource-group "${RG_NAME}" \
  --template-file ../templates/application-gateway.json \
  --parameters "${PARAM_JSON_TMP_FILE}" \
  --parameters \
    env="${ENV_NAME}" \
    regionCode="${REGION_CODE}" \
    appCode="${APP_CODE}" \
    subscriptionCode="${SUBSCRIPTION_CODE}" \
    deploymentVersion="${DEPLOYMENT_VERSION}"
