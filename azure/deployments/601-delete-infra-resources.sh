#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: "$1"

readonly ENV_NAME=$1
readonly REGION_CODE=${2:-japaneast}
readonly SUBSCRIPTION_CODE=${3:-gcspre}
readonly APP_CODE=${4:-lacmn}
readonly DNS_ZONE=${5:-"aitrios.sony-semicon.co.jp"}

pushd "$(dirname "$0")"
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(./../scripts/build-subscription-option.sh "${SUBSCRIPTION_CODE}")
SUBSCRIPTION_ID=$(./../scripts/get-subscription-id.sh "${SUBSCRIPTION_CODE}")

readonly AKS_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"
rgExists=$(az group exists ${SUBSCRIPTION_OPTION} -n "${AKS_RG_NAME}")
if [[ "$rgExists" == true ]]; then
  echo '----------- drop sql database and users -----------'
  ./../scripts/drop-db-and-users.sh "${ENV_NAME}" "${REGION_CODE}" "${SUBSCRIPTION_CODE}" "${APP_CODE}"
fi

readonly TARGET_RG_PFX="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}"
readonly TARGET_SP_AKS="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"
readonly TARGET_AKS_ROLE="role-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks-sp"
readonly TARGET_SP_LA="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-la"
readonly TARGET_SP_DPS="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-dps"
readonly TARGET_SP_OCSP="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-ocsp"
readonly AGW_NAME="agw-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-${REGION_CODE}"
readonly AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-agw"
readonly WAF_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-wgf"

rgExists=$(az group exists ${SUBSCRIPTION_OPTION} -n "${WAF_RG_NAME}")
if [[ "$rgExists" == true ]]; then
  for MODULE_NAME in {la,dps}; do
    ../scripts/associate-waf-policies-with-agw.sh \
      "${SUBSCRIPTION_CODE}" \
      "/${MODULE_NAME}/*" \
      "http-setting-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}" \
      "backend-pool-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}" \
      "path-based-rule-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}" \
      "laapi-${ENV_NAME}-rule" \
      "${AGW_NAME}" \
      "${AGW_RG_NAME}" \
      "" \
      ""
  done
fi

readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./../scripts/get-key-vault-id.sh "${SUBSCRIPTION_CODE}" "${KV_RG_NAME}" || true)

mapfile -t RESOURCE_GROUPS < <( \
  az group list ${SUBSCRIPTION_OPTION} --query "[?contains(name, '${TARGET_RG_PFX}')].name" -o tsv
)
for RESOURCE_GROUP in "${RESOURCE_GROUPS[@]}"
do
  ./../scripts/delete-resource-group.sh "${SUBSCRIPTION_CODE}" "${RESOURCE_GROUP}" || true
done

if [[ -n $KEY_VAULT_ID ]]; then
  az keyvault purge ${SUBSCRIPTION_OPTION} --name "${KEY_VAULT_ID##*/}" || true
fi

DEPLOYMENT_NAME="${SUBSCRIPTION_CODE}-${APP_CODE}-${ENV_NAME}-aks-sp-custom-role"
CUSTOM_ROLE_DEPLOYMENT_OUTPUT=$(\
  az deployment sub show \
    ${SUBSCRIPTION_OPTION} \
    --name "${DEPLOYMENT_NAME}" \
    --query properties.outputs \
)
CUSTOM_ROLE_ID=$(echo "${CUSTOM_ROLE_DEPLOYMENT_OUTPUT}" | jq -r .customRoleId.value)

SCOPE_RESOURCE_GROUPS_OF_ROLE=(
  # AKS (Container Service Managed Cluster)
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"
  # Virtual Network
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-vnet"
  # Container Registry
  "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-cr"
)

for RG in "${SCOPE_RESOURCE_GROUPS_OF_ROLE[@]}"
do
  az role assignment delete \
    ${SUBSCRIPTION_OPTION} \
    --role "${CUSTOM_ROLE_ID}" \
    --scope "${RG}" || true
done

az role definition delete --name "${TARGET_AKS_ROLE}"

mapfile -t APP_ID_ARRAY < <( \
  az ad app list \
    --filter "\
      displayName eq '${TARGET_SP_AKS}' or \
      displayName eq '${TARGET_SP_LA}' or \
      displayName eq '${TARGET_SP_DPS}' or \
      displayName eq '${TARGET_SP_OCSP}' \
    " | jq -r '.[].appId' \
)
for APP_ID in "${APP_ID_ARRAY[@]}"
do
  az ad sp delete --id "${APP_ID}" || true
done

for MODULE_NAME in {la,dps,ocsp}; do
  ../scripts/delete-agw-path-based-rule.sh \
    "${SUBSCRIPTION_CODE}" \
    "path-based-rule-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}" \
    "laapi-${ENV_NAME}-rule" \
    "${AGW_NAME}" \
    "${AGW_RG_NAME}"
done

../scripts/delete-agw-rules.sh \
  "${SUBSCRIPTION_CODE}" \
  "laapi-${ENV_NAME}-rule" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}"

../scripts/delete-agw-listeners.sh \
  "${SUBSCRIPTION_CODE}" \
  "laapi-${ENV_NAME}-listener" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}"

for MODULE_NAME in {la,dps,ocsp}; do
  ../scripts/delete-agw-http-settings.sh \
    "${SUBSCRIPTION_CODE}" \
    "http-setting-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}" \
    "${AGW_NAME}" \
    "${AGW_RG_NAME}"
done

for MODULE_NAME in {la,dps,ocsp}; do
  ../scripts/delete-agw-backend-pool.sh \
    "${SUBSCRIPTION_CODE}" \
    "backend-pool-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}" \
    "${AGW_NAME}" \
    "${AGW_RG_NAME}"
done