#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: "$1" "$2" "$3"

readonly ENV_NAME=$1
readonly SUBSCRIPTION_CODE=$2
readonly APP_CODE=$3

pushd "$(dirname "$0")"
trap "popd" EXIT

SUBSCRIPTION_OPTION="$(../build-subscription-option.sh "${SUBSCRIPTION_CODE}")"
SUBSCRIPTION_ID=$(../get-subscription-id.sh ${SUBSCRIPTION_CODE})

readonly REPO="ss-base-ocsp"
readonly USAGE="gha-${REPO}"
# naming rule: sp-{Subscription}-{Environment}-{Application}-{Usage}
readonly SERVICE_PRINCIPAL_NANE="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${USAGE}"

EXISTING_APP=$(az ad app list --display-name "${SERVICE_PRINCIPAL_NANE}" --query "[?displayName=='${SERVICE_PRINCIPAL_NANE}'].appId" --output tsv)

if [ -n "${EXISTING_APP}" ]; then
  echo "Since the application object already exists, the processing of creating it is skipped."
  exit 0
fi

set +vx
SP_JSON=$(az ad sp create-for-rbac \
  --name "${SERVICE_PRINCIPAL_NANE}" \
  --skip-assignment true \
  --years 2 \
  --scopes /subsctiptions/${SUBSCRIPTION_ID} \
  --sdk-auth)
APP_ID="$(echo "${SP_JSON}" | jq -r .clientId)"
DISPLAY_NAME="${SERVICE_PRINCIPAL_NANE}"
PASSWORD="$(echo "${SP_JSON}" | jq -r .clientSecret)"
TENANT="$(echo "${SP_JSON}" | jq -r .tenantId)"

readonly SHARED_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./../get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${SHARED_KV_RG_NAME})
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")

add_secret_to_key_vault() {
  ../../scripts/tools/set-key-vault-secret.sh "$1" "$2" "${SUBSCRIPTION_CODE}" "${KEY_VAULT_NAME}" > /dev/null
}

add_secret_to_key_vault "sp-${USAGE}-appId"       "${APP_ID}"
add_secret_to_key_vault "sp-${USAGE}-displayName" "${DISPLAY_NAME}"
add_secret_to_key_vault "sp-${USAGE}-password"    "${PASSWORD}"
add_secret_to_key_vault "sp-${USAGE}-tenant"      "${TENANT}"
add_secret_to_key_vault "sp-${USAGE}-sdk-auth"    "${SP_JSON}"

unset SP_JSON APP_ID DISPLAY_NAME PASSWORD TENANT
set -vx
