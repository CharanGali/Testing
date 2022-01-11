#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $2 $3 $4 $5

readonly ENV_NAME=$1
readonly SUBSCRIPTION_CODE=$2
readonly APP_CODE=$3
readonly OPSGENIE_KEY_NAME=$4
readonly OPSGENIE_KEY_VALUE=$5

pushd $(dirname $0)
trap "popd" EXIT

set +vx
# Key Vault名の取得
readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(bash ./../../scripts/get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME})
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")

bash ./../../scripts/set-key-vault-secret.sh "$OPSGENIE_KEY_NAME" "$OPSGENIE_KEY_VALUE" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"

set -vx
