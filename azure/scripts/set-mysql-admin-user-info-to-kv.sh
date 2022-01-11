#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1

readonly SUBSCRIPTION_CODE=$1

pushd $(dirname $0)
trap "popd" EXIT

# Key Vaultへの登録
SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh ${SUBSCRIPTION_CODE})
readonly SHARED_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-main-kv"
KEY_VAULT_ID=$(bash ./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${SHARED_KV_RG_NAME})
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")

MYSQL_ADMIN_USERNAME_KEY="mysqlAdminUsername"
MYSQL_ADMIN_PASSWORD_KEY="mysqlAdminPassword"

IS_SECRET_DEFINED=$(az keyvault secret list \
  ${SUBSCRIPTION_OPTION} \
  --vault-name ${KEY_VAULT_NAME} \
  --query "[?name=='"${MYSQL_ADMIN_PASSWORD_KEY}"'].name" \
  --output tsv \
)
if [ -n "${IS_SECRET_DEFINED}" ]; then
  echo "mysqlAdminPassword has already been registered in key vault. Skips the generation of that value."
  exit 0
fi

echo "Registration of ${MYSQL_ADMIN_PASSWORD_KEY} and mysqlAdminPassword start"
set +vx
MYSQL_ADMIN_USERNAME=adminUser
PASSWORD_PREFIX="Pswd_${RANDOM}_"
RANDOM_STRING=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 15; echo)
MYSQL_ADMIN_PASSWORD="${PASSWORD_PREFIX}${RANDOM_STRING}"
bash ./set-key-vault-secret.sh "$MYSQL_ADMIN_USERNAME_KEY" "$MYSQL_ADMIN_USERNAME" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"
bash ./set-key-vault-secret.sh "$MYSQL_ADMIN_PASSWORD_KEY" "$MYSQL_ADMIN_PASSWORD" "$SUBSCRIPTION_CODE" "$KEY_VAULT_NAME"

unset MYSQL_ADMIN_USERNAME MYSQL_ADMIN_PASSWORD PASSWORD_PREFIX RANDOM_STRING
set -vx
