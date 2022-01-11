#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $2 $3

readonly ENV_NAME=$1
readonly SUBSCRIPTION_CODE=$2
readonly APP_CODE=$3

pushd $(dirname $0)
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

# Key Vault名の取得
readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME})
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")

set +vx
readonly USAGES=( "la" "dps" "ocsp" )
for USAGE in "${USAGES[@]}"
do
  # naming rule: sp-{Subscription}-{Environment}-{Application}-{Usage}
  SERVICE_PRINCIPAL_NAME="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${USAGE}"

  # 既存のApp（サービスプリンシパルの）の存在チェック
  EXISTING_APP=$(az ad app list --display-name ${SERVICE_PRINCIPAL_NAME} --query "[?displayName=='${SERVICE_PRINCIPAL_NAME}'].appId" --output tsv)
  if [ -n "${EXISTING_APP}" ]; then
    echo "Since ${SERVICE_PRINCIPAL_NAME} already exists, the processing of creating it is skipped."
  else
    SP_JSON=$(az ad sp create-for-rbac \
      --name "${SERVICE_PRINCIPAL_NAME}" \
      --skip-assignment true \
      --years 2)
    APP_ID="$(echo ${SP_JSON} | jq -r .appId)"
    DISPLAY_NAME="$(echo ${SP_JSON} | jq -r .displayName)"
    PASSWORD="$(echo ${SP_JSON} | jq -r .password)"
    TENANT="$(echo ${SP_JSON} | jq -r .tenant)"
    # KeyVaultへの登録
    ./set-key-vault-secret.sh "sp-${USAGE}-appId" "$APP_ID" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
    ./set-key-vault-secret.sh "sp-${USAGE}-displayName" "$DISPLAY_NAME" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
    ./set-key-vault-secret.sh "sp-${USAGE}-password" "$PASSWORD" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
    ./set-key-vault-secret.sh "sp-${USAGE}-tenant" "$TENANT" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
    unset SP_JSON APP_ID DISPLAY_NAME PASSWORD TENANT
  fi
done
set -vx

for USAGE in "${USAGES[@]}"
do
  # 各アプリのサービスプリンシパルにKey vault Secret UserのRoleをアサインする
  KV_RESOURCE_GROUP_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
  KV_SECRET_USER_ROLE_NAME="role-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-sharedKvSecretUser"
  KV_SECRET_USER_ROLE_ID=$(az role definition list --name ${KV_SECRET_USER_ROLE_NAME} | jq -r .[0].id)
  APP_ID=$(./../tools/get-key-vault-secret.sh "sp-${USAGE}-appId" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME")

  SERVICE_PRINCIPAL_OBJECT_ID=$(az ad sp show --id ${APP_ID} | jq -r .objectId)

  # TOIMPROVE: アサインをARM Template化 & アプリ毎に権限調整
  az role assignment create \
    ${SUBSCRIPTION_OPTION} \
    --assignee ${SERVICE_PRINCIPAL_OBJECT_ID} \
    --role ${KV_SECRET_USER_ROLE_ID} \
    --scope ${KEY_VAULT_ID}
done
