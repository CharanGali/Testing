#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: "$1" "$2" "$3" "$4"

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4

pushd "$(dirname "$0")"
trap "popd" EXIT

# github actionsではkubectlをインストールする必要あり
if [ -n "${CI-}" ]; then
  az aks install-cli
fi

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

readonly CMN_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
CMN_KEY_VAULT_ID=$(./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${CMN_KV_RG_NAME})
CMN_KEY_VAULT_NAME=$(basename "${CMN_KEY_VAULT_ID}")

get_secret_from_cmn_key_vault() {
  ./get-key-vault-secret.sh "$1" "${SUBSCRIPTION_CODE}" "${CMN_KEY_VAULT_NAME}"
}

readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME})
KEY_VAULT_NAME=$(basename "${KEY_VAULT_ID}")

add_secret_to_key_vault() {
  ./set-key-vault-secret.sh "$1" "$2" "${SUBSCRIPTION_CODE}" "${KEY_VAULT_NAME}" > /dev/null
}

IS_MY_SQL_USER_DEFINED=$( \
  az keyvault secret list \
    ${SUBSCRIPTION_OPTION} \
    --vault-name ${KEY_VAULT_NAME} \
    --query "[?name=='laMysqlUsername'].name" \
    --output tsv \
)
if [ -n "${IS_MY_SQL_USER_DEFINED}" ]; then
  echo "Since the mysql db and user already exists, the processing of creating it is skipped."
  exit 0
fi

MYSQL_HOST="mysql-${SUBSCRIPTION_CODE}-cmn-flexible-japaneast.mysql.database.azure.com"
MYSQL_DATABASE_LA="${SUBSCRIPTION_CODE}_${ENV_NAME}_la_db"
MYSQL_DATABASE_DPS="${SUBSCRIPTION_CODE}_${ENV_NAME}_dps_db"
MYSQL_DATABASE_OCSP="${SUBSCRIPTION_CODE}_${ENV_NAME}_ocsp_db"
MYSQL_USER_LA="${SUBSCRIPTION_CODE}_${ENV_NAME}_la_username"
MYSQL_USER_DPS="${SUBSCRIPTION_CODE}_${ENV_NAME}_dps_username"
MYSQL_USER_OCSP="${SUBSCRIPTION_CODE}_${ENV_NAME}_ocsp_username"

set +vx
MYSQL_ROOT_USERNAME="$(get_secret_from_cmn_key_vault 'mysqlAdminUsername')"
MYSQL_ROOT_PASSWORD="$(get_secret_from_cmn_key_vault 'mysqlAdminPassword')"
PASSWORD_PREFIX="Pswd_${RANDOM}_"
RANDOM_STRING=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 15; echo)
MYSQL_PASSWORD_LA="${PASSWORD_PREFIX}${RANDOM_STRING}"
RANDOM_STRING=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 15; echo)
MYSQL_PASSWORD_DPS="${PASSWORD_PREFIX}${RANDOM_STRING}"
RANDOM_STRING=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 15; echo)
MYSQL_PASSWORD_OCSP="${PASSWORD_PREFIX}${RANDOM_STRING}"

if [[ $MYSQL_HOST =~ -flexible- ]]; then
  echo "mysql flexible server"
  USER_OPTION="--user=${MYSQL_ROOT_USERNAME}"
else
  echo "old mysql server"
  USER_OPTION="--user=${MYSQL_ROOT_USERNAME}@${MYSQL_HOST}"
fi

KUBCTL_OPT="
  -i \
  --rm \
  --image=mysql:8.0.21 \
  --restart=Never \
  mysql-client -- \
  mysql --host=${MYSQL_HOST} ${USER_OPTION} --password=${MYSQL_ROOT_PASSWORD}
"

readonly CLUSTER_NAME="aks-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${REGION_CODE}"
readonly AKS_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"

az aks get-credentials ${SUBSCRIPTION_OPTION} \
  --resource-group "${AKS_RG_NAME}" \
  --name "${CLUSTER_NAME}" \
  --overwrite-existing

kubectl run ${KUBCTL_OPT} <<-EOD
  CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_LA} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  CREATE USER IF NOT EXISTS '${MYSQL_USER_LA}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD_LA}';
  GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_LA}.* TO '${MYSQL_USER_LA}'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;

  CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_DPS} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  CREATE USER IF NOT EXISTS '${MYSQL_USER_DPS}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD_DPS}';
  GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_DPS}.* TO '${MYSQL_USER_DPS}'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;

  CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_OCSP} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  CREATE USER IF NOT EXISTS '${MYSQL_USER_OCSP}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD_OCSP}';
  GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_OCSP}.* TO '${MYSQL_USER_OCSP}'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
EOD

# --vvvをつけて登録した内容を確認
# shellcheck disable=SC2086
kubectl run ${KUBCTL_OPT} -vvv <<-EOD
  -- database
  SHOW DATABASES LIKE '${MYSQL_DATABASE_LA}';
  SHOW DATABASES LIKE '${MYSQL_DATABASE_DPS}';
  SHOW DATABASES LIKE '${MYSQL_DATABASE_OCSP}';
  -- user
  SELECT USER, HOST FROM mysql.user WHERE USER = '${MYSQL_USER_LA}';
  SELECT USER, HOST FROM mysql.user WHERE USER = '${MYSQL_USER_DPS}';
  SELECT USER, HOST FROM mysql.user WHERE USER = '${MYSQL_USER_OCSP}';
  -- user grants
  SHOW GRANTS for '${MYSQL_USER_LA}'@'%';
  SHOW GRANTS for '${MYSQL_USER_DPS}'@'%';
  SHOW GRANTS for '${MYSQL_USER_OCSP}'@'%';
EOD

# Key Vaultへの登録
add_secret_to_key_vault 'mysqlHost'     "${MYSQL_HOST}"
add_secret_to_key_vault 'laMysqlDatabase' "${MYSQL_DATABASE_LA}"
add_secret_to_key_vault 'laMysqlUsername' "${MYSQL_USER_LA}"
add_secret_to_key_vault 'laMysqlPassword' "${MYSQL_PASSWORD_LA}"
add_secret_to_key_vault 'dpsMysqlDatabase' "${MYSQL_DATABASE_DPS}"
add_secret_to_key_vault 'dpsMysqlUsername' "${MYSQL_USER_DPS}"
add_secret_to_key_vault 'dpsMysqlPassword' "${MYSQL_PASSWORD_DPS}"
add_secret_to_key_vault 'ocspMysqlDatabase' "${MYSQL_DATABASE_OCSP}"
add_secret_to_key_vault 'ocspMysqlUsername' "${MYSQL_USER_OCSP}"
add_secret_to_key_vault 'ocspMysqlPassword' "${MYSQL_PASSWORD_OCSP}"

unset MYSQL_ROOT_USERNAME MYSQL_ROOT_PASSWORD KUBCTL_OPT
unset MYSQL_HOST MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD PASSWORD_PREFIX RANDOM_STRING
set -vx
