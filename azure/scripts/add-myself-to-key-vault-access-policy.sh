#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $2

readonly SUBSCRIPTION_CODE=$1
readonly KV_RG_NAME=$2

pushd $(dirname $0)
# Key Vault名の取得
KEY_VAULT_ID=$(bash ./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME})
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

# 実行環境のGlobal IPアドレスを取得してSENのIP以外の場合はFirewallに穴あけをする
MY_IP=$(curl -s https://checkip.amazonaws.com/)
SEN_IP_DEFINITION_FILE="./../parameters/sen-ip.json"
SEN_IP_LIST=$(cat ${SEN_IP_DEFINITION_FILE} | jq -r '.parameters.ipRules[] | map(.value) | join(" ")')
WORKING_FROM_SEN=$(python ./is_the_ip_included_in_the_ip_list.py ${MY_IP} ${SEN_IP_LIST})
if [ ${WORKING_FROM_SEN} = "false" ]; then
  # Firewall設定 を Key Vaultに行う
  az keyvault network-rule add \
    ${SUBSCRIPTION_OPTION} \
    --resource-group ${KV_RG_NAME} \
    --name ${KEY_VAULT_NAME} \
    --ip-address "${MY_IP}/32"
fi

if [ -n "${CI:-}" ]; then
  USAGE="gha"
  REPO=$(basename "$(git config --get remote.origin.url)" | cut -d. -f1)
  if [[ $REPO != ss-gcs-infra-template ]]; then
    USAGE="gha-${REPO}"
  fi
  SERVICE_PRINCIPAL_NANE="sp-${SUBSCRIPTION_CODE}-cmn-main-${USAGE}"
  OBJECT_ID=$(az ad sp list --display-name "${SERVICE_PRINCIPAL_NANE}" -o tsv --query "[?displayName=='${SERVICE_PRINCIPAL_NANE}'].objectId")
else
  OBJECT_ID=$(az ad signed-in-user show --query objectId --output tsv)
fi

az keyvault set-policy \
  ${SUBSCRIPTION_OPTION} \
  --name ${KEY_VAULT_NAME} \
  --object-id ${OBJECT_ID} \
  --secret-permissions get list set \
  --key-permissions get list create
