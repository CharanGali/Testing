#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# 概要
# ==========
# lacmnのAKS用のService Principalを構築します。
# また、その情報をKey vaultに登録します。
#
# 引数
# ==========
#
# 1. 環境名
#    e.g.) cmn
#
# 3. SUBSCRIPTION_CODE
#    e.g.) gcspre, gcsrls
#
# 4. APP_CODE
#    e.g.) main, yt
#
################################################################################
: $1 $2 $3

readonly ENV_NAME=$1
readonly SUBSCRIPTION_CODE=$2
readonly APP_CODE=$3

pushd $(dirname $0)
trap "popd" EXIT

readonly USAGE="aks"
readonly SERVICE_PRINCIPAL_NANE="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${USAGE}"

# 既存のApp（サービスプリンシパルの）の存在チェック
EXISTING_APP=$(az ad app list --display-name "${SERVICE_PRINCIPAL_NANE}" --query "[?displayName=='${SERVICE_PRINCIPAL_NANE}'].appId" --output tsv)

if [ -n "${EXISTING_APP}" ]; then
  # 既にアプリケーションオブジェクトとサービスプリンシパルが作成済みなので、以下の処理をスキップする
  echo "Since the application object already exists, the processing of creating it is skipped."
  exit 0
fi

set +vx
# サービスプリンシパルの作成（RoleはAKS構築後にアサインするのでここではskip-assignmentオプションを使用）
SP_JSON=$(az ad sp create-for-rbac \
  --name "${SERVICE_PRINCIPAL_NANE}" \
  --skip-assignment true \
  --years 2 \
)

APP_ID="$(echo ${SP_JSON} | jq -r .appId)"
DISPLAY_NAME="$(echo ${SP_JSON} | jq -r .displayName)"
PASSWORD="$(echo ${SP_JSON} | jq -r .password)"
TENANT="$(echo ${SP_JSON} | jq -r .tenant)"

# Key Vaultへの登録
readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./../tools/get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME})
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")

./../tools/set-key-vault-secret.sh "sp-${USAGE}-appId" "$APP_ID" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
./../tools/set-key-vault-secret.sh "sp-${USAGE}-displayName" "$DISPLAY_NAME" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
./../tools/set-key-vault-secret.sh "sp-${USAGE}-password" "$PASSWORD" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
./../tools/set-key-vault-secret.sh "sp-${USAGE}-tenant" "$TENANT" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
unset SP_JSON APP_ID DISPLAY_NAME PASSWORD TENANT
set -vx
